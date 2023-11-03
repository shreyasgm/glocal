"""
Download ntl_dmsp_ext rasters from EOG

"""


# Run file as `EOG_PASSWORD=your_password python download_ntl_dmsp_ext.py`

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
        "/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas/proj/2023-02-05 - Pipeline/ntl_dmsp_ext"
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


def list_available_rasters(
    rasters_root_url="https://eogdata.mines.edu/wwwdata/dmsp/extension_series/",
    endswith_filter=".global.stable_lights.avg_vis.tif",
):
    # List available rasters
    # Get list of folders listed in the table
    soup = BeautifulSoup(requests.get(rasters_root_url).text, "html.parser")
    table = soup.find("table")
    rows = table.find_all("tr")
    rows = rows[1:]
    rows = [row.find_all("td") for row in rows]
    rows = [[cell.text for cell in row] for row in rows]
    folderlist = []
    for row in rows:
        for cell in row:
            if cell.endswith("/"):
                folderlist.append(cell)
    # For each year, keep only the latest satellite
    folder_df = pd.DataFrame({"folder": folderlist})
    folder_df[["satellite", "year"]] = (
        folder_df["folder"].str.replace("/", "").str.split("_", expand=True)
    )
    folder_df["year"] = folder_df["year"].astype(int)
    folder_df = folder_df.sort_values(["year", "satellite"], ascending=[True, False])
    # For each year, get the latest satellite
    folder_df = folder_df.groupby("year").head(1)
    folderlist = folder_df["folder"].tolist()
    # Loop through folders and get list of files that matches the filter
    download_links = []
    for folder in folderlist:
        # Get the table inside each folder
        folder_url = f"{rasters_root_url}{folder}/annual/"
        soup = BeautifulSoup(requests.get(folder_url).text, "html.parser")
        table = soup.find("table")
        rows = table.find_all("tr")
        rows = rows[1:]
        for row in rows:
            rowlink = row.find("a").get("href")
            endswith_met = endswith_filter is None or rowlink.endswith(endswith_filter)
            if rowlink.endswith(".tif") and endswith_met:
                row_download_link = f"{folder_url}{rowlink}"
                download_links.append(row_download_link)
    return download_links


def get_files_to_download(download_links, outpath):
    # Check if files already exist at outpath
    # If exists, check if file is empty
    files_to_download = []
    for link in download_links:
        filename = link.split("/")[-1]
        outpath_file = outpath / filename
        # Append if file does not exist or is empty
        if not outpath_file.exists() or outpath_file.stat().st_size == 0:
            files_to_download.append(link)
    return files_to_download


if __name__ == "__main__":
    # Get list of available rasters
    download_links = list_available_rasters(
        rasters_root_url="https://eogdata.mines.edu/wwwdata/dmsp/extension_series/",
        endswith_filter=".global.stable_lights.avg_vis.tif",
    )

    # Get files to download
    outpath = DATA / "raw/rasters/ntl_dmsp_ext/"
    files_to_download = get_files_to_download(download_links, outpath)

    # Get headers
    headers = get_headers()

    # Use parfive to download files
    dl = Downloader(max_conn=1, max_splits=2, progress=True, overwrite=False)
    for file_to_queue in files_to_download:
        dl.enqueue_file(file_to_queue, path=outpath, headers=headers)
    # Download
    res = dl.download()
    # if any files error out, retry
    if res.errors:
        sleep(5)
        dl.retry(res)
