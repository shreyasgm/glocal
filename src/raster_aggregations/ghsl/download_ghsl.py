"""
Download GHSL urban built up area data
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
        "/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas/proj/2023-02-05 - Pipeline/ghsl"
    )
ROOT = PROJ.parents[2]
DATA = ROOT / "data/"

# Import custom modules
sys.path.append(str(PROJ))
sys.path.append(str(ROOT / "src/"))
from general_utils import *


def run_downloads():
    # Download temperature data and unpack
    download_dir = DATA / "raw/rasters/ghsl/"

    builtup_links = [f"https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_BUILT_S_GLOBE_R2023A/GHS_BUILT_S_E{year}_GLOBE_R2023A_54009_100/V1-0/GHS_BUILT_S_E{year}_GLOBE_R2023A_54009_100_V1_0.zip" for year in list(range(1975, 2025, 5))]

    download_urls_to_dir(builtup_links, download_dir)

    # Unpack data
    for file in (download_dir).glob("*.zip"):
        unpack_file(file)


if __name__ == "__main__":
    run_downloads()
