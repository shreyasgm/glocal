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
import seaborn as sns

# Geospatial
import geopandas as gpd

# Earth engine API
import ee

try:
    ee.Initialize()
except Exception as e:
    ee.Authenticate()
    ee.Initialize()

from general_utils import *

# Helper functions
def get_country_centroid(iso):
    """Read country boundaries and get a rough centroid"""
    import warnings

    gdf_centroid = gpd.read_file(gpd.datasets.get_path("naturalearth_lowres"))
    gdf_centroid = gdf_centroid[gdf_centroid.iso_a3 == iso]
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        centroid_point = gdf_centroid.centroid.iloc[0]
    return [centroid_point.y, centroid_point.x]


# Process GEE
def load_admin_boundaries(cntry_selected_abbr, selected_admin_level, simplify_tol=100):
    """
    Load admin boundaries. Simplify country boundaries.
    """
    # Load administrative boundaries
    # country_boundaries_ee = ee.Feature(
    #     ee.FeatureCollection("FAO/GAUL/2015/level0")
    #     .filter(ee.Filter.eq("ADM0_NAME", cntry_selected))
    #     .first()
    # ).geometry()
    country_boundaries_ee = (
        ee.FeatureCollection(f"users/shreyasgm/growth_lab/gadm36_0")
        .filter(ee.Filter.eq("GID_0", cntry_selected_abbr))
        .first()
        .geometry()
        .simplify(maxError=simplify_tol)
    )
    admin_boundaries_ee = ee.FeatureCollection(
        f"users/shreyasgm/growth_lab/gadm36_{selected_admin_level}"
    ).filter(ee.Filter.eq("GID_0", cntry_selected_abbr))
    if selected_admin_level == 0:
        admin_boundaries_ee = admin_boundaries_ee.map(
            lambda x: x.simplify(maxError=simplify_tol)
        )
    return country_boundaries_ee, admin_boundaries_ee


def load_world_country_boundaries():
    return ee.FeatureCollection(f"users/shreyasgm/growth_lab/gadm36_0")


def load_city_boundaries(cntry_selected_abbr):
    city_boundaries_ee = ee.FeatureCollection(f"users/shreyasgm/growth_lab/ghs").filter(
        ee.Filter.eq("iso", cntry_selected_abbr)
    )
    return city_boundaries_ee


def get_unique_values(image, region, scale=500):
    reduction = image.reduceRegion(
        ee.Reducer.frequencyHistogram(), region, scale=scale, bestEffort=True
    )

    values = ee.Dictionary(reduction.get(image.bandNames().get(0))).keys()
    return values


def get_country_boundary(cntry_selected_abbr):
    """Get FAO GAUL country boundary if GADM boundary is broken"""
    country_boundaries_ee, admin_boundaries_ee = load_admin_boundaries(
        cntry_selected_abbr, 0
    )
    num_features = admin_boundaries_ee.size().getInfo()
    if num_features == 1:
        return country_boundaries_ee
    elif num_features < 1:
        raise ValueError("Country boundary not found in GADM")
    elif num_features > 1:
        print(
            "GADM Earth Engine feature has more than one element. "
            "Geometry likely too large, switching to FAO GAUL."
        )
    # Convert country code to FAO GAUL
    gaul_codes = pd.read_csv(
        DATA / "raw/country_codes/country-codes.csv",
        usecols=["ISO3166-1-Alpha-3", "GAUL"],
    )
    gaul_codes = country_codes.rename(
        columns={"ISO3166-1-Alpha-3": "iso3", "GAUL": "gaul_code"}
    )
    selected_gaul_code = gaul_codes.loc[
        gaul_codes.iso3 == cntry_selected_abbr, "gaul_code"
    ]
    assert (
        len(selected_gaul_code) == 1
    ), f"Country ISO code {cntry_selected_abbr} not yielding a single GAUL code"
    selected_gaul_code = int(selected_gaul_code)
    # Filter FAO GAUL region
    region = (
        ee.FeatureCollection("FAO/GAUL/2015/level0")
        .filter(ee.Filter.eq("ADM0_CODE", selected_gaul_code))
        .geometry()
    )
    return region


