"""
Finds likely matches between red books and class reports
"""
from datetime import datetime
import re
import pandas as pd
import numpy as np
import recordlinkage
import joblib
from jellyfish import jaro_winkler
import os
from recordlinkage.index import SortedNeighbourhood
from recordlinkage.base import BaseCompareFeature
import shutil
from sklearn.cluster import KMeans
from sklearn.ensemble import RandomForestClassifier
from sklearn.base import is_classifier

DEFAULT_SEED = 0

class JaroWinklerWithMissings(BaseCompareFeature):
    """
        Compare two strings based on the jaro-winkler method and return a
        missing score if either of the two strings is empty
    """
    @staticmethod
    def _jaro_winkler_or_missing(s1, s2):
        if all((isinstance(x,str)) & (len(x) > 0) for x in [s1,s2]):
            score = jaro_winkler(s1,s2)
        else:
            score  = np.nan
        return score
    
    def _compute_vectorized(self,left_on,right_on):
        score = np.array([self._jaro_winkler_or_missing(x,y) for x,y in zip(left_on,right_on)])
        return score

class JaroWinklerFirstOnly(BaseCompareFeature):
    """
        Compare two strings of first and middle names based on the 
        closest jaro-winkler distance of any of the partial names in the
        second string to the first name in the first string. 
    """
    @staticmethod
    def _jaro_winkler_first_only(s1, s2):
        if any((isinstance(x,str)) & (len(x) <= 1) for x in [s1,s2]):
            score = 0
        else:
            s2_first = s2.split(" ")[0]
            s1 = re.sub(r'\.','',s1)
            s1_parts = s1.split(" ")
            scores = {
                part: jaro_winkler(s2_first,part)
                for part in s1_parts
            }
            score = max(scores.values())
        return score
    
    def _compute_vectorized(self,left_on,right_on):
        score = np.array([self._jaro_winkler_first_only(x,y) for x,y in zip(left_on,right_on)])
        return score
    
    
    
