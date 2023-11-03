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
here::i_am("proj/2023-02-05 - Pipeline/precipitation/process_precipitation.R")
#-------------------------------------------------------------------
# Import functions
source(here("proj/2023-02-05 - Pipeline/zonal_stats_raster.R"))
#---------------

# GPCP
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/precipitation/gpcp/"),
  pattern = ".nc$",
  output_dir = here("data/intermediate/raster_aggregations/precipitation/"),
  outfile_prefix = "precipitation_gpcp",
  categorical = FALSE,
  aggfuncs = c("mean", "median"),
  max_cells_in_memory = 15e+07
)

# CRU
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/precipitation/cru/"),
  pattern = ".nc$",
  subdataset = "pre",
  output_dir = here("data/intermediate/raster_aggregations/precipitation/"),
  outfile_prefix = "precipitation_cru",
  categorical = FALSE,
  aggfuncs = c("mean", "median"),
  max_cells_in_memory = 15e+07
)

# GPCC
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/precipitation/gpcc/"),
  pattern = ".nc$",
  subdataset = "precip",
  output_dir = here("data/intermediate/raster_aggregations/precipitation/"),
  outfile_prefix = "precipitation_gpcc",
  categorical = FALSE,
  aggfuncs = c("mean", "median"),
  max_cells_in_memory = 15e+07
)