def get_custom_reducer(reducers="all"):
    # Set custom reducer
    reducer_ee_dict = {
        "mean": ee.Reducer.mean(),
        "max": ee.Reducer.max(),
        "min": ee.Reducer.min(),
        "median": ee.Reducer.median(),
        "sum": ee.Reducer.sum(),
        "stdDev": ee.Reducer.stdDev(),
        "count": ee.Reducer.count(),
    }

    # Handle "all" case
    if reducers == "all":
        reducers = list(reducer_ee_dict.keys())

    convert_to_list = lambda a: [a] if isinstance(a, str) else a
    reducers = convert_to_list(reducers)

    # Convert to functions
    reducers = [reducer_ee_dict[x] for x in reducers]

    # Combine into one reducer
    for i, r in enumerate(reducers):
        if i == 0:
            reducer = r
        elif i > 0:
            reducer = reducer.combine(r, sharedInputs=True)
    return reducer


def get_reduced_image(
    img,
    fc_boundaries,
    scaleFactor=None,
    crs=None,
    crsTransform=None,
    set_date=False,
    reducers="all",
):
    """
    Aggregate img to fc_boundaries with custom reducers
    """
    reducers = get_custom_reducer(reducers)
    reduced_img = img.reduceRegions(
        reducer=reducers,
        collection=fc_boundaries,
        scale=scaleFactor,
        crs=crs,
        crsTransform=crsTransform,
    )
    # Set date if necessary
    if set_date:
        img = img.set("system:time_start", ee.Number(set_date.timestamp() * 1000))
    # Add a date to each feature
    img_date = img.date().format()
    reduced_img = reduced_img.map(lambda x: x.set("date", img_date))
    return reduced_img


def get_reduced_image_grouped(
    img_with_bands,
    fc_boundaries,
    grouping_band_index,
    group_name,
    scaleFactor=None,
    crs=None,
    crsTransform=None,
    set_date=False,
    reducers="all",
):
    """
    Reduce given image based on the following custom reducers:
    sum, mean, median, min, max, std dev, count
    """
    reducers = get_custom_reducer(reducers)
    reduced_img = img_with_bands.reduceRegions(
        reducer=reducers.group(groupField=grouping_band_index, groupName=group_name),
        collection=fc_boundaries,
        scale=scaleFactor,
        crs=crs,
        crsTransform=crsTransform,
    )
    # Set date if necessary
    if set_date:
        img = img.set("system:time_start", ee.Number(set_date.timestamp() * 1000))
    # Add a date to each feature
    img_date = img_with_bands.date().format()
    reduced_img = reduced_img.map(lambda x: x.set("date", img_date))
    return reduced_img


# function to get individual img dates
def get_date(img):
    return img.set("date", img.date().format())


def get_reduced_imagecollection(
    imagecollection,
    fc_boundaries,
    scaleFactor=None,
    crs=None,
    crsTransform=None,
    grouped=False,
    grouping_band_index=1,
    group_name="group",
    reducers="all",
):
    # Get imagecollection reduced to featurecollection
    if not grouped:
        fx = lambda x: get_reduced_image(
            x, fc_boundaries, scaleFactor, crs, crsTransform, reducers=reducers
        )
        reduced_fc = imagecollection.map(fx).flatten()
    else:
        fx = lambda x: get_reduced_image_grouped(
            x,
            fc_boundaries,
            grouping_band_index,
            group_name,
            scaleFactor,
            crs,
            crsTransform,
            reducers=reducers,
        )
        reduced_fc = imagecollection.map(fx).flatten()

    return reduced_fc