class MatchFinder(object):
    """Includes methods for comparing entries in class reports & red books
    and determining which entries likely refer to the same people.
    """

    def __init__(self, class_report_file, red_books_file, training_data_file,new_classifier=True,classifier_path=None):
        """

        :param class_report_file: filename of CSV containing class report, e.g. from update_and_merge.py
        :param red_books_file: filename of master redbook document (from create_master.py)
        :training_data_file: filename of training data file
        :param new_classifier: bool indicating whether a new classifier should be trained or old reloaded
        """
        # Set seed
        np.random.seed(DEFAULT_SEED)
        # Load class report (cr), red book (rb) data and training data (training)
        self.cr = pd.read_csv(class_report_file, index_col='PID')
        self.cr = self.cr[~self.cr.index.duplicated(keep='first')]
        self.cr = self.cr[pd.notna(self.cr.index)]
        self.rb = pd.read_csv(red_books_file, index_col='index')
        self.training = pd.read_csv(training_data_file, index_col=(0,1))
        # Compile factors
        self.factors_cr = self.get_factors_cr()
        self.factors_rb = self.get_factors_rb()
        self.candidate_pairs = None
        self.features = None
        # Train new or load old classifier
        if classifier_path is not None:
            self.classifier_path = classifier_path
        elif os.path.basename(os.getcwd()) == 'clean':
            self.classifier_path = os.path.join(
                '.','red_book_class_report_linking', 'classifier_new.joblib')
        elif os.path.basename(os.getcwd()) == 'red_book_class_report_linking':
            self.classifier_path = os.path.join('.','classifier_new.joblib')
        else:
            print(f"Current working directory is {os.getcwd()}. Storing classifier here")
            self.classifier_path = os.path.join('.','classifier_new.joblib')

        if (new_classifier==False) & (os.path.isfile(self.classifier_path)==False):
            print(f"{self.classifier_path} could not be found. Training new classifier instead.")
            new_classifier=True

        self.new_classifier = new_classifier
        self.clf = self.load_classifier()

        # Reset candidate pairs and features
        self.candidate_pairs = None
        self.features = None

    @staticmethod
    def extract_names(name):
        # Remove parantheses but keep contents at beginning of string
        name =re.sub(r'^\(([\w\-])\)',r'\g<1>',name)
        # Remove notes in parantheses from the end of string
        name = re.sub(r'(\(.+\))$','',name).strip()
        # Remove characters that are not alphanumerics, white space, comma, dot
        name = re.sub(r'[^\w\s\.,]','',name)
        # Mistaken , instead of . after abbreviated middle name
        name = re.sub(r'(\s\w),\s',r'\g<1>. ',name)
        # Remove space between abbreviated middle name and .
        name = re.sub(r'(\s[A-Z])\s\.',r'\g<1>. ',name,flags=re.I) 
        # Space after abbreviated middle name
        while re.search(r'([A-Z]\.)(\S)',name):
            name = re.sub(r'([A-Z]\.)(\S)',r'\g<1> \g<2>',name)
        # Space after comma
        name = re.sub(r',(\S)',', \g<1>',name)
        # Remove E.S. from end of string
        name = re.sub(r',\s?E\.\s?S\.\s?\W*$','',name,flags=re.I)
        # Remove Suffixes
        name = re.sub((r',\s?(JR\s?\.?|\d\S{0,3}|[A-Z]{1,3}|[1-9][A-Z]{2})\W?\s*\W?$'), '', 
                      name.strip(), flags=re.I).strip()
        # Remove trailing comma at end of string
        name = re.sub(r',\s?$','',name)
        # Remove multiple spaces
        name = re.sub(r'\s+',' ',name)
        # SAINT -> ST.
        name = re.sub(r'SAINT\s?',r'ST. ',name,flags=re.I)
        # Separate names if there are multiple uppercase characters within a word
        name = re.sub(r'([A-Z][a-z]{1,})([A-Z]\w+)(\s|$)',r'\g<1> \g<2>\g<3>',
                      name)
        ### Check for name pattern
        # Convert pattern LAST, FIRST(, SUFFIX) -> FIRST LAST(, SUFFIX)
        name = name.strip()
        search = re.search(r'^([^,]+), ?(\w.*?)$', name)
        if search is not None:
            parts = name.split(", ")
            name = ', '.join(parts[1:]) + ' ' + parts[0]
            
        # Join Composite last names together (i.e. no space-separation)
        name = re.sub(r'(\s|^)(D[AEIOUL]|LA|V[AO]N|MA?C) (\w+)$', '\g<1>\g<2>\g<3>',
                      name,flags=re.I)

        # Extract first, last and full name from the name string
        name = str.upper(name)
        first, last = ('','')
        full = name
        search = re.search(r'^(.*?)\s([\w\.]+)\s*$', name)
        if search is not None:
            first = search.group(1).strip() 
            last = search.group(2).strip()
            # initials = "".join(sorted([x[0] for x in first.split(" ")])+ [last[0]])

        return first, last, full
    
    
    @staticmethod
    def clean_school(highschool):
        if not isinstance(highschool,str):
            highschool = ""
        # Remove geographical reference at end of string
        highschool = re.sub(r'(\w{3,})\.',r'\g<1>,',highschool,flags=re.I)
        parts = highschool.split(', ')
        highschool = parts[0]
        for p in parts[1:]:
            if re.search(r'(school|academy|institute| and )',p,re.I):
                highschool = ", ".join([highschool,p])
        # Remove parantheses (+contained content)
        highschool = re.sub(r'(\(.+\))','',highschool)
        # Remove high school from end of string
        highschool = re.sub(r'(H\.?\s?S\.?|(High )?School( for boys)?|High)\W*$','',highschool,flags=re.I)
        # Remove 'The' from the start
        highschool = re.sub(r'^\s*The','',highschool,flags=re.I)
        # Remove apostrophs
        highschool = re.sub(r'(St\. \w+)\Ws ',r'\g<1> ',highschool,flags=re.I)
        # Remove non-alphanumerics
        highschool = re.sub(r'[^\w\s\-]','',highschool)

        highschool = highschool.strip()
        # Map a few school names
        school_map = {
            'Boston Latin': 'Public Latin',
            'Phillips Academy': r'^Andover$',
            'Phillips Exeter Academy': r'^(Phillips )?Exeter$',
            'English': r'^Boston English$',
            'Boys': r'^Atlanta Boys$'
            }
        for school in school_map:
            if re.search(school_map[school],highschool,re.I):
                highschool = school
        
        return highschool
    
    
    def get_factors_cr(self):
        """Assembles variables from class report that will be used for matching
        """
        print("Assembling class report factors now...")
        names = self.cr['name'].apply(lambda x: x.upper() if isinstance(x, str) else '')
        factors_cr = pd.DataFrame(index=self.cr.index)
        factors_cr['first'],factors_cr['last'],factors_cr['full'] = \
            tuple(zip(*names.apply(self.extract_names)))
        factors_cr['year'] = self.cr['year']
        factors_cr['high_school'] = self.cr['high_school_name'].apply(self.clean_school)
        return factors_cr

    def get_factors_rb(self):
        """Assembles variables from red book that will be used for matching
        """
        print("Assembling redbooks factors now...")
        names = self.rb['name'].apply(lambda x: x.upper() if isinstance(x, str) else '')
        factors_rb = pd.DataFrame(index=self.rb.index)
        factors_rb['first'], factors_rb['last'], factors_rb['full'] = \
            tuple(zip(*names.apply(self.extract_names)))
        factors_rb['year'] = self.rb['year']
        factors_rb['high_school'] = self.rb['high_school'].apply(self.clean_school)

        return factors_rb

    def set_candidate_pairs(self):
        """Determine which records are possible matches
        The indices of the possible matches are saved in a Pandas MultiIndex as self.candidate_pairs
        """
        print("Identifying potential matches...")
        # Find similar names
        name_indexer = recordlinkage.Index()
        name_indexer.add(SortedNeighbourhood(left_on='first', window=7))
        name_indexer.add(SortedNeighbourhood(left_on='last', window=5))
        name_pairs = name_indexer.index(self.factors_cr, self.factors_rb)
        # Find similar years +- 2
        year_indexer = SortedNeighbourhood(left_on='year', window=5)
        year_pairs = year_indexer.index(self.factors_cr, self.factors_rb)
        # Take intersection (names *and* years must be similar)
        candidate_pairs = name_pairs.intersection(year_pairs)
        print('Number of candidate pairs is {}'.format(len(candidate_pairs)))
        self.candidate_pairs = candidate_pairs

    def get_age_score(self, pid, idx, failure_value=2):
        """Estimates the age difference between individuals in two records.

        :param pid: index of the entry from class report
        :param idx: index of the entry from red book
        :param failure_value: value to return if something goes wrong
        :return: estimated distance between ages
        """
        birth_date = self.cr.loc[pid]['birthDate']
        try:
            birth_year = int(re.search(r'\d{4}$', birth_date).group())
        except (TypeError, AttributeError):
            return failure_value
        try:
            rb_year = int(self.rb.loc[idx]['year'])
            rb_age = int(self.rb.loc[idx]['age'])
        except (TypeError, ValueError):
            return failure_value
        est_birth_year = rb_year - rb_age - 3  # 3 since books published at end of freshman year
        return abs(birth_year - est_birth_year)

    def get_age_scores(self, multi_index=None, normalize=False):
        """Gets scores for the similarity of ages of candidate pairs

        :param multi_index: corresponds to pairs of indices in cr and rb data. Default is self.candidate_pairs
        :param normalize: If True, will transform all scores to be between 0 and 1
        :return: a Pandas Series of scores, one for each pair in the given multi_index
        """
        if multi_index is None:
            if self.candidate_pairs is not None:
                multi_index = self.candidate_pairs
            else:
                raise ValueError('No MultiIndex provided')
        scores = pd.Series([self.get_age_score(pid, idx) for pid, idx in multi_index],
                           index=multi_index)
        if normalize:
            scores = 1 - np.exp(-scores/4)
        return scores

    def assemble_features(self,radius=0.4):
        """Create a Pandas DataFrame of features, for machine learning to identify
        which candidate pairs are actually matches.

        :param radius Candidates whose (first_score, last_score) vector is more than radius from (1,1) will be dropped
        :return: A DataFrame of features with columns first_score, last_score, full_score, year_score, age_score
        """
        if self.candidate_pairs is None:
            self.set_candidate_pairs()
        # Compute similarity scores for the included factors
        comparer = recordlinkage.Compare()
        comparer.string(left_on='first', right_on='first',
                        method='jarowinkler', label='first_score')
        comparer.add(JaroWinklerFirstOnly('first','first',label='first_only_score'))
        comparer.string(left_on='last', right_on='last',
                        method='jarowinkler', label='last_score')
        comparer.string(left_on='full', right_on='full', label='full_score')
        comparer.numeric(left_on='year', right_on='year', label='year_score')
        # comparer.string(left_on='high_school', right_on='high_school', label='high_school_score')
        comparer.add(JaroWinklerWithMissings('high_school','high_school',label='high_school_score'))
        # Note: the following line may throw an error since recordlinkage is not compatible with pandas >= 1.0.0
        # To fix this, got to ~\site-packages\recordlinkage\utils.py and change line 201 from
            # data = frame.loc[multi_index.get_level_values(level_i)]
            # to
            # data = frame.reindex(multi_index.get_level_values(level_i))
        print('Computing similarity scores...')
        features = comparer.compute(self.candidate_pairs,
                                    self.factors_cr, self.factors_rb)
        # Remove obviously bad matches
        features = features[(features.first_score - 1)**2 + (features.last_score - 1)**2 < radius**2]
        # Impute mean high school score for missings
        features['high_school_score'].fillna(features['high_school_score'].mean(),inplace=True)
        # Compile age comparison scores
        features['age_score'] = self.get_age_scores()
        self.features = features
        return features

    @staticmethod
    def cluster(features):
        """Uses KMeans clustering to try to separate features into two groups.
        This doesn't work very well for record linking.
        """
        kmeans = KMeans(n_clusters=2, random_state=0)
        labeled = kmeans.fit_predict(features)
        return pd.Series(labeled, index=features.index)

    def build_training_data(self, features=None, max_size=1000):
        """Generates a set of data that you can manually label and use to train a classifier."""
        if features is None:
            if self.features is None:
                features = self.assemble_features()
            else:
                features = self.features
        if len(features) > max_size:
            features = features.sample(max_size)
        cr_sample = self.cr.loc[features.index.get_level_values(0)]
        rb_sample = self.rb.loc[features.index.get_level_values(1)]
        data = pd.concat((features.reset_index(drop=True),
                          cr_sample.reset_index(drop=True),
                          rb_sample.reset_index(drop=True)),
                         axis=1)
        data.index = features.index
        return data

    @staticmethod
    def train_classifier(features, labels, saveas=None, seed=DEFAULT_SEED):
        """Trains a RandomForestClassifier that you can use to evaluate candidate pairs."""
        clf = RandomForestClassifier(50, max_depth=5, random_state=DEFAULT_SEED, class_weight='balanced')
        clf.fit(features, labels)
        if saveas is not None:
            joblib.dump(clf, saveas)
        return clf

    def load_classifier(self):
        """Load an sklearn classifier from a joblib file."""
        source = self.classifier_path
        clf = None
        if bool(self.new_classifier)==False:
            print(f"Load classifier from {source}")
            clf = joblib.load(source)
            assert(is_classifier(clf))
            print("Classifier successfully loaded.")
        else:
            print('Training new classifier...')
            training_data = self.training
            self.candidate_pairs = training_data.index
            self.assemble_features(radius=2.0)
            labels = training_data['is_match']
            clf = self.train_classifier(self.features, labels, source)
            assert(is_classifier(clf))
            print("Finished training new classifier.")       
        return clf

    def find_likely_matches(self, threshold=0.4, only_best=True, pid_dups=False, append_names=False, save_as=None):
        """Finds likely matches between class reports and red book data.
        Will automatically find candidate pairs and compute similarity features before using
        the provided sklearn classifier to narrow down likely matches.

        :param threshold: Pairs with match scores (predicted probabilities) less than this will be excluded.
        :param only_best: If True, will only include the best match if more than one match is found for a cr entry
        :pid_dups: If True, will allow for multiple matches for the same PID (but only one per RB index) if very confident
        :param append_names: If True, will add columns to the output with the names of the predicted matches.
        :return: A Pandas DataFrame with columns for the class report & red book indices and their match scores
        """
        print("Start finding likely matches now...")
        if self.features is None:
            self.assemble_features()
        probas = self.clf.predict_proba(self.features)[:, 1]
        matches = pd.DataFrame({'PID': self.features.index.get_level_values(0),
                                'index': self.features.index.get_level_values(1),
                                'confidence': probas}
                               )[probas > threshold]

        if only_best:
            matches.sort_values(by='confidence', ascending=False, inplace=True)
            matches.drop_duplicates(subset='index', keep='first', inplace=True)
            if pid_dups:
                matches['PID_dup'] = matches.duplicated(subset='PID', keep=False)
                # Keep PID duplicates, only if very confident
                drop = matches[
                    (matches['confidence'] < 0.9) & (matches['PID_dup'] == 1)
                    ].index
                matches.drop(drop, inplace=True)
                # Reclassify duplicates
                matches.drop('PID_dup',inplace=True,axis=1)
                matches['PID_dup'] = matches.duplicated(subset='PID', keep=False)
            else:
                matches.drop_duplicates(subset='PID', keep='first', inplace=True)
        if append_names:
            matches['cr_name'] = [self.cr.loc[pid]['name'] for pid in matches['PID']]
            matches['rb_name'] = [self.rb.loc[idx]['name'] for idx in matches['index']]
        matches.reset_index(drop=True, inplace=True)
        if save_as is not None:
            matches.to_csv(save_as, index=False)
        return matches


