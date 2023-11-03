import os
import random
import re
import sys
from pathlib import Path
import warnings

import geopandas as gpd

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import dask.dataframe as dd
import seaborn as sns
from tqdm import tqdm


# Set filepaths
PROJ = Path(os.path.realpath("."))
if str(PROJ) == "/n/home10/shreyasgm":
    PROJ = Path(
        "/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas/proj/2021-07-28 - GEE"
    )
ROOT = PROJ.parents[1]
DATA = ROOT / "data/"

sys.path.append(str(PROJ))
sys.path.append(str(ROOT / "src"))
from gee_utils import *
from aggregate_ee import *
from general_utils import *

# Google earth engine
import ee

try:
    ee.Initialize()
except Exception as e:
    ee.Authenticate()
    ee.Initialize()


def aggregate_landcover_ic(
    lc_ic,
    admin_boundaries_ee,
    selected_admin_level,
    scaleFactor,
    categories_codebook_path,
    export_to_gcs=False,
    gcs_bucket=None,
):
    """
    Aggregate image with categorical values as a grouped reduction

    Args:
        lc_ic: Land cover imagecollection
        admin_boundaries_ee: earth engine admin boundaries
        selected_admin_level: GADM level
        scaleFactor: GEE scale
        categories_codebook_path: codebook with relevant cols to merge in
    """
    # Add pixel area band
    lc_ic = lc_ic.map(
        lambda x: ee.Image.pixelArea()
        .addBands(x)
        .set("system:time_start", x.get("system:time_start"))
        .copyProperties(x)
    )
    # Get reduction
    reduced_fc = get_reduced_imagecollection(
        lc_ic,
        admin_boundaries_ee,
        scaleFactor=scaleFactor,
        grouped=True,
        grouping_band_index=1,
        group_name="land_cover_category",
        reducers=["sum"],
    )
    # Get outputs
    results_df = extract_reduction_results_grouped(
        reduced_fc,
        id_cols=[
            f"GID_{selected_admin_level}",
        ],
        reducers=["sum"],
        export_to_gcs=export_to_gcs,
        gcs_bucket=gcs_bucket,
    )
    if export_to_gcs == False:
        # If a column called 0 exists, drop
        if 0 in results_df.columns:
            results_df = results_df.drop(columns=0)
        results_df["land_cover_category"] = pd.to_numeric(
            results_df["land_cover_category"]
        )
        results_df = results_df.sort_values(
            ["date", f"GID_{selected_admin_level}", "land_cover_category"]
        )
        # Read categories descriptions
        categories_df = pd.read_csv(categories_codebook_path)
        categories_df = categories_df.rename(columns={"Value": "land_cover_category"})
        categories_df = categories_df[
            ["land_cover_category", "category", "effective_category"]
        ].rename(
            columns={
                "category": "lc_detailed",
                "effective_category": "lc_effective",
            }
        )
        # Merge in categories
        results_df = results_df.merge(
            categories_df,
            on="land_cover_category",
            how="left",
        ).rename(
            columns={
                "land_cover_category": "lc_category_code",
            }
        )
        results_df = results_df.rename(columns={"sum": "area"})
    else:
        # Do nothing
        # Note that further processing is needed for GCS task results
        pass
    return results_df


