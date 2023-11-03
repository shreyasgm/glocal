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
here::i_am("proj/2023-02-05 - Pipeline/dmsp/process_dmsp.R")
#-------------------------------------------------------------------
# Import functions
source(here("proj/2023-02-05 - Pipeline/zonal_stats_raster.R"))
#---------------

# Run
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/dmsp/cloud_free_coverage/"),
  pattern = ".global.cf_cvg.tif$",
  output_dir = here("data/intermediate/raster_aggregations/dmsp/"),
  outfile_prefix = "dmsp_cloud_free_coverage",
  categorical = FALSE,
  aggfuncs = c("mean", "sum"),
  max_cells_in_memory = 15e+07
)

zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/dmsp/stable_lights/"),
  pattern = ".global.intercal.stable_lights.avg_vis.tif$",
  output_dir = here("data/intermediate/raster_aggregations/dmsp/"),
  outfile_prefix = "dmsp_stable_lights",
  raster_extent = c(-180, 180,-65, 75),
  categorical = FALSE,
  aggfuncs = c("mean"),
  max_cells_in_memory = 15e+07
)

