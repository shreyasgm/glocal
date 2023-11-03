zonal_stats_raster <-
  function(folder_path,
           pattern,
           admin_level,
           output_path,
           subdataset = 0,
           mosaic_files = FALSE,
           categorical = FALSE,
           raster_extent = NULL,
           aggfuncs = c("mean", "min", "max", "count", "sum", "median"),
           max_cells_in_memory = 3e+07,
           overwrite = FALSE,
           maxrasters = 0) {
    #' Get zonal statistics for raster files in a folder
    #'
    #' @param folder_path Path to folder containing rasters
    #' @param pattern Pattern to match files in folder
    #' @param admin_level GADM admin level to use
    #' @param output_path Path to output file
    #' @param subdataset Character or integer indicating the subdataset to use if raster is netcdf
    #' @param mosaic_files Whether to mosaic files before getting zonal statistics
    #' @param categorical Whether the raster is categorical or continuous
    #' @param raster_extent Extent of raster to use
    #' @param aggfuncs List of aggregation functions to apply
    #' @param max_cells_in_memory Maximum number of cells to keep in memory
    #' @param overwrite Whether to overwrite output file if it exists
    #' @param maxrasters Maximum number of rasters to process, used for debugging mostly
    #' @return Nothing, writes to file
    #' @export
    #' @examples
    #' zonal_stats_raster(
    #'  folder_path = here("data/raw/rasters/viirs/vnl_v2.1/"),
    #'  pattern = ".median_masked.dat.tif$",
    #'  admin_level = 0,
    #'  output_path = here("data/intermediate/raster_aggregations/viirs/viirs_annual_agg.parquet"),
    #'  categorical = FALSE
    #' )
    
    # If categorical is TRUE, error out
    if (categorical) {
      stop("Categorical rasters not supported yet")
    }
    
    # If overwrite is FALSE, Check if output file exists
    # If it does, exit function
    if (!overwrite) {
      if (file.exists(output_path)) {
        message(paste0("Output file ",
                       output_path,
                       " already exists. Skipping."))
        return()
      }
    }
    
    # Read GADM
    gadm <-
      read_sf(here(
        "data/raw/shapefiles/gadm/gadm36",
        paste0("gadm36_", admin_level, ".shp")
      ))
    gid_colname <- paste0("GID_", admin_level)
    gid_values <- pull(gadm, gid_colname)
    
    
    # Read raster using terra
    # Get list of files in folder that ends with ".median_masked.dat.tif.gz"
    filenames <-
      list.files(folder_path, pattern = pattern)
    filepaths <- paste0(folder_path, filenames)
    # If maxrasters is not 0, only use the first maxrasters files and warn user
    if (maxrasters > 0) {
      filepaths <- filepaths[1:maxrasters]
      message(
        paste0(
          "Only using the first ",
          maxrasters,
          " files. To use all files, set maxrasters to 0."
        )
      )
    }
    # Function to get filetype, used to detect netcdf files
    # Get file type
    get_file_type <- function(file_path) {
      file_ext <- strsplit(file_path, split = "\\.")[[1]][-1]
      file_ext <- file_ext[length(file_ext)]
      return(file_ext)
    }
    
    # Try creating SpatRaster from files and get zonal statistics
    # If error, get zonal statistics from each file separately and concatenate
    # Start timing
    start_time <- Sys.time()
    raster_agg <- tryCatch({
      #-------------
      # If mosaic_files is TRUE, mosaic files before getting zonal statistics
      if (mosaic_files) {
        # Create a SpatRasterCollection with all files in filepaths
        # Check if file mosaic.tif exists in folder_path, otherwise create it
        if (!file.exists(here(folder_path, "mosaic.tif"))) {
          message("Mosaicking files")
          raster_collection <- terra::vrt(filepaths)
          # Get foldername
          terra::writeRaster(
            raster_collection,
            here(folder_path, "mosaic.tif"),
            names = basename(folder_path),
            overwrite = FALSE
          )
        } else {
          message("Mosaic file already exists, reading")
        }
        raster <-
          terra::rast(here(folder_path, "mosaic.tif"))
      } else {
        # If files are netcdf, then set names of the files as the time
        if (get_file_type(filepaths[1]) == "nc") {
          # If there are more than one variables, then make sure subdataset is not 0
          numvars_nc <- ncdf4::nc_open(filepaths[1])$nvars
          if (subdataset == 0 & numvars_nc > 1) {
            # Print names of variables
            varnames_nc <- names(ncdf4::nc_open(filepaths[1])$var)
            message("There are more than one variables in the netcdf file")
            message("Please specify the subdataset to use")
            message("The variables are:")
            message(varnames_nc)
            stop("Exiting.")
          }
          raster <- terra::rast(filepaths, subds = subdataset)
          names(raster) <- time(raster)
        } else {
          # # Check if the extent of all the files are the same
          # # If not, make each of them have the same extent as specified extent by cropping
          # # If extent is not specified, then use the extent of the first file
          # get_raster_extent <- function(filepath) {
          #   raster_i <- terra::rast(filepath)
          #   raster_extent_i <- terra::ext(raster_i)
          #   return(raster_extent_i)
          # }
          # if (is.null(raster_extent)) {
          #   raster_extent <- get_raster_extent(filepaths[1])
          # } else {
          #   raster_extent <- terra::ext(raster_extent)
          # }
          # # Check if all files have the same extent
          # all_raster_extents <- lapply(filepaths, get_raster_extent)
          # raster_extents_match <- sapply(all_raster_extents, function(x) {
          #   x==raster_extent
          # })
          # if (!all(raster_extents_match)) {
          #   # If not, crop each file to the specified extent
          #   message("Files do not all have the same extent")
          #   message("Cropping files to the specified extent")
          #   crop_raster <- function(filepath) {
          #     print(filepath)
          #     raster_i <- terra::rast(filepath)
          #     raster_i <- terra::crop(raster_i, raster_extent)
          #     return(raster_i)
          #   }
          #   raster <- lapply(filepaths, crop_raster)
          #   raster <- terra::rast(raster)
          # } else {
          # If all files have the same extent, then read them as a SpatRasterCollection
          raster <- terra::rast(filepaths)
          # }
        }
      }
      #-------------
      # Get zonal statistics
      raster_agg <-
        exactextractr::exact_extract(
          x = raster,
          y = gadm,
          fun = aggfuncs,
          progress = TRUE,
          force_df = TRUE,
          full_colnames = TRUE,
          max_cells_in_memory = max_cells_in_memory
        ) %>%
        # Add appropriate GID column based on admin_level
        mutate(gid = gid_values)
    }, error = function(e) {
      # If mosaic_files is TRUE, error out while printing error message
      if (mosaic_files) {
        message("Error occurred while mosaicking files and getting zonal stats")
        message("Error message:")
        message(e)
        stop("Exiting")
      }
      # Print error message
      message(
        "Error occurred, getting zonal statistics from each file separately and concatenating"
      )
      message("Error message:")
      message(e)
      # Get zonal statistics from each file separately and concatenate
      for (i in 1:length(filepaths)) {
        # If files are netcdf, then set names of the files as the time
        if (get_file_type(filepaths[i]) == "nc") {
          raster <- terra::rast(filepaths, subds = subdataset)
          names(raster) <- time(raster)
        } else {
          raster <- terra::rast(filepaths[i])
        }
        raster_agg_i <-
          exactextractr::exact_extract(
            x = raster,
            y = gadm,
            fun = aggfuncs,
            progress = TRUE,
            force_df = TRUE,
            full_colnames = TRUE,
            max_cells_in_memory = max_cells_in_memory
          ) %>%
          mutate(gid = gid_values)
        print(paste0("raster_agg_i: ", i))
        print(head(raster_agg_i))

        if (i == 1) {
          raster_agg <- raster_agg_i
        } else {
          raster_agg <- cbind(raster_agg, raster_agg_i)
        }
      }
      return(raster_agg)
    })
    # Print time taken as "Function run took x minutes"
    end_time <- Sys.time()
    time_taken <- end_time - start_time
    message(paste0("Time taken: ", round(time_taken / 60, 2), " minutes"))
    
    
    # Write to parquet file
    arrow::write_parquet(raster_agg, output_path)
  }

#------------------------------------------------------------------------
zonal_stats_raster_all_admin_levels <- function(output_dir,
                                                outfile_prefix,
                                                ...) {
  #' @param output_dir Directory for output file
  #' @param outfile_prefix Prefix for output file
  #' @param ... Additional arguments to pass to zonal_stats_raster
  #' @return Nothing, writes to file
  #' @export
  #' @examples
  #' zonal_stats_raster_all_admin_levels(
  #'  folder_path = here("data/raw/rasters/viirs/vnl_v2.1/"),
  #'  pattern = ".median_masked.dat.tif$",
  #'  output_path = here("data/intermediate/raster_aggregations/viirs/viirs_annual_agg.parquet"),
  #'  categorical = FALSE
  #' )
  
  # If output_dir does not exist, create it
  if (!dir.exists(output_dir)) {
    dir.create(output_dir)
  }
  
  # Run zonal_stats_raster for each admin level
  for (admin_level in 0:2) {
    # Get output path for this admin level
    output_path_i <-
      paste0(output_dir,
             outfile_prefix,
             "_level_",
             admin_level,
             ".parquet")
    # Run zonal_stats_raster
    zonal_stats_raster(output_path = output_path_i,
                       admin_level = admin_level,
                       
                       ...)
  }
}