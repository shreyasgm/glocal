"""
Download VIIRS rasters from EOG

"""


# Run file as `EOG_PASSWORD=your_password python download_viirs.py`

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
        "/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas/proj/2023-02-05 - Pipeline/viirs"
    )
ROOT = PROJ.parents[2]
DATA = ROOT / "data/"

# Import custom modules
sys.path.append(str(PROJ))
sys.path.append(str(ROOT / "src/"))
from general_utils import *


def get_headers():
    """Get header for EOG request"""
    # Retrieve access token
    params = {
        "client_id": "eogdata_oidc",
        "client_secret": "2677ad81-521b-4869-8480-6d05b9e57d48",
        "username": "shreyas.gm61@gmail.com",
        "password": os.environ["EOG_PASSWORD"],
        "grant_type": "password",
    }
    token_url = (
        "https://eogauth.mines.edu/auth/realms/master/protocol/openid-connect/token"
    )
    response = requests.post(token_url, data=params)
    access_token_dict = json.loads(response.text)
    access_token = access_token_dict.get("access_token")
    # Submit request with token bearer
    ## Change data_url variable to the file you want to download
    auth = "Bearer " + access_token
    headers = {"Authorization": auth}
    return headers


def download_url_to_file(url, outfile, headers):
    import functools
    from pathlib import Path
    import shutil

    r = requests.get(url, stream=True, allow_redirects=True, headers=headers)
    if r.status_code != 200:
        r.raise_for_status()  # Will only raise for 4xx codes, so...
        raise RuntimeError(f"Request to {url} returned status code {r.status_code}")
    file_size = int(r.headers.get("Content-Length", 0))

    path = Path(outfile).expanduser().resolve()
    path.parent.mkdir(parents=True, exist_ok=True)

    desc = "(Unknown total file size)" if file_size == 0 else ""
    r.raw.read = functools.partial(
        r.raw.read, decode_content=True
    )  # Decompress if needed
    with tqdm.wrapattr(r.raw, "read", total=file_size, desc=desc) as r_raw:
        with path.open("wb") as f:
            shutil.copyfileobj(r_raw, f)

    return path


def download_urls(urls, output_dir, headers=None):
    """Download list of urls to output_dir in parallel"""
    if headers is None:
        headers = get_headers()


def list_available_rasters(
    rasters_root_url="https://eogdata.mines.edu/nighttime_light/annual/v21/",
    endswith_filter=None,
):
    # List available rasters
    years_list = np.arange(2012, 2022)
    rasters_year_urls = {x: rasters_root_url + str(x) + "/" for x in years_list}

    # Get list of rasters
    download_links = {}
    for year, rasters_year in rasters_year_urls.items():
        rasters_year = rasters_year_urls[year]
        # Wait to avoid getting blocked
        sleep(random.uniform(0.5, 1.5))
        # Parse html, get list of folders from table with id "indexlist"
        r = requests.get(rasters_year)
        soup = BeautifulSoup(r.text, "html.parser")
        table = soup.find("table", {"id": "indexlist"})
        # Get all rows and links from each row
        rows = table.find_all("tr")
        year_download_links = []
        for row in rows:
            rowlink = row.find("a").get("href")
            endswith_met = endswith_filter is None or rowlink.endswith(endswith_filter)
            if rowlink.endswith(".gz") and endswith_met:
                row_download_link = rasters_year + rowlink
                year_download_links.append(row_download_link)
        download_links[year] = year_download_links
    return download_links


def get_files_to_download(download_links, outpath):
    # Check if files already exist at outpath
    # If exists, check if file is empty
    files_to_download = []
    for year, year_download_links in download_links.items():
        for link in year_download_links:
            filename = link.split("/")[-1]
            outpath_file = outpath / filename
            # Append if file does not exist or is empty
            if not outpath_file.exists() or outpath_file.stat().st_size == 0:
                files_to_download.append(link)
    return files_to_download


if __name__ == "__main__":
    # Get list of available rasters
    download_links = list_available_rasters(
        rasters_root_url="https://eogdata.mines.edu/nighttime_light/annual/v21/",
        endswith_filter=".median_masked.dat.tif.gz",
    )

    # Get files to download
    outpath = DATA / "raw/rasters/viirs/vnl_v2.1"
    files_to_download = get_files_to_download(download_links, outpath)

    # Get headers
    headers = get_headers()

    # Use parfive to download files
    dl = Downloader(max_conn=1, max_splits=3, progress=True, overwrite=False)
    for file_to_queue in files_to_download:
        dl.enqueue_file(file_to_queue, path=outpath, headers=headers)
    # Download
    res = dl.download()
    # if any files error out, retry
    if res.errors:
        sleep(5)
        dl.retry(res)

    # Unpack each of the files
    for file in files_to_download:
        # Check if file already unpacked
        filename = file.split("/")[-1]
        outpath_file = outpath / filename
        outpath_file = outpath_file.with_suffix("")
        if not outpath_file.exists():
            unpack_file(outpath_file)