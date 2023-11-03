# Geometric centroid of each administrative area for levels 1 and 2

#1. Load Packages ----------------------------------------------------------------
library(sf) 

#2. Load Data --------------------------------------------------------------------

# ADM1 shp 
ADM1 <- st_read("../data/raw/GADM/gadm36_1.shp")

# ADM2 shp
ADM2 <- st_read("../data/raw/GADM/gadm36_2.shp")


#3. ADM1  -----------------------------------------------------------------

#3.1 Calculate the geometric centroids of each administrative area using 
# st_point_on_surface()

sf::sf_use_s2(FALSE)
centroids_adm1 <- st_point_on_surface(ADM1)
 
#4. ADM2 -----------------------------------------------------------------
# Repeat process for ADM2 

sf::sf_use_s2(FALSE)

centroids_adm2 <- st_point_on_surface(ADM2)

