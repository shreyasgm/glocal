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
here::i_am("proj/2023-02-05 - Pipeline/emissions/process_emissions.R")
#-------------------------------------------------------------------
# Import functions
source(here("proj/2023-02-05 - Pipeline/zonal_stats_raster.R"))
#---------------

# SEDAC
zonal_stats_raster_all_admin_levels(
  folder_path = here("data/raw/rasters/emissions/sedac_pm25/"),
  pattern = ".tif$",
  output_dir = here("data/intermediate/raster_aggregations/emissions/"),
  outfile_prefix = "emissions_pm25",
  categorical = FALSE,
  aggfuncs = c("mean", "median"),
  max_cells_in_memory = 15e+07
)


# # Types of pollutants - CH4  CO  CO2_excluded  CO2_short_cycle  N2O  NO2  NOx  PM10  PM25  SO2

# # CH4
# zonal_stats_raster_all_admin_levels(
#   folder_path = here("data/raw/rasters/emissions/CH4/"),
#   pattern = ".nc$",
#   output_dir = here("data/intermediate/raster_aggregations/emissions/"),
#   outfile_prefix = "emissions_ch4",
#   categorical = FALSE,
#   aggfuncs = c("mean", "median"),
#   max_cells_in_memory = 15e+07
# )

# # CO
# zonal_stats_raster_all_admin_levels(
#   folder_path = here("data/raw/rasters/emissions/CO/"),
#   pattern = ".nc$",
#   output_dir = here("data/intermediate/raster_aggregations/emissions/"),
#   outfile_prefix = "emissions_co",
#   categorical = FALSE,
#   aggfuncs = c("mean", "median"),
#   max_cells_in_memory = 15e+07
# )

# # CO2_excluded
# zonal_stats_raster_all_admin_levels(
#   folder_path = here("data/raw/rasters/emissions/CO2_excluded/"),
#   pattern = ".nc$",
#   output_dir = here("data/intermediate/raster_aggregations/emissions/"),
#   outfile_prefix = "emissions_co2_excluded",
#   categorical = FALSE,
#   aggfuncs = c("mean", "median"),
#   max_cells_in_memory = 15e+07
# )

# # CO2_short_cycle
# zonal_stats_raster_all_admin_levels(
#   folder_path = here("data/raw/rasters/emissions/CO2_short_cycle/"),
#   pattern = ".nc$",
#   output_dir = here("data/intermediate/raster_aggregations/emissions/"),
#   outfile_prefix = "emissions_co2_short_cycle",
#   categorical = FALSE,
#   aggfuncs = c("mean", "median"),
#   max_cells_in_memory = 15e+07
# )

# # N2O
# zonal_stats_raster_all_admin_levels(
#   folder_path = here("data/raw/rasters/emissions/N2O/"),
#   pattern = ".nc$",
#   output_dir = here("data/intermediate/raster_aggregations/emissions/"),
#   outfile_prefix = "emissions_n2o",
#   categorical = FALSE,
#   aggfuncs = c("mean", "median"),
#   max_cells_in_memory = 15e+07
# )

# # NO2
# zonal_stats_raster_all_admin_levels(
#   folder_path = here("data/raw/rasters/emissions/NO2/"),
#   pattern = ".nc$",
#   output_dir = here("data/intermediate/raster_aggregations/emissions/"),
#   outfile_prefix = "emissions_no2",
#   categorical = FALSE,
#   aggfuncs = c("mean", "median"),
#   max_cells_in_memory = 15e+07
# )

# # NOx
# zonal_stats_raster_all_admin_levels(
#   folder_path = here("data/raw/rasters/emissions/NOx/"),
#   pattern = ".nc$",
#   output_dir = here("data/intermediate/raster_aggregations/emissions/"),
#   outfile_prefix = "emissions_nox",
#   categorical = FALSE,
#   aggfuncs = c("mean", "median"),
#   max_cells_in_memory = 15e+07
# )

# # PM10
# zonal_stats_raster_all_admin_levels(
#   folder_path = here("data/raw/rasters/emissions/PM10/"),
#   pattern = ".nc$",
#   output_dir = here("data/intermediate/raster_aggregations/emissions/"),
#   outfile_prefix = "emissions_pm10",
#   categorical = FALSE,
#   aggfuncs = c("mean", "median"),
#   max_cells_in_memory = 15e+07
# )

# # PM25
# zonal_stats_raster_all_admin_levels(
#   folder_path = here("data/raw/rasters/emissions/PM25/"),
#   pattern = ".nc$",
#   output_dir = here("data/intermediate/raster_aggregations/emissions/"),
#   outfile_prefix = "emissions_pm25",
#   categorical = FALSE,
#   aggfuncs = c("mean", "median"),
#   max_cells_in_memory = 15e+07
# )

# # SO2
# zonal_stats_raster_all_admin_levels(
#   folder_path = here("data/raw/rasters/emissions/SO2/"),
#   pattern = ".nc$",
#   output_dir = here("data/intermediate/raster_aggregations/emissions/"),
#   outfile_prefix = "emissions_so2",
#   categorical = FALSE,
#   aggfuncs = c("mean", "median"),
#   max_cells_in_memory = 15e+07
# )
