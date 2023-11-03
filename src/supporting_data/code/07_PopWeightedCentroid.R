# Population weighted centroids for each administrative area polygon.


#1. Load packages -----------------------------------------------------------
library(data.table)
library(dplyr)
library(spatialEco)
library(raster)
library(rgdal)
library(readxl)
library(sf)
library(sp)
library(plyr)
library(furrr)
library(purrr)
library(parallel)

#2. Load data ---------------------------------------------------------------

VE_ADM3 <- st_read("../data/raw/shapefiles/ven_admbnda_adm0_20180502.shp")

pop_raster <- raster("../data/raw/gpw_v4_population_density_adjusted_to_2015_unwpp_country_totals_rev11_2020_30_sec.tif")

geom_centr_adm1 <- read_excel("../data/raw/ADM1_Atributos.xlsx")

geom_centr_adm2 <- read_excel("../data/raw/ADM2_Atributos.xlsx")

#3. ADM1 --------------------------------------------------------------------

# Dividing W_ADM1 shp by country as a factor 

countries <- levels(as.factor(W_ADM1$NAME_0)) %>% unlist() %>% as.vector()

crs <- st_crs(W_ADM1)
crs(pop_raster) <- crs

wadm1 <- data.frame() 

# Loop to calculate population weighted centroids
for(j in 1:length(countries)){
   
   country <- W_ADM1 %>% 
      filter(NAME_0 == countries[j])
   
   pop_raster_adm1 <- crop(pop_raster, 
                           extent(country))
   
   pop_raster_adm1 <- mask(pop_raster_adm1, 
                           mask = country)
   
   z <- rasterize(country, pop_raster_adm1)
   
   xx <- zonal(init(pop_raster_adm1, v="x")*pop_raster_adm1, z) / zonal(pop_raster_adm1,z)
   yy <- zonal(init(pop_raster_adm1, v="y")*pop_raster_adm1, z) / zonal(pop_raster_adm1,z)
   
   res <- cbind(xx[,2],yy[,2]) %>% 
      as.data.frame()
   
   
   for(i in 1:nrow(res)){
      res$ADM1_PCODE[i] <- country$GID_1[i]
   }
   
   wadm1 <- rbind(wadm1,res)
   
   
}

# Transforming output as numeric and renaming GID_1
wadm1 <- wadm1 %>% 
   transform(V1 = as.numeric(V1), 
             V2 = as.numeric(V2)) %>% 
   na.omit() %>% 
   dplyr::rename("GID_1" = ADM1_PCODE)

# Removing any duplicates (just in case). Generating centroid output 
wadm1 <- wadm1[!duplicated(wadm1[,c('GID_1')]),]

# Verify polygons without centroids 

c_adm1 <- W_ADM1$GID_1

c_wadm1 <- wadm1$GID_1

no_centroid_adm1 <- setdiff(c_adm1, c_wadm1) %>% as.data.frame()

colnames(no_centroid_adm1) <- "GID_1"

no_c_adm1 <- inner_join(no_centroid_adm1, W_ADM1, by = "GID_1") 

# Generating complete dataset of ADM1 level and binary variable to identify 
# whether a centroid is a population weighted centroid (1) or geometric (0)

wadm1_comp <- rbind.fill(wadm1, no_centroid_adm1)

for(i in 1:nrow(wadm1_comp)){
   wadm1_comp$pop_centr[[i]] <- dplyr::if_else(is.na(wadm1_comp$V1[i]), 0, 1)
}

non_comp <- wadm1_comp %>% 
   filter(pop_centr == 0)

non_comp <- left_join(non_comp, geom_centr_adm1) %>% 
   select(long_centroide, lat_centroide, GID_1, pop_centr) %>% 
   dplyr::rename("V1" = long_centroide , 
                 "V2" = lat_centroide)

# Final output ADM1
wadm1_comp <- rbind.fill(wadm1_comp, non_comp) %>% 
   na.omit() %>% 
   dplyr::rename("lon_popcentr" = V1 , 
                 "lat_popcentr" = V2)


#4. ADM2 --------------------------------------------------------------------
# Dividing W_ADM2 shp by country as a factor 

countries_2 <- levels(as.factor(W_ADM2$NAME_0)) %>% unlist() %>% as.vector()

crs_adm2 <- st_crs(W_ADM2) 
crs(pop_raster) <- crs_adm2

wadm2 <- data.frame()

wadm2.b <- data.frame()


plan(multisession, workers = 2) # Using furrr to enable cores to make process faster

# Function that uses same procedure as ADM1 
get_adm2centroid <- function(n) {
   
   
   country <- W_ADM2 %>% 
      filter(NAME_0 == countries_2[156])
   
   pop_raster_adm2 <- crop(pop_raster, 
                           extent(country))
   
   pop_raster_adm2 <- mask(pop_raster_adm2, 
                           mask = country)
   
   z <- rasterize(country, pop_raster_adm2) # Me quede aca para countries_2 156
   
   xx <- zonal(init(pop_raster_adm2, v="x")*pop_raster_adm2, z) / zonal(pop_raster_adm2,z)
   yy <- zonal(init(pop_raster_adm2, v="y")*pop_raster_adm2, z) / zonal(pop_raster_adm2,z)
   
   res <- cbind(xx[,2],yy[,2]) %>% 
      as.data.frame()
   
   for(i in 1:nrow(res)){
      res$GID_2[i] <- country$GID_2[i]
      
   }
   
   wadm2.b <- rbind(wadm2.b,res)
   
}

# Future map to run the function for all the countries in countries_2
wadm2_p <- data.frame() 

plan(multisession, workers = 2)

wadm2_c <- future_map(1:nrow(countries_2), get_adm2centroid, .progress=TRUE, 
                      .options = furrr_options(packages = "sf"))

wadm2_int <- bind_rows(wadm2_c)

wadm2_p <- rbind(wadm2_p, wadm2_int)

wadm2_p <- wadm2_p[!duplicated(wadm2_p[,c('GID_2')]),] %>% 
   na.omit()

# Verify polygons without centroids 
c_adm2 <- W_ADM2$GID_2

c_wadm2 <- wadm2_p$GID_2

no_centroid_adm2 <- setdiff(c_adm2, c_wadm2) %>% as.data.frame() 

colnames(no_centroid_adm2) <- "GID_2"

wadm2_comp <- rbind.fill(wadm2_p, no_centroid_adm2)

# Generating complete dataset of ADM2 level and binary variable to identify 
# whether a centroid is a population weighted centroid (1) or geometric (0)

for(i in 1:nrow(wadm2_comp)){
   wadm2_comp$pop_centr[[i]] <- dplyr::if_else(is.na(wadm2_comp$V1[i]), 0, 1)
}

wadm2_comp <- wadm2_comp %>% 
   transform(pop_centr = as.numeric(pop_centr)) 


non_comp <- wadm2_comp %>% 
   filter(pop_centr == 0) 

non_comp <- left_join(non_comp, geom_centr_adm2) %>% 
   dplyr::select(long_centroide, lat_centroide, GID_2, pop_centr) %>% 
   dplyr::rename("V1" = long_centroide , 
                 "V2" = lat_centroide)

# Final output ADM2

wadm2_comp <- rbind(wadm2_comp, non_comp) %>% 
   na.omit() %>% 
   dplyr::rename("lon_popcentr" = V1 , 
                 "lat_popcentr" = V2)
