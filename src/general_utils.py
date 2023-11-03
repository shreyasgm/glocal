"""
Utilities for working with GEE

- Aggregating rasters on GEE to polygons (FeatureCollections)
- Grouped aggregations
"""

# Standard
import os
import sys
import random
import re
from pathlib import Path
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import dask.dataframe as dd
from time import sleep
import seaborn as sns
from google.cloud import storage as gcs
from parfive import Downloader
from parfive import SessionConfig


def initialize_gcs(bucketname="earth_engine_aggregations"):
    client = gcs.Client()
    bucket = client.get_bucket(bucketname)
    return bucket


def check_if_file_exists_gcs(filename, bucket, overwrite=False):
    if overwrite:
        return False
    else:
        return gcs.Blob(bucket=bucket, name=filename).exists()


def list_gcp_files(
    bucketname="earth_engine_aggregations", foldername=None, pattern=None
):
    """
    List files in GCP bucket / folder
    """
    from google.cloud import storage as gcs

    # List all files
    client = gcs.Client()
    blobs = client.list_blobs(bucketname, prefix=foldername)
    files = [x.name for x in blobs]
    # Check pattern match
    if pattern:
        r = re.compile(pattern)
        files = [x for x in files if r.match(x)]
    return files


def delete_errored_files(res_errors):
    # Try deleting any errored files
    print("Errors encountered while downloading: \n")
    for error in res_errors:
        try:
            print("------------------")
            error_filepath_func = error[0]
            error_filepath = error_filepath_func(resp=None, url=error[1])

            print(f"Filepath function: {error[0]}")
            print(f"URL: {error[1]}")
            print(f"Exception: {error[2]}")
            
            print(f"Trying to delete: {error_filepath}")
            os.remove(error_filepath)
            print("File deleted.")
        except Exception as e:
            print("Error deleting file: ", e)
            


def download_urls_to_dir(
    urls, outdir, max_conn=5, max_splits=5, retries=2, overwrite=False, sessionconfig_kwargs={}, enqueue_kwargs={}
):
    """Download file from url to outdir using parfive"""
    # Create outdir if it doesn't exist
    outdir = Path(outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    # Create downloader
    if sessionconfig_kwargs is None:
        config=None
    else:
        config=SessionConfig(**sessionconfig_kwargs)
    dl = Downloader(
        max_conn=max_conn,
        max_splits=max_splits,
        progress=True,
        overwrite=overwrite,
        config=config,
    )

    # Queue files for download
    # Print list of urls to download
    print("Downloading files:")
    for url in urls:
        print(url)
        dl.enqueue_file(url, path=outdir, **enqueue_kwargs)

    # Wait for download to finish
    # If any files error out, retry errored files times
    res = dl.download()
    
    # If errors, retry
    if res.errors:
        for i in range(retries):
            # Keep retrying until no errors, max retries times
            if res.errors:
                delete_errored_files(res.errors)
                print(f"Download failed. Retrying {i+1} of {retries} times")
                sleep(5)
                res = dl.retry(res)
                if res.errors:
                    delete_errored_files(res.errors)
            else:
                break
    return

def delete_small_files(folderpath, pattern=None, min_size_mb=10):
    """
    Delete files smaller than min_size_mb in megabytes
    """
    # Read filelist
    if pattern is None:
        pattern = "*.*"
    filelist = list(Path(folderpath).glob(pattern))
    # Delete files smaller than min_size_mb
    for filepath in filelist:
        if filepath.stat().st_size < min_size_mb * 1e6:
            print(f"Deleting {filepath}")
            os.remove(filepath)
    return

def list_local_files(folderpath, pattern=None):
    """
    List local files in directory
    """
    # read filelist
    if pattern is None:
        pattern = "*.*"
    csvlist = list(Path(folderpath).glob(pattern))
    # Make sure file exists and has data in it
    csvlist_valid = [x for x in csvlist if x.stat().st_size > 10]
    return csvlist_valid


def download_missing_gcp(
    local_folderpath,
    gcs_bucketname="earth_engine_aggregations",
    gcs_foldername=None,
    overwrite=False,
    pattern=None,
    n_jobs=None,
):
    from tqdm import tqdm
    from google.cloud import storage as gcs

    # List missing files
    local_files = list_local_files(folderpath=local_folderpath, pattern=pattern)
    local_files = [x.name for x in local_files]
    gcs_files = list_gcp_files(
        bucketname=gcs_bucketname, foldername=gcs_foldername, pattern=pattern
    )
    if overwrite:
        missing_files = list(set(gcs_files))
    else:
        missing_files = list(set(gcs_files) - set(local_files))
    # Download
    client = gcs.Client()
    bucket = client.bucket(gcs_bucketname)

    def download_file_from_bucket(bucket, filename, local_folderpath):
        blob = bucket.blob(filename)
        blob.download_to_filename(Path(local_folderpath) / filename)

    if n_jobs is None:
        for filename in tqdm(missing_files):
            download_file_from_bucket(bucket, filename, local_folderpath)
        return missing_files
    else:
        from joblib import Parallel, delayed

        Parallel(n_jobs=n_jobs)(
            delayed(download_file_from_bucket)(bucket, f, local_folderpath)
            for f in tqdm(missing_files)
        )
        return missing_files


def compile_downloaded_files(infolder, infiles_pattern, outfile):
    # Process downloaded csv's from GCS
    csv_dict = {}
    csvlist = list(Path(infolder).glob(infiles_pattern))
    # Make sure file exists and has data in it
    csvlist_valid = [x for x in csvlist if x.stat().st_size > 2]
    print(outfile)
    print(f"Total files: {len(csvlist)} ..... Valid files: {len(csvlist_valid)}")
    # Read files
    df = dd.read_csv(csvlist_valid, include_path_column="fname")
    df["date"] = dd.to_datetime(df["date"])
    df = df.compute()
    # Export
    df.to_parquet(outfile, index=False)



def unpack_file(filepath):
    """
    Unpack archive file to the same directory (zip, tar, etc.)
    """
    import shutil
    filepath = Path(filepath)
    shutil.unpack_archive(filepath, filepath.parent)
    