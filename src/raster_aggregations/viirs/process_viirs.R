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
here::i_am("proj/2023-02-05 - Pipeline/viirs/process_viirs.R")
#-------------------------------------------------------------------
# Import functions
source(here("proj/2023-02-05 - Pipeline/zonal_stats_raster.R"))
#---------------

# GPCP
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/viirs/vnl_v2.1/"),
  pattern = ".tif$",
  output_dir = here("data/intermediate/raster_aggregations/viirs/"),
  outfile_prefix = "viirs",
  categorical = FALSE,
  aggfuncs = c("mean", "min", "max", "count", "sum", "median"),
  max_cells_in_memory = 15e+07
)