def match(class_report_file, red_books_file, training_data_file,output_file=None):

    mf = MatchFinder(class_report_file,red_books_file,training_data_file)
    matches = mf.find_likely_matches(save_as=output_file)
    return matches


def fancy_drop(df):
    """This doesn't work right now! Does not retain any entries where both indices are duplicates!"""
    # Identify duplicated PIDs
    pid_groups = df.groupby('PID')
    pid_counts = pid_groups.size()
    duplicated_pids = pid_counts.index[pid_counts > 1]
    # Identify duplicated redbook indices
    idx_groups = df.groupby('index')
    idx_counts = idx_groups.size()
    duplicated_idxs = idx_counts.index[idx_counts > 1]
    # Retain entries that have either a unique PID or a unique redbook index
    return pd.DataFrame([r for i, r in df.iterrows() if (i not in duplicated_pids) or (i not in duplicated_idxs)])


def merge_match_files(filenames, drop='strict', save_as=None):
    df = pd.concat((pd.read_csv(f) for f in filenames))
    df.sort_values(by='confidence', ascending=False, inplace=True)
    if drop == 'strict':
        df.drop_duplicates(subset='PID', keep='first', inplace=True)
        df.drop_duplicates(subset='index', keep='first', inplace=True)
    elif drop == 'fancy':
        df = fancy_drop(df)
    if save_as is not None:
        df.to_csv(save_as, index=False)
    return df


def train_new_classifier(class_report_file, red_books_file,
                         training_data_file, saveas=None):
    #training_data = pd.read_csv(training_data_file, index_col=(0,1))
    mf = MatchFinder(class_report_file, red_books_file,training_data_file)
    training_data = mf.training
    mf.candidate_pairs = training_data.index
    mf.assemble_features(radius=2.0)
    labels = training_data['is_match']
    clf = mf.train_classifier(mf.features, labels, saveas)
    return clf
