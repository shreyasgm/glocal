"""
Download terrain ruggedness data
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
        "/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas/proj/2023-02-05 - Pipeline/ruggedness"
    )
ROOT = PROJ.parents[2]
DATA = ROOT / "data/"

# Import custom modules
sys.path.append(str(PROJ))
sys.path.append(str(ROOT / "src/"))
from general_utils import *


def run_downloads():
    # Download ruggedness data and unpack
    download_dir = DATA / "raw/rasters/ruggedness/"

    tri_link = "https://diegopuga.org/data/rugged/tri.zip"
    slope_link = "https://diegopuga.org/data/rugged/slope.zip"
    cellarea_link = "https://diegopuga.org/data/rugged/cellarea.zip"

    download_urls_to_dir([tri_link, slope_link, cellarea_link], download_dir)

    # Unpack data
    for file in (download_dir).glob("*.zip"):
        unpack_file(file)


if __name__ == "__main__":
    run_downloads()
