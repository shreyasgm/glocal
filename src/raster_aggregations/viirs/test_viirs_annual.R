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
here::i_am("proj/2023-02-05 - Pipeline/viirs_annual.R")
#-------------------------------------------------------------------
admin_level <- 0

# Read GADM
start_time <- Sys.time()
gadm <-
  read_sf(here("data/raw/shapefiles/gadm/gadm36", paste0("gadm36_",admin_level, ".shp")))
Sys.time() - start_time


# Read back file
gadm_id_col <- paste0("GID_", admin_level)
gadm_ids <- gadm %>% pull(gadm_id_col)
raster_agg <- read_parquet(here("data/intermediate/raster_aggregations/viirs/viirs_annual_agg.parquet")) %>%
  # Remove columns ending with "VNL_v21_npp_201204-201303_global_vcmcfg_c202205302300.median_masked.dat"
  dplyr::select(-ends_with("VNL_v21_npp_201204-201303_global_vcmcfg_c202205302300.median_masked.dat"))

# Get filenames and convert to yearmon
agg_filenames <- names(raster_agg)

# Regex to extract yearmon from filename
names(raster_agg) <- gsub(
  pattern = "(.+)\\.VNL_v21_npp_(\\d{4,6}).+",
  replacement = "\\2_\\1",
  perl=TRUE,
  x = agg_filenames
)

# Add GID_0
raster_agg <- raster_agg %>%
  mutate("{gadm_id_col}":=gadm_ids)

# Save
write_parquet(raster_agg, here("data/intermediate/raster_aggregations/viirs/viirs_annual_agg_cleaned.parquet"))
