"""
Download FAO data
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
        "/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas/proj/2023-02-05 - Pipeline/fao"
    )
ROOT = PROJ.parents[2]
DATA = ROOT / "data/"

# Import custom modules
sys.path.append(str(PROJ))
sys.path.append(str(ROOT / "src/"))
from general_utils import *



def run_fao_downloads():
    # Download FAO data and unpack
    yield_link = "https://s3.eu-west-1.amazonaws.com/data.gaezdev.aws.fao.org/res06.zip"
    production_gap_link = "https://s3.eu-west-1.amazonaws.com/data.gaezdev.aws.fao.org/res07.zip"
    
    download_urls_to_dir([yield_link, production_gap_link], DATA / "raw/rasters/fao")
    
    # Unpack yield data
    unpack_file(DATA / "raw/rasters/fao" / "res06.zip")

    # Unpack production gap data
    unpack_file(DATA / "raw/rasters/fao" / "res07.zip")