def extract_reduction_results(
    reduced_fc,
    id_cols,
    additional_stats=[],
    export_to_gcs=False,
    gcs_bucket=None,
    reducers="all",
):
    """
    Extract reduction results into a dataframe

    Args:
        reduced_fc: FeatureCollection to export
        id_cols: ID columns as a list
        additional_stats: additional reducer stats if included in properties
        export_to_gcs: default False. Otherwise, string with CSV filename.
        gcs_bucket: str
        reducers: list of custom reducer names, or "all"

    Returns:
        EE task if export_to_gcs. Otherwise, df with results.
    """
    # Convert data into EE lists
    allowed_stats = [
        "mean",
        "sum",
        "median",
        "stdDev",
        "count",
        "min",
        "max",
    ]
    if reducers == "all":
        reducers = allowed_stats

    # Convert to list if not
    convert_to_list = lambda a: [a] if isinstance(a, str) else a
    reducers = convert_to_list(reducers)

    stats_list = reducers + additional_stats
    id_cols = ["date"] + id_cols
    key_cols = id_cols + stats_list

    if export_to_gcs == False:
        areas_list = reduced_fc.reduceColumns(
            ee.Reducer.toList(len(key_cols)), key_cols
        ).values()
        # Force computation, convert to df
        results_df = pd.DataFrame(
            np.asarray(areas_list.getInfo()).squeeze(), columns=key_cols
        )
        # Convert date data type
        results_df["date"] = pd.to_datetime(results_df["date"])
        # Convert other data types
        for x in reducers:
            results_df[x] = pd.to_numeric(results_df[x])

        return results_df
    else:
        assert isinstance(export_to_gcs, str), "export_to_gcs should be a string"
        # Prepare and start export task
        export_task = ee.batch.Export.table.toCloudStorage(
            collection=reduced_fc,
            description=export_to_gcs,
            bucket=gcs_bucket,
            fileFormat="CSV",
            selectors=key_cols,
        )
        export_task.start()
        return export_task


def extract_reduction_results_grouped(
    reduced_fc, id_cols, reducers="all", export_to_gcs=False, gcs_bucket=None
):
    """
    Extract reduction results for grouped reductions

    Args:
        reduced_fc: FeatureCollection to export
        id_cols: ID columns as a list
        reducers: list of custom reducer names, or "all"
        export_to_gcs: default False. Otherwise, string with CSV filename.
        gcs_bucket: str

    Returns:
        EE task if export_to_gcs. Otherwise, df with results.
    """
    # Convert data into EE lists
    allowed_stats = [
        "mean",
        "sum",
        "median",
        "stdDev",
        "count",
        "min",
        "max",
    ]
    if reducers == "all":
        reducers = allowed_stats

    # Convert to list if not
    convert_to_list = lambda a: [a] if isinstance(a, str) else a
    reducers = convert_to_list(reducers)

    id_cols = ["date"] + id_cols
    key_cols = id_cols + ["groups"]

    if export_to_gcs == False:
        areas_list = reduced_fc.reduceColumns(
            ee.Reducer.toList(len(key_cols)), key_cols
        ).values()
        # Force computation, convert to df
        results_df = pd.DataFrame(
            np.asarray(areas_list.getInfo(), dtype=object).squeeze(), columns=key_cols
        )
        # Explode list of dictionaries
        results_df = results_df.explode("groups")
        # Split dictionary elements
        results_df = pd.concat(
            [results_df[id_cols], results_df["groups"].apply(pd.Series)], axis=1
        )

        # Convert date data type
        results_df["date"] = pd.to_datetime(results_df["date"])

        for x in reducers:
            if x in results_df.columns:
                results_df[x] = pd.to_numeric(results_df[x])
            else:
                import warnings

                warnings.warn(f"Reducer {x} not present in output")
    else:
        assert isinstance(export_to_gcs, str), "export_to_gcs should be a string"
        # Prepare and start export task
        export_task = ee.batch.Export.table.toCloudStorage(
            collection=reduced_fc,
            description=export_to_gcs,
            bucket=gcs_bucket,
            fileFormat="CSV",
            selectors=key_cols,
        )
        export_task.start()
        return export_task
    return results_df


