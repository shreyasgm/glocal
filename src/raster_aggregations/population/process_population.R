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
here::i_am("proj/2023-02-05 - Pipeline/population/process_population.R")
#-------------------------------------------------------------------
# Import functions
source(here("proj/2023-02-05 - Pipeline/zonal_stats_raster.R"))
#---------------

# Run
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/population/"),
  pattern = "gpw_v4_population_count_adjusted_to_2015.+tif$",
  output_dir = here("data/intermediate/raster_aggregations/population/"),
  outfile_prefix = "population_count",
  categorical = FALSE,
  aggfuncs = c("mean", "min", "max", "count", "sum", "median"),
  max_cells_in_memory = 15e+07
)

# Run
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/population/"),
  pattern = "gpw_v4_population_density_adjusted_to_2015.+tif$",
  output_dir = here("data/intermediate/raster_aggregations/population/"),
  outfile_prefix = "population_density",
  categorical = FALSE,
  aggfuncs = c("mean", "min", "max", "count", "sum", "median"),
  max_cells_in_memory = 15e+07
)