def aggregate_landcover_all_countries(
    cntry_list_df,
    selected_admin_level,
    ee_landcover_ic,
    landcover_codebook_path,
    overwrite=False,
    scaleFactor=500,
    outfile_prefix="MODIS_landcover",
    gcs_bucketname="earth_engine_aggregations",
):
    # Init gcs
    bucket = initialize_gcs(gcs_bucketname)
    # Run for all countries
    results_dict = {}
    # Submit GCS tasks
    total_count = len(cntry_list_df)
    existing_count = 0
    processed_count = 0
    for i, cntry_row in tqdm(cntry_list_df.iterrows(), total=len(cntry_list_df)):
        # Set outfile name
        outfile = f"{outfile_prefix}_{cntry_row.GID_0}_level{selected_admin_level}"
        # Check if file exists
        if not check_if_file_exists_gcs(f"{outfile}.csv", bucket, overwrite=overwrite):
            cntry_selected_abbr = cntry_row.GID_0
            # Load administrative boundaries
            country_boundaries_ee, admin_boundaries_ee = load_admin_boundaries(
                cntry_selected_abbr, selected_admin_level
            )
            # Aggregate
            results = aggregate_landcover_ic(
                ee_landcover_ic,
                admin_boundaries_ee,
                selected_admin_level=selected_admin_level,
                scaleFactor=scaleFactor,
                categories_codebook_path=landcover_codebook_path,
                export_to_gcs=outfile,
                gcs_bucket=gcs_bucketname,
            )
            # Put result in dict
            results_dict[cntry_row.GID_0] = results
            processed_count += 1
        else:
            existing_count += 1
    # Print results
    print(
        f"Total: {total_count}, Existing: {existing_count}, Processed: {processed_count}"
    )
    return results_dict


def compile_landcover_gcs_results(
    gcs_results_folder,
    gcs_bucketname="earth_engine_aggregations",
    gcs_files_prefix="MODIS_landcover",
    admin_level=0,
    compilation_folder="intermediate/gee_landcover_compiled",
    id_cols="GID_0",
    landcover_codebook_path="supporting_data/modis_lc_type2.csv",
    output_folder="processed/gee_landcover_processed",
    overwrite=False,
):
    # Compile results when done
    landcover_df = process_grouped_gcs_results(
        local_folderpath=gcs_results_folder,
        gcs_bucketname=gcs_bucketname,
        gcs_files_pattern=rf"^{gcs_files_prefix}_.+_level{admin_level}.csv",
        compilation_pattern=rf"{gcs_files_prefix}_*_level{admin_level}.csv",
        outfile=Path(compilation_folder) / f"{gcs_files_prefix}_{admin_level}.parquet",
        id_cols=f"GID_{admin_level}",
        reducers=["sum"],
        overwrite=overwrite,
    )
    # Add in categories descriptions
    landcover_df["land_cover_category"] = pd.to_numeric(
        landcover_df["land_cover_category"]
    )
    landcover_df = landcover_df.sort_values(
        ["date", f"GID_{admin_level}", "land_cover_category"]
    )
    # Read categories descriptions
    categories_df = pd.read_csv(landcover_codebook_path)
    categories_df = categories_df.rename(columns={"Value": "land_cover_category"})
    categories_df = categories_df[
        ["land_cover_category", "category", "effective_category"]
    ].rename(
        columns={
            "category": "lc_detailed",
            "effective_category": "lc_effective",
        }
    )
    # Merge in categories
    landcover_df = landcover_df.merge(
        categories_df,
        on="land_cover_category",
        how="left",
    ).rename(
        columns={
            "land_cover_category": "lc_category_code",
        }
    )
    landcover_df = landcover_df.rename(columns={"sum": "area"})
    # Export
    landcover_df.to_parquet(
        Path(output_folder) / f"{gcs_files_prefix}_{admin_level}.parquet",
        index=False,
    )
    print(f"Done! - Admin level {admin_level}")


def aggregate_landcover_df(region_lc, lc_type):
    if lc_type == "lc_effective":
        region_lc = (
            region_lc.groupby(["date", "GID_1", lc_type])["area"].sum().reset_index()
        ).sort_values(["GID_1", lc_type, "date"])
    region_lc["frac"] = region_lc.groupby(["date", "GID_1"])["area"].transform(
        lambda x: x / x.sum()
    )
    region_lc["frac_cumsum"] = region_lc.groupby(["date", "GID_1"])["frac"].transform(
        lambda x: x.cumsum()
    )
    region_lc["area_change"] = (
        region_lc["area"]
        / region_lc.groupby(["GID_1", lc_type])["area"].transform("first")
        - 1
    ) * 100
    region_lc["frac_change"] = region_lc["frac"] - region_lc.groupby(
        ["GID_1", lc_type]
    )["frac"].transform("first")
    # Convert date to year
    region_lc = region_lc.sort_values(
        ["date", "GID_1", "area"], ascending=[True, True, False]
    )
    return region_lc
