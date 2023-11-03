"""
Utilities for working with geospatial analysis in Python

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

# Spatial
import geojson
import geopandas as gpd
import fiona
import contextily as ctx
import rasterio as rio
import rasterio.mask
from rasterio.plot import show as rioshow
import rioxarray


def resample_raster(
    raster_inpath,
    raster_outpath,
    upscale_factor=10,
    resampling_method=rio.enums.Resampling.nearest,
):
    """
    Resample raster to a given resolution.

    Args:
        raster_inpath (str): Path to raster to resample.
        raster_outpath (str): Path to output raster.
        upscale_factor (float): Upscale factor. Fractions for downscaling.

    """
    import rasterio as rio
    
    with rio.open(raster_inpath) as src:
        # resample data to target shape
        height = int(src.height * upscale_factor)
        width = int(src.width * upscale_factor)
        data = src.read(
            out_shape=(
                src.count,
                height,
                width,
            ),
            resampling=resampling_method,
        )

        # scale image transform
        transform = src.transform * src.transform.scale(
            (src.width / data.shape[-1]), (src.height / data.shape[-2])
        )

        # Export to new raster
        kwargs = src.meta.copy()
        kwargs.update({"transform": transform, "width": width, "height": height})

        with rio.open(raster_outpath, "w", **kwargs) as dst:
            dst.write(data)



def polygonize_raster(rasterpath, bandnum=1):
    """Polygonize given raster"""
    import rasterio as rio
    import geopandas as gpd
    from rasterio.features import shapes

    mask = None
    with rio.Env():
        with rio.open(rasterpath) as src:
            image = src.read(bandnum)  # first band
            results = (
                {"properties": {"raster_val": v}, "geometry": s}
                for i, (s, v) in enumerate(
                    shapes(image, mask=mask, transform=src.transform)
                )
            )
    geoms = list(results)
    gpd_polygonized_raster  = gpd.GeoDataFrame.from_features(geoms)
    return gpd_polygonized_raster
    

def crop_raster_to_gdf(raster_inpath, gdf, raster_outpath):
    """
    Crop raster to geodataframe

    Args:
        raster_inpath: Raster filepath, CRS is EPSG:4326
        gdf: any CRS, geodataframe
        raster_outpath: Cropped raster output filepath
    """
    # Get list of shapes
    shapes = [x for x in gdf.to_crs(4326).geometry]

    # Read raster, mask
    with rio.open(raster_inpath) as src:
        out_image, out_transform = rasterio.mask.mask(src, shapes, crop=True)
        out_meta = src.meta

    # Set output metadata and write
    out_meta.update(
        {
            "driver": "GTiff",
            "height": out_image.shape[1],
            "width": out_image.shape[2],
            "transform": out_transform,
        }
    )

    with rio.open(raster_outpath, "w", **out_meta) as dest:
        dest.write(out_image)


def convert_to_geodf(
    df, longitude_col, latitude_col, drop_coords=False, crs="epsg:4326"
):
    # Convert dataframe of coordinates to a geodataframe (geopandas), provided latitude and longitude variables
    import geopandas as gpd
    import shapely
    from shapely.geometry import Point

    shapely.speedups.enable()
    df = df.copy()
    df["coordinates"] = list(zip(df[longitude_col], df[latitude_col]))
    if drop_coords:
        df = df.drop([latitude_col, longitude_col], axis=1)
    df["coordinates"] = df["coordinates"].apply(Point)
    geodf = gpd.GeoDataFrame(df, crs=crs, geometry="coordinates")
    return geodf
