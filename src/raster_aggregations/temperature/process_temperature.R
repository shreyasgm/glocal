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
here::i_am("proj/2023-02-05 - Pipeline/temperature/process_temperature.R")
#-------------------------------------------------------------------
# Import functions
source(here("proj/2023-02-05 - Pipeline/zonal_stats_raster.R"))
#---------------

# GPCP
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/temperature/"),
  pattern = ".nc$",
  subdataset = "tmp",
  output_dir = here("data/intermediate/raster_aggregations/temperature/"),
  outfile_prefix = "temperature",
  categorical = FALSE,
  aggfuncs = c("mean"),
  max_cells_in_memory = 15e+07
)
