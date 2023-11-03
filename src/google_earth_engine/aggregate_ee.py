import os
import random
import re
import sys
from pathlib import Path
import argparse
from argparse import RawTextHelpFormatter

import geopandas as gpd
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

from google.cloud import storage as gcs

# Google earth engine
import ee

try:
    ee.Initialize()
except Exception as e:
    ee.Authenticate()
    ee.Initialize()

from gee_utils import *


def aggregate_ee(
    img_ee,
    boundaries_ee,
    id_cols,
    scaleFactor=None,
    set_date=None,
    export_to_gcs=False,
    gcs_bucket=None,
):
    """
    Aggregate earth engine Image or ImageCollection to boundaries (FeatureCollection)

    Args:
        img_ee: Earth Engine Image / ImageCollection
        boundaries_ee: Earth Engine FeatureCollection with geometries to aggregate to
        id_cols: ID columns from boundaries_ee to aggregate by
        scaleFactor: Earth Engine reduceRegions scaleFactor
        set_date: Date to set if image does not have a timestamp
        export_to_gcs: Whether to export to Google Cloud Storage. Otherwise, string with CSV filename to create.
        gcs_bucket: Name of GCS bucket

    Returns:
        If export_to_gcs is False, then DataFrame with results, else, GCS task
    """
    # Check if Image or ImageCollection
    if isinstance(img_ee, ee.imagecollection.ImageCollection):
        # Reduce
        reduced_fc = get_reduced_imagecollection(
            img_ee, fc_boundaries=boundaries_ee, scaleFactor=scaleFactor, grouped=False
        )
    else:
        # Reduce
        reduced_fc = get_reduced_image(
            img_ee,
            fc_boundaries=boundaries_ee,
            scaleFactor=scaleFactor,
            set_date=pd.to_datetime(set_date),
        )

    # Extract
    results = extract_reduction_results(
        reduced_fc,
        id_cols=id_cols,
        export_to_gcs=export_to_gcs,
        gcs_bucket=gcs_bucket,
    )