def convert_str_to_list_of_dicts(str_to_convert):
    # Take string of format '[{land_cover_category=1, sum=1.1.5}, {land_cover_category=2, sum=6.5}]'
    # Convert it to a list of dictionaries
    # Remove spaces
    str_to_convert = str_to_convert.replace(" ", "")
    # Remove square brackets
    str_to_convert = str_to_convert.replace("[", "")
    str_to_convert = str_to_convert.replace("]", "")
    # Split by commas between curly brackets
    str_to_convert = str_to_convert.replace("},{", "},\n{")
    # Split by \n
    str_to_convert = str_to_convert.split("\n")
    # For each element of list, remove curly brackets
    str_to_convert = [x.replace("{", "").replace("}", "") for x in str_to_convert]
    # For each element, convert to dict
    output_list = []
    for list_element in str_to_convert:
        list_of_dicts = list_element.split(",")
        # Remove if empty
        list_of_dicts = [x for x in list_of_dicts if x != ""]
        list_element_dict = {}
        for dict_elements in list_of_dicts:
            dict_elements = dict_elements.split("=")
            list_element_dict[dict_elements[0]] = dict_elements[1]
        output_list.append(list_element_dict)

    return output_list


def process_grouped_gcs_results(
    local_folderpath,
    gcs_bucketname,
    gcs_files_pattern,
    compilation_pattern,
    outfile,
    id_cols=["GID_0"],
    reducers="all",
    overwrite=False,
):
    """
    Process gropued gcs results

    If using extract_reduction_results_grouped with GCS, this function can be used to process the resulting csv's.
    """
    # Get stats to be used
    allowed_stats = [
        "mean",
        "sum",
        "median",
        "stdDev",
        "count",
        "min",
        "max",
    ]
    if reducers == "all":
        reducers = allowed_stats

    # Get data from GCS
    # Download all missing files
    downloaded_files = download_missing_gcp(
        local_folderpath=local_folderpath,
        gcs_bucketname=gcs_bucketname,
        pattern=gcs_files_pattern,
        overwrite=overwrite,
    )
    # Compile downloaded files
    compile_downloaded_files(local_folderpath, compilation_pattern, outfile)
    # Read compiled file
    results_df = pd.read_parquet(outfile)
    # If a column called 0 exists, drop
    if 0 in results_df.columns:
        results_df = results_df.drop(columns=0)
    # Read column groups as a list of dictionaries
    results_df["groups"] = results_df["groups"].apply(convert_str_to_list_of_dicts)
    # Explode list of dictionaries
    results_df = results_df.explode("groups")
    # Split dictionary elements
    # Convert to list if not list
    id_cols = [id_cols] if isinstance(id_cols, str) else id_cols
    id_cols = ["date"] + id_cols
    results_df = pd.concat(
        [results_df[id_cols], results_df["groups"].apply(pd.Series)], axis=1
    )
    # Convert date data type
    results_df["date"] = pd.to_datetime(results_df["date"])

    missing_reducers = 0
    for x in reducers:
        if x in results_df.columns:
            results_df[x] = pd.to_numeric(results_df[x])
        else:
            missing_reducers = 1
    if missing_reducers:
        import warnings

        warnings.warn(f"Some reducers not present in output")
    return results_df


def export_ee_img_to_gcs(
    ee_img,
    cntry_selected_abbr,
    outfile,
    gcs_bucketname="earth_engine_images",
    check_if_exists=True,
    **kwargs,
):
    # Check if outfile already exists
    if check_if_exists:
        gcs_bucket = initialize_gcs(gcs_bucketname)
        if check_if_file_exists_gcs(outfile, gcs_bucket):
            return
    # Get country boundaries
    cntry_boundary = get_country_boundary(cntry_selected_abbr)
    # Export
    print(f"Exporting {outfile}")
    ee_task = ee.batch.Export.image.toCloudStorage(
        ee_img,
        description=outfile,
        bucket=gcs_bucketname,
        region=cntry_boundary,
        **kwargs,
    )
    ee_task.start()
