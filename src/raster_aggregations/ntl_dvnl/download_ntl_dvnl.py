"""
Download ntl_dvnl data
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
        "/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas/proj/2023-02-05 - Pipeline/ntl_dvnl"
    )
ROOT = PROJ.parents[2]
DATA = ROOT / "data/"

# Import custom modules
sys.path.append(str(PROJ))
sys.path.append(str(ROOT / "src/"))
from general_utils import *


def run_downloads():
    # Download ntl_dvnl data and unpack
    download_dir = DATA / "raw/rasters/ntl_dvnl/"

    download_links = [f"https://eogdata.mines.edu/wwwdata/viirs_products/dvnl/DVNL_{x}.tif" for x in range(2013, 2020)]

    download_urls_to_dir(download_links, download_dir, max_conn=1)

    # Unpack data
    for file in (download_dir).glob("*.gz"):
        unpack_file(file)


if __name__ == "__main__":
    run_downloads()
