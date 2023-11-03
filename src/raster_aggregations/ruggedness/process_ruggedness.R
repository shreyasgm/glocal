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
here::i_am("proj/2023-02-05 - Pipeline/ruggedness/process_ruggedness.R")
#-------------------------------------------------------------------
# Import functions
source(here("proj/2023-02-05 - Pipeline/zonal_stats_raster.R"))
#---------------

# Read ruggedness
tri <- terra::rast(here("data/raw/rasters/ruggedness/tri.txt"))
cellarea <- terra::rast(here("data/raw/rasters/ruggedness/cellarea.txt"))


# Run for admin_level 0, 1 and 2
admin_levels <- c(0, 1, 2)

# Loop through admin levels
for (admin_level in admin_levels) {
  # Read GADM values
  gadm <-
    read_sf(here(
      "data/raw/shapefiles/gadm/gadm36",
      paste0("gadm36_", admin_level, ".shp")
    ))
  gid_colname <- paste0("GID_", admin_level)
  gid_values <- pull(gadm, gid_colname)

  # Calculate ruggedness
  # Get zonal statistics
  raster_agg <-
    exactextractr::exact_extract(
      x = tri,
      y = gadm,
      weights = cellarea,
      fun = c("weighted_mean"),
      progress = TRUE,
      force_df = TRUE,
      full_colnames = TRUE,
      max_cells_in_memory = 15e+07
    ) %>%
    # Add appropriate GID column based on admin_level
    mutate(gid = gid_values)

  output_dir <- here("data/intermediate/raster_aggregations/ruggedness/")
  outfile_prefix <- "ruggedness"

  # Get output path for this admin level
  output_path_i <-
    paste0(output_dir,
           outfile_prefix,
           "_level_",
           admin_level,
           ".parquet")

  # Write to parquet file
  arrow::write_parquet(raster_agg, output_path_i)
}

