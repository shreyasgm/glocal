"""
Download wind power potential data
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
        "/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas/proj/2023-02-05 - Pipeline/wind_potential"
    )
ROOT = PROJ.parents[2]
DATA = ROOT / "data/"

# Import custom modules
sys.path.append(str(PROJ))
sys.path.append(str(ROOT / "src/"))
from general_utils import *


def run_downloads():
    # Download wind_potential data and unpack
    download_dir = DATA / "raw/rasters/wind_potential/"

    wind_pot_links = {
        "https://data.dtu.dk/ndownloader/files/17248214": "wind_potential_50m_2019.tif",
        "https://data.dtu.dk/ndownloader/files/17251376": "wind_potential_150m_2019.tif",
        "https://data.dtu.dk/ndownloader/files/17258036": "wind_potential_10m_2019.tif",
        "https://data.dtu.dk/ndownloader/files/17263265": "wind_potential_100m_2019.tif",
        "https://data.dtu.dk/ndownloader/files/17265269": "wind_potential_200m_2019.tif",
    }

    download_urls_to_dir(wind_pot_links.keys(), download_dir)

    # Rename files using dict
    for file in download_dir.glob("*"):
        new_name = wind_pot_links["https://data.dtu.dk/ndownloader/files/" + file.name]
        file.rename(file.parent / new_name)


if __name__ == "__main__":
    run_downloads()
