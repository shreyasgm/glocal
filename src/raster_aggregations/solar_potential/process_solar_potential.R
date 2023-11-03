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
here::i_am("proj/2023-02-05 - Pipeline/solar_potential/process_solar_potential.R")
#-------------------------------------------------------------------
# Import functions
source(here("proj/2023-02-05 - Pipeline/zonal_stats_raster.R"))
#---------------

# Solar potential
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/solar_potential/"),
  pattern = ".tif$",
  output_dir = here("data/intermediate/raster_aggregations/solar_potential/"),
  outfile_prefix = "solar_potential",
  categorical = FALSE,
  aggfuncs = c("mean", "sum"),
  max_cells_in_memory = 15e+07
)
