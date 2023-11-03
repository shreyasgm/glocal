# Load packages
packages <-
  c("tidyverse",
    "arrow",
    "exactextractr",
    "sf",
    "terra",
    "raster",
    "here")
sapply(packages, library, character.only = T)

# Set working directory appropriately
setwd("/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas")
here::i_am("proj/2023-02-05 - Pipeline/telecom_mobile_coverage/process_telecom_mobile_coverage.R")
#-------------------------------------------------------------------
# Import functions
source(here("proj/2023-02-05 - Pipeline/zonal_stats_raster.R"))
#---------------

# Run MCE (operator submitted data)
# 2G
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/telecom_mobile_coverage/mce_compiled/"),
  pattern = "^MCE.*2G.*\\.tif$",
  output_dir = here("data/intermediate/raster_aggregations/telecom_mobile_coverage/"),
  outfile_prefix = "telecom_mobile_coverage_mce_2g",
  categorical = FALSE,
  aggfuncs = c("mean", "sum"),
  max_cells_in_memory = 15e+07
)

# 3G
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/telecom_mobile_coverage/mce_compiled/"),
  pattern = "^MCE.*3G.*\\.tif$",
  output_dir = here("data/intermediate/raster_aggregations/telecom_mobile_coverage/"),
  outfile_prefix = "telecom_mobile_coverage_mce_3g",
  categorical = FALSE,
  aggfuncs = c("mean", "sum"),
  max_cells_in_memory = 15e+07
)

# 4G
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/telecom_mobile_coverage/mce_compiled/"),
  pattern = "^MCE.*4G.*\\.tif$",
  output_dir = here("data/intermediate/raster_aggregations/telecom_mobile_coverage/"),
  outfile_prefix = "telecom_mobile_coverage_mce_4g",
  categorical = FALSE,
  aggfuncs = c("mean", "sum"),
  max_cells_in_memory = 15e+07
)

# 5G
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/telecom_mobile_coverage/mce_compiled/"),
  pattern = "^MCE.*5G.*\\.tif$",
  output_dir = here("data/intermediate/raster_aggregations/telecom_mobile_coverage/"),
  outfile_prefix = "telecom_mobile_coverage_mce_5g",
  categorical = FALSE,
  aggfuncs = c("mean", "sum"),
  max_cells_in_memory = 15e+07
)

#---------------

# Run OCI (OpenCellID tower locations)
# 2G
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/telecom_mobile_coverage/oci_compiled/"),
  pattern = "^OCI.*2G.*\\.tif$",
  output_dir = here("data/intermediate/raster_aggregations/telecom_mobile_coverage/"),
  outfile_prefix = "telecom_mobile_coverage_oci_2g",
  categorical = FALSE,
  aggfuncs = c("mean", "sum"),
  max_cells_in_memory = 15e+07
)

# 3G
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/telecom_mobile_coverage/oci_compiled/"),
  pattern = "^OCI.*3G.*\\.tif$",
  output_dir = here("data/intermediate/raster_aggregations/telecom_mobile_coverage/"),
  outfile_prefix = "telecom_mobile_coverage_oci_3g",
  categorical = FALSE,
  aggfuncs = c("mean", "sum"),
  max_cells_in_memory = 15e+07
)

# 4G
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/telecom_mobile_coverage/oci_compiled/"),
  pattern = "^OCI.*4G.*\\.tif$",
  output_dir = here("data/intermediate/raster_aggregations/telecom_mobile_coverage/"),
  outfile_prefix = "telecom_mobile_coverage_oci_4g",
  categorical = FALSE,
  aggfuncs = c("mean", "sum"),
  max_cells_in_memory = 15e+07
)
