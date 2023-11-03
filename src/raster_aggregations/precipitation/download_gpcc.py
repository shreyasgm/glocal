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
        "/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas/proj/2023-02-05 - Pipeline/precipitation"
    )
ROOT = PROJ.parents[2]
DATA = ROOT / "data/"

# Import custom modules
sys.path.append(str(PROJ))
sys.path.append(str(ROOT / "src/"))
from general_utils import *



def run_gpcc_downloads():
    # Download gpcc data and unpack
    start_years = list(range(1891, 2021, 10))
    end_years = list(range(1900, 2020, 10)) + [2019]
    gpcc_links = [f"https://opendata.dwd.de/climate_environment/GPCC/full_data_monthly_v2020/025/full_data_monthly_v2020_{start_year}_{end_year}_025.nc.gz" for start_year, end_year in zip(start_years, end_years)]

    download_urls_to_dir(gpcc_links, DATA / "raw/rasters/precipitation/gpcc")
    
    # Unpack data
    for file in (DATA / "raw/rasters/precipitation/gpcc").glob("*.gz"):
        unpack_file(file)

if __name__ == "__main__":
    run_gpcc_downloads()