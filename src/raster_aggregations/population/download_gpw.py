"""
Python script that downloads NASA GPW data from SEDAC
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
import aiohttp

# Set filepaths
PROJ = Path(os.path.realpath("."))
if str(PROJ) == "/n/home10/shreyasgm":
    PROJ = Path(
        "/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas/proj/2023-02-05 - Pipeline/population"
    )
ROOT = PROJ.parents[2]
DATA = ROOT / "data/"

# Import custom modules
sys.path.append(str(PROJ))
sys.path.append(str(ROOT / "src/"))
from general_utils import *


import requests  # get the requsts library from https://github.com/requests/requests


# Uses some sample code from https://wiki.earthdata.nasa.gov/display/EL/How+To+Access+Data+With+Python


class SessionWithHeaderRedirection(requests.Session):
    """overriding requests.Session.rebuild_auth to mantain headers when redirected"""

    AUTH_HOST = "urs.earthdata.nasa.gov"

    def __init__(self, username, password):
        super().__init__()
        self.auth = (username, password)

    # Overrides from the library to keep headers when redirected to or from
    # the NASA auth host.

    def rebuild_auth(self, prepared_request, response):
        headers = prepared_request.headers
        url = prepared_request.url
        if "Authorization" in headers:
            original_parsed = requests.utils.urlparse(response.request.url)
            redirect_parsed = requests.utils.urlparse(url)
            if (
                (original_parsed.hostname != redirect_parsed.hostname)
                and redirect_parsed.hostname != self.AUTH_HOST
                and original_parsed.hostname != self.AUTH_HOST
            ):
                del headers["Authorization"]
        return


def earthdata_download(username, password, url, filename):
    # create session with the user credentials that will be used to authenticate access to the data
    session = SessionWithHeaderRedirection(username, password)

    try:
        # submit the request using the session
        response = session.get(url, stream=True)
        print(f"Earthdata page response: {response.status_code}")
        # raise an exception in case of http errors
        response.raise_for_status()

        # save the file
        with open(filename, "wb") as fd:
            for chunk in response.iter_content(chunk_size=1024 * 1024):
                fd.write(chunk)

    except requests.exceptions.HTTPError as e:
        # handle any errors here
        print(e)


# First read username and password from a separate file (not in repo)
# Then download GPW data


def run_gpw_downloads():
    # Download GPW data
    # Read username and password from file credentials.txt
    with open(PROJ / "credentials.txt", "r") as f:
        username = f.readline().strip()
        password = f.readline().strip()

    print("Read credentials for NASA Earthdata login")
    print("Downloading...")

    # Download GPW data
    gpw_links = [
        "https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-count-adjusted-to-2015-unwpp-country-totals-rev11/gpw-v4-population-count-adjusted-to-2015-unwpp-country-totals-rev11_2000_30_sec_tif.zip",
        "https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-count-adjusted-to-2015-unwpp-country-totals-rev11/gpw-v4-population-count-adjusted-to-2015-unwpp-country-totals-rev11_2005_30_sec_tif.zip",
        "https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-count-adjusted-to-2015-unwpp-country-totals-rev11/gpw-v4-population-count-adjusted-to-2015-unwpp-country-totals-rev11_2010_30_sec_tif.zip",
        "https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-count-adjusted-to-2015-unwpp-country-totals-rev11/gpw-v4-population-count-adjusted-to-2015-unwpp-country-totals-rev11_2015_30_sec_tif.zip",
        "https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-count-adjusted-to-2015-unwpp-country-totals-rev11/gpw-v4-population-count-adjusted-to-2015-unwpp-country-totals-rev11_2020_30_sec_tif.zip",
        "https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-density-adjusted-to-2015-unwpp-country-totals-rev11/gpw-v4-population-density-adjusted-to-2015-unwpp-country-totals-rev11_2000_30_sec_tif.zip",
        "https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-density-adjusted-to-2015-unwpp-country-totals-rev11/gpw-v4-population-density-adjusted-to-2015-unwpp-country-totals-rev11_2005_30_sec_tif.zip",
        "https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-density-adjusted-to-2015-unwpp-country-totals-rev11/gpw-v4-population-density-adjusted-to-2015-unwpp-country-totals-rev11_2010_30_sec_tif.zip",
        "https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-density-adjusted-to-2015-unwpp-country-totals-rev11/gpw-v4-population-density-adjusted-to-2015-unwpp-country-totals-rev11_2015_30_sec_tif.zip",
        "https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-density-adjusted-to-2015-unwpp-country-totals-rev11/gpw-v4-population-density-adjusted-to-2015-unwpp-country-totals-rev11_2020_30_sec_tif.zip",
    ]

    # If output folder does not exist, create it
    if not (DATA / "raw/rasters/population").exists():
        (DATA / "raw/rasters/population").mkdir()

    # Download each file
    for link in gpw_links:
        # Get filename
        filename = link.split("/")[-1]
        # Check if file already exists
        if (DATA / "raw/rasters/population" / filename).exists():
            print(f"File {filename} already exists. Skipping.")
            continue
        # Download file
        earthdata_download(
            username, password, link, DATA / "raw/rasters/population" / filename
        )

    # Unpack GPW data
    for zip_file in list_local_files(DATA / "raw/rasters/population", "*.zip"):
        if (DATA / "raw/rasters/population" / zip_file.stem).exists():
            print(f"File {zip_file.stem} already exists. Skipping.")
            continue
        unpack_file(zip_file)

    # For each file in the folder that ends with _tif, rename it to end with .tif
    for file in list_local_files(DATA / "raw/rasters/population", "*_tif"):
        os.rename(file, str(file)[:-4] + ".tif")

    return

if __name__ == "__main__":
    run_gpw_downloads()