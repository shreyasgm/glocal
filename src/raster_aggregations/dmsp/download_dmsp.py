"""
Download DMSP rasters from EOG

"""


# Run file as `EOG_PASSWORD="your_password" python download_dmsp.py`

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
        "/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas/proj/2023-02-05 - Pipeline/dmsp"
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


def get_table_rows(url):
    # Parse html, get list of folders from table with id "indexlist"
    r = requests.get(url)
    soup = BeautifulSoup(r.text, "html.parser")
    table = soup.find("table", {"id": "indexlist"})
    # Get all rows and folder names from each row
    rows = table.find_all("tr")
    return rows


def get_folders_to_check(
    rasters_root_url="https://eogdata.mines.edu/wwwdata/dmsp/v4composites_rearrange/",
):
    # List available folders to download from
    rows = get_table_rows(rasters_root_url)
    dmsp_folders_list = []
    for row in rows:
        rowlink = row.find("a").get("href")
        if rowlink.endswith("/"):
            dmsp_folders_list.append(rowlink)
    return dmsp_folders_list


def get_folder_urls(dmsp_folders_list, rasters_root_url):
    # For each folder, open and get table rows again
    dmsp_folder_filenames = {}
    for dmsp_folder in dmsp_folders_list:
        rows = get_table_rows(rasters_root_url + dmsp_folder)
        folder_lights_url = None
        folder_cf_cvg_url = None
        for row in rows:
            rowlink = row.find("a").get("href")
            if rowlink.endswith(".global.intercal.stable_lights.avg_vis.tif"):
                folder_lights_filename = rowlink
            if rowlink.endswith(".global.cf_cvg.tif"):
                folder_cf_cvg_filename = rowlink
        dmsp_folder_filenames[dmsp_folder] = (
            folder_lights_filename,
            folder_cf_cvg_filename,
        )
    return dmsp_folder_filenames


def get_urls_to_download(
    dmsp_folder_filenames,
    rasters_root_url,
):
    # Create a pandas dataframe with folder names
    dmsp_folders = (
        pd.DataFrame.from_dict(
            dmsp_folder_filenames,
            orient="index",
            columns=["stable_lights_filename", "cf_cvg_filename"],
        )
        .reset_index()
        .rename(columns={"index": "folder"})
    )
    # Remove / at the end
    dmsp_folders["folder"] = dmsp_folders["folder"].str[:-1]
    # Split folder into satellite and year
    dmsp_folders[["satellite", "year"]] = dmsp_folders["folder"].str.split(
        "_", expand=True
    )
    # Remove F from satellite name
    dmsp_folders["satellite"] = dmsp_folders["satellite"].str[1:]
    # Convert satellite number to int
    dmsp_folders["satellite"] = dmsp_folders["satellite"].astype(int)
    # For each year, consider the latest available satellite
    dmsp_folders = dmsp_folders.sort_values(
        ["year", "satellite"], ascending=[True, False]
    )
    dmsp_folders = dmsp_folders.drop_duplicates(subset=["year"], keep="first")
    # Get download url for stable lights
    dmsp_folders["stable_lights_url"] = (
        rasters_root_url
        + dmsp_folders["folder"]
        + "/"
        + dmsp_folders["stable_lights_filename"]
    )
    # Get download url for cloud free coverage
    dmsp_folders["cf_cvg_url"] = (
        rasters_root_url
        + dmsp_folders["folder"]
        + "/"
        + dmsp_folders["cf_cvg_filename"]
    )
    return dmsp_folders


def filter_out_existing_files(download_links, outdir):
    # Check if files already exist at outdir
    # If exists, check if file is empty
    for link in download_links:
        filename = link.split("/")[-1]
        outpath = outdir / filename
        if outpath.exists():
            if os.path.getsize(outpath) > 0:
                download_links.remove(link)
    return download_links


def run_downloads(overwrite=False):
    rasters_root_url = "https://eogdata.mines.edu/wwwdata/dmsp/v4composites_rearrange/"
    # Get folders to check
    dmsp_folders_list = get_folders_to_check(rasters_root_url)
    # Get required filenames inside each folder
    dmsp_folder_filenames = get_folder_urls(dmsp_folders_list, rasters_root_url)
    # Get download links
    dmsp_folders = get_urls_to_download(dmsp_folder_filenames, rasters_root_url)
    # List files to download - stable lights
    stable_lights_outdir = DATA / "raw/rasters/dmsp/stable_lights"
    stable_lights_download_links = dmsp_folders["stable_lights_url"].tolist()
    stable_lights_download_links = filter_out_existing_files(
        stable_lights_download_links, stable_lights_outdir
    )
    # List files to download - cloud free coverage
    cf_cvg_outdir = DATA / "raw/rasters/dmsp/cloud_free_coverage"
    cf_cvg_download_links = dmsp_folders["cf_cvg_url"].tolist()
    cf_cvg_download_links = filter_out_existing_files(
        cf_cvg_download_links, cf_cvg_outdir
    )
    # Get headers
    headers = get_headers()
    # Use parfive to download files
    # Stable lights
    download_urls_to_dir(
        urls=stable_lights_download_links,
        outdir=stable_lights_outdir,
        max_conn=1,
        max_splits=1,
        retries=5,
        overwrite=overwrite,
        enqueue_kwargs={"headers": headers},
    )
    # Cloud free coverage
    download_urls_to_dir(
        urls=cf_cvg_download_links,
        outdir=cf_cvg_outdir,
        max_conn=1,
        max_splits=1,
        retries=5,
        overwrite=overwrite,
        enqueue_kwargs={"headers": headers},
    )

    # Delete files that weren't properly downloaded
    delete_small_files(stable_lights_outdir, pattern="*.tif", min_size_mb=10)
    delete_small_files(cf_cvg_outdir, pattern="*.tif", min_size_mb=10)

    # Unpack each of the files
    # Stable lights
    for filepath in stable_lights_outdir.glob("*.zip"):
        unpack_file(filepath)
    # Cloud free coverage
    for filepath in cf_cvg_outdir.glob("*.zip"):
        unpack_file(filepath)


if __name__ == "__main__":
    run_downloads(overwrite=False)
    