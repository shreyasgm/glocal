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
here::i_am("proj/2023-02-05 - Pipeline/test_process_raster.R")
#-------------------------------------------------------------------
# Import functions
source(here("proj/2023-02-05 - Pipeline/process_raster.R"))
#---------------

# Run
process_raster(
  folder_path = here("data/raw/rasters/viirs/vnl_v2.1/"),
  pattern = ".median_masked.dat.tif$",
  admin_level = 0,
  output_path = here("data/intermediate/raster_aggregations/viirs/viirs_annual_agg.parquet"),
  categorical = FALSE,
  aggfuncs = c("mean", "min", "max", "count", "sum", "median"),
  max_cells_in_memory = 15e+07
)


