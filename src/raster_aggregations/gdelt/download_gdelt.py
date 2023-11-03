"""
Download GPCP precipitation data
"""

import requests
import json
import os
import sys
from pathlib import Path
from bs4 import BeautifulSoup
from time import sleep
import requests
from tqdm import tqdm
from parfive import Downloader
from parfive import SessionConfig


# Set filepaths
PROJ = Path(os.path.realpath("."))
if str(PROJ) == "/n/home10/shreyasgm":
    PROJ = Path(
        "/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas/proj/2023-02-05 - Pipeline/gdelt"
    )
ROOT = PROJ.parents[2]
DATA = ROOT / "data/"

# Import custom modules
sys.path.append(str(PROJ))
sys.path.append(str(ROOT / "src/"))
from general_utils import *



def run_gdelt_downloads():
    # Download gdelt data and unpack
    gdelt_link = ["https://www.dropbox.com/sh/lfyzmvmnvpvt32j/AAAf8FYMar-iL3vBtXV19V2va?dl=1"]

    download_urls_to_dir(gdelt_link, DATA / "raw/rasters/gdelt/")
    
    # Unpack data
    for file in (DATA / "raw/rasters/gdelt/").glob("*."):
        unpack_file(file)

if __name__ == "__main__":
    run_gdelt_downloads()