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
here::i_am("proj/2023-02-05 - Pipeline/ntl_dmsp_ext/process_ntl_dmsp_ext.R")
#-------------------------------------------------------------------
# Import functions
source(here("proj/2023-02-05 - Pipeline/zonal_stats_raster.R"))
#---------------

# GPCP
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/ntl_dmsp_ext/"),
  pattern = ".tif$",
  output_dir = here("data/intermediate/raster_aggregations/ntl_dmsp_ext/"),
  outfile_prefix = "ntl_dmsp_ext",
  categorical = FALSE,
  aggfuncs = c("mean", "min", "max", "count", "sum", "median"),
  max_cells_in_memory = 15e+07
)
