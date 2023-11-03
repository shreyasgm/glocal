"""
Clean VIIRS, threshold, extract dataframe
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
import seaborn as sns

# Geospatial
import folium
import geopandas as gpd
import geemap

# Earth engine API
import ee

try:
    ee.Initialize()
except Exception as e:
    ee.Authenticate()
    ee.Initialize()

# Set filepaths
PROJ = Path(os.path.realpath("."))
if str(PROJ)=="/n/home10/shreyasgm":
    PROJ = Path("/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas/proj/2021-07-28 - GEE")
ROOT = PROJ.parents[1]
DATA = ROOT / "data/"

sys.path.append(str(ROOT / "src/"))
from gee_utils import *


def prepare_gadm_without_geometry():
    for x in [0, 1, 2]:
        print(x)
        df = gpd.read_file(
            ROOT / f"data/raw/shapefiles/gadm/gadm36_{x}.shp", ignore_geometry=True
        )
        df.to_parquet(
            ROOT / f"data/intermediate/gadm_without_geometry/gadm36_{x}.parquet",
            index=False,
        )


def add_modis_to_viirs_img(img):
    """
    Add MODIS landcover band based on year
    Note: MODIS images only available till 2019
    """
    # year = img.date().get("year")
    year = 2019
    modis_landcover = (
        ee.ImageCollection("MODIS/006/MCD12Q1")
        .filterDate(ee.Date.fromYMD(year, 1, 1), ee.Date.fromYMD(year, 12, 31))
        .select("LW")
        .first()
    )
    return img.addBands(srcImg=modis_landcover)


def set_noise_threshold(img, water_mask, country_boundaries_ee, scaleFactor):
    threshold = (
        img.updateMask(water_mask)
        .reduceRegion(
            reducer=ee.Reducer.median(),
            geometry=country_boundaries_ee,
            scale=scaleFactor,
            bestEffort=True,
        )
        .get("avg_rad")
    )
    threshold_img = ee.Number(threshold)
    img = img.set("noise_threshold", threshold)
    return img.updateMask(img.gte(threshold_img))


def get_time_series_viirs_gadm(
    cntry_selected_abbr,
    selected_admin_level,
    vcm_type,
    scaleFactor,
    export_to_gcs=False,
    gcs_bucket=None,
):
    # VIIRS raster
    viirs_ic = ee.ImageCollection(
        f"NOAA/VIIRS/DNB/MONTHLY_V1/{vcm_type.upper()}CFG"
    ).select("avg_rad")
    # MODIS raster
    modis_year = 2019
    modis_landcover = (
        ee.ImageCollection("MODIS/006/MCD12Q1")
        .filterDate(
            ee.Date.fromYMD(modis_year, 1, 1), ee.Date.fromYMD(modis_year, 12, 31)
        )
        .select("LW")
        .first()
    )
    # Load administrative boundaries
    country_boundaries_ee, admin_boundaries_ee = load_admin_boundaries(
        cntry_selected_abbr, selected_admin_level
    )
    # Get mask value
    water_mask = modis_landcover.eq(1)
    fx = lambda x: set_noise_threshold(
        x, water_mask, country_boundaries_ee, scaleFactor
    )
    viirs_ic = viirs_ic.map(fx)
    # Reducing image values
    reduced_admin = get_reduced_imagecollection(
        viirs_ic, fc_boundaries=admin_boundaries_ee, scaleFactor=500, grouped=False
    )
    # Extract results
    results = extract_reduction_results(
        reduced_admin,
        id_cols=[f"GID_{selected_admin_level}"],
        export_to_gcs=export_to_gcs,
        gcs_bucket=gcs_bucket,
    )
    return results


def get_time_series_viirs_ghs(cntry_selected_abbr, vcm_type, scaleFactor):
    # VIIRS raster
    viirs_ic = ee.ImageCollection(
        f"NOAA/VIIRS/DNB/MONTHLY_V1/{vcm_type.upper()}CFG"
    ).select("avg_rad")
    # MODIS raster
    modis_year = 2019
    modis_landcover = (
        ee.ImageCollection("MODIS/006/MCD12Q1")
        .filterDate(
            ee.Date.fromYMD(modis_year, 1, 1), ee.Date.fromYMD(modis_year, 12, 31)
        )
        .select("LW")
        .first()
    )
    # Load city boundaries
    city_boundaries_ee = load_city_boundaries(cntry_selected_abbr)
    # Load administrative boundaries
    country_boundaries_ee, admin_boundaries_ee = load_admin_boundaries(
        cntry_selected_abbr, 1
    )
    # Get mask value
    water_mask = modis_landcover.eq(1)
    fx = lambda x: set_noise_threshold(
        x, water_mask, country_boundaries_ee, scaleFactor
    )
    viirs_ic = viirs_ic.map(fx)
    # Reducing image values
    reduced_admin = get_reduced_imagecollection(
        viirs_ic, fc_boundaries=city_boundaries_ee, scaleFactor=500, grouped=False
    )
    # Extract results
    results_df = extract_reduction_results(reduced_admin, id_cols=["ghs_id"])
    return results_df


def process_viirs_all_gadm(
    cntry_selected_abbr,
    viirs_ic,
    modis_landcover,
    selected_admin_level,
    vcm_type,
    scaleFactor,
    export_to_gcs=False,
    gcs_bucket=None,
):
    # Load administrative boundaries
    country_boundaries_ee, admin_boundaries_ee = load_admin_boundaries(
        cntry_selected_abbr, selected_admin_level
    )
    # Get mask value
    water_mask = modis_landcover.eq(1)
    fx = lambda x: set_noise_threshold(
        x, water_mask, country_boundaries_ee, scaleFactor
    )
    viirs_with_thresh = viirs_ic.map(fx)
    # Reducing image values
    reduced_admin = get_reduced_imagecollection(
        viirs_with_thresh,
        fc_boundaries=admin_boundaries_ee,
        scaleFactor=500,
        grouped=False,
    )
    # Extract results
    results = extract_reduction_results(
        reduced_admin,
        id_cols=[f"GID_{selected_admin_level}"],
        export_to_gcs=export_to_gcs,
        gcs_bucket=gcs_bucket,
    )
    return results
