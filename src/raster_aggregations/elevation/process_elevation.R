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
here::i_am("proj/2023-02-05 - Pipeline/elevation/process_elevation.R")
#-------------------------------------------------------------------
# Import functions
source(here("proj/2023-02-05 - Pipeline/zonal_stats_raster.R"))
#---------------

# Run
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/elevation/"),
  pattern = "0.tif$",
  output_dir = here("data/intermediate/raster_aggregations/elevation/"),
  outfile_prefix = "elevation",
  mosaic_files = TRUE,
  categorical = FALSE,
  aggfuncs = c("mean", "min", "max", "count", "sum", "median"),
  max_cells_in_memory = 15e+07,
  overwrite = TRUE,
  maxrasters = 0
)
