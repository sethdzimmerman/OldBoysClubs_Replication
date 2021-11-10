import pandas as pd
import os
from tqdm import tqdm
import re
import sys
sys.path.insert(0, '.')
from gender import split_name

ROOMS_DIR = "../../../Raw Data/Room_assignments"
OUT_FILE = '../../../Intermediate Data/Excel Files/longrun_series_rooms.csv'


def clean_rooms(rawdir):    
    rooms = {}
    print("\nStart cleaning rooms now...")
    for file in tqdm(os.listdir(rawdir)):
        if file.endswith(".csv"):
            year = int(re.search(r'(\d{4})',file).group(1))
            df = pd.read_csv(os.path.join(rawdir,file),
                             usecols=['name', 'year1', 'year2', 'dorm', 'roomno'],
                             engine='python',encoding='utf-8')
        
            # Deal with odd encoding in some years 
            # (data entries covered in b'' string)
            for col in df.columns:
                df[col] = [re.search(r'b\'(.+)\'',str(x)).group(1) 
                           if re.search(r'b\'(.+)\'',str(x)) else x  
                           for x in df[col]]

            # Set Datatypes
            df = df.astype(
                {'name': 'string',
                'year1': 'int',
                'year2': 'int',
                'dorm': 'string',
                'roomno': 'string',
                })

        # Year1 is year of class, year2, year of room residence
        df.rename(columns={'year1':'year'},inplace=True)

        # Split name    
        df['first'],df['middle'],df['last'] = \
            zip(*df['name'].map(split_name))

        # Only keep (likely) freshman dorm records
        df['fresh_predict'] = df.year - 4
        df['fresh_dist'] = abs(df.year2 - df.fresh_predict)
        df = df.loc[df.fresh_dist <= 1]

        # Only keep record that is closest to freshman year
        df['min_dist'] = df.groupby(['name','year'])['fresh_dist'].transform('min')
        df = df.loc[df.fresh_dist == df.min_dist]

        df.drop_duplicates(inplace=True)
        df.sort_values(['name','year','dorm','roomno'],inplace=True)
        df.reset_index(inplace=True,drop=True)
        
        df.drop(['fresh_predict','fresh_dist','min_dist'],axis=1,inplace=True)
        
        rooms[year] = df
        
    roomsdf = pd.concat([rooms[year] for year in rooms])
    
    return roomsdf


if __name__ == '__main__':
    df = clean_rooms(ROOMS_DIR)    
    df.to_csv(OUT_FILE, sep=",", index=False)
        
