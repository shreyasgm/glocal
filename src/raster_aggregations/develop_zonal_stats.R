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
here::i_am("proj/2023-02-05 - Pipeline/develop_process_raster.R")
#-------------------------------------------------------------------

# Set some parameters
folder_path = here("data/raw/rasters/dmsp/stable_lights/")
pattern = ".global.intercal.stable_lights.avg_vis.tif$"
admin_level = 0
output_path = here("data/intermediate/raster_aggregations/dmsp/dmsp_stable_lights.parquet")
categorical = FALSE
aggfuncs = c("mean", "min", "max", "count", "sum", "median")
max_cells_in_memory = 15e+07



# Read GADM
gadm <-
  read_sf(here(
    "data/raw/shapefiles/gadm/gadm36",
    paste0("gadm36_", admin_level, ".shp")
  ))


# Read raster using terra
# Get list of files in folder that ends with ".median_masked.dat.tif.gz"
filenames <-
  list.files(folder_path, pattern = pattern)
filepaths <- paste0(folder_path, filenames)

# Try creating SpatRaster from files and get zonal statistics
# If error, get zonal statistics from each file separately and concatenate
tryCatch({
  raster <- terra::rast(filepaths)
  raster_agg <-
    exactextractr::exact_extract(
      x = raster,
      y = gadm,
      fun = aggfuncs,
      progress = TRUE,
      force_df = TRUE,
      max_cells_in_memory = max_cells_in_memory
    )
}, error = function(e) {
  raster_agg <- data.frame()
  for (i in 1:length(filepaths)) {
    raster <- terra::rast(filepaths[i])
    raster_agg_i <-
      exactextractr::exact_extract(
        x = raster,
        y = gadm,
        fun = aggfuncs,
        progress = TRUE,
        force_df = TRUE,
        max_cells_in_memory = max_cells_in_memory
      )
    raster_agg <- rbind(raster_agg, raster_agg_i)
  }
})

# Write to parquet file
# arrow::write_parquet(raster_agg, output_path)
