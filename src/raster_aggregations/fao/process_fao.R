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
here::i_am("proj/2023-02-05 - Pipeline/fao/process_fao.R")
#-------------------------------------------------------------------
# Import functions
source(here("proj/2023-02-05 - Pipeline/zonal_stats_raster.R"))
#---------------

# Run
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/fao/all_stats/"),
  pattern = "all_.+_yld.tif$",
  output_dir = here("data/intermediate/raster_aggregations/fao/"),
  outfile_prefix = "fao_yield",
  categorical = FALSE,
  aggfuncs = c("mean", "sum"),
  max_cells_in_memory = 15e+07
)

# Run
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/fao/all_stats/"),
  pattern = "all_.+_val.tif$",
  output_dir = here("data/intermediate/raster_aggregations/fao/"),
  outfile_prefix = "fao_value",
  categorical = FALSE,
  aggfuncs = c("mean", "sum"),
  max_cells_in_memory = 15e+07
)
