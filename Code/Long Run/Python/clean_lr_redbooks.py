import pandas as pd
import re
import os
import sys
from datetime import datetime
from tqdm import tqdm
import multiprocessing as mp

sys.path.append(".")

from create_redbooks_master import clean_rb_file, merge_w_ocr_version

REDBOOKS_MASTER = '../../../Intermediate Data/Excel Files/longrun_series_redbooks.csv'
RAW_REDBOOKS_DIR = '../../../Raw Data/Red_Books/hand_coded_with_longrun'
OCR_VERSION = '../../../Raw Data/Red_Books/OCRed/red_books_allyears.csv'


def main(outfile=REDBOOKS_MASTER,n_cores=16):
    files = [os.path.join(RAW_REDBOOKS_DIR, f) for f in os.listdir(RAW_REDBOOKS_DIR) \
         if re.search(r'^(template_)?(\d{4})\.xlsx',f)]
    
    # Set up parallelizing
    manager = mp.Manager()
    return_dict = manager.dict()

    pool = mp.Pool(n_cores)

    # Clean multiple years parallel and stored results to return_dict
    for file in files:
        pool.apply_async(clean_rb_file, args=(file,return_dict))
        
    # Tell the pool that there are no more tasks to come and join
    pool.close()
    pool.join()
    
    # Make a long dataset of all years
    df = pd.concat([return_dict[year] for year in return_dict])
    df.sort_values(['year','index'],inplace=True)
    df.reset_index(inplace=True)
    
    # Export to filename
    df.to_csv(outfile,sep=",",index=False)

    # Merge on OCR files for pre 1940 years
    merge_w_ocr_version(outfile, OCR_VERSION)


if __name__ == '__main__':

    # Rename the old redbook master file
    if os.path.isfile(REDBOOKS_MASTER):
        try:
            os.rename(
                REDBOOKS_MASTER, 
                os.path.splitext(REDBOOKS_MASTER)[0] + datetime.now().strftime('_old_%Y-%m-%d.csv')
                )
        except FileExistsError:
            pass
    
    # Clean all redbooks files
    if len(sys.argv) > 1:
        main(sys.argv[1])
    else:
        main()
    