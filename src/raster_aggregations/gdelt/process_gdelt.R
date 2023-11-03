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
here::i_am("proj/2023-02-05 - Pipeline/gdelt/process_gdelt.R")
#-------------------------------------------------------------------
# Import functions
source(here("proj/2023-02-05 - Pipeline/zonal_stats_raster.R"))
#---------------

# # Run
# zonal_stats_raster_all_admin_levels(
#   folder_path = here("data/raw/rasters/gdelt/"),
#   pattern = "gpw-v4-gdelt-count-adjusted",
#   output_dir = here("data/intermediate/raster_aggregations/gdelt/"),
#   outfile_prefix="gdelt_count",
#   categorical = FALSE,
#   aggfuncs = c("mean", "min", "max", "count", "sum", "median"),
#   max_cells_in_memory = 15e+07
# )

# Read CSV's
csv_dir <- here("data/raw/rasters/gdelt_v2")
csv_filename <- "20150218230000.export.CSV.zip"
gdelt <- read_csv(paste0(csv_dir, "/", csv_filename))