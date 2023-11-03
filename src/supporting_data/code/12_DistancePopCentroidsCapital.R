# Packages  ---------------------------------------------------------------

library(tidyverse)
library(dplyr)
library(sf)
library(tmap)
library(readr)
library(readxl)
library(lubridate)
library(sf)
library(rio)
library(openxlsx)
library(sfheaders)
library(units)
library(matrixStats)
library(nngeo)
library(janitor)
library(googleway)
library(rlist)

# Load Data -------------------------------------------------------------------

# ADM1 
ADM1 <- st_read("../../../02_adminAreas/data/raw/GADM/gadm36_1.shp")

# ADM2

ADM2 <- st_read("../../../02_adminAreas/data/raw/GADM/gadm36_2.shp")

# Capitals
capitals <-  read.csv("../../../02_adminAreas/data/raw/GADM/countries_capitals_ggmp.csv")%>%  
   
   mutate(longitude = as.numeric(longitude),
          
          latitude = as.numeric(latitude)) %>% 
   
   na.omit()

# River and lakes 

rivers_lakes<-st_read("../../../02_adminAreas/data/raw/rivers_lakes/ne_10m_rivers_lake_centerlines_scale_rank.shp")

# Costas
coasts <- st_read("../../../02_adminAreas/data/raw/coastline/ne_10m_coastline.shp")

# ADM1: Capitals and distance to pop_centroids  --------------------------------------------------------------------

#1.2) Assign the coordinate reference system from the ADM shape file to the capitals file.

CRS_adm1  <- st_crs(ADM1)

#1.3) Rewrite the capitals csv as an sf file.

capitales_spatialADM1 <- st_as_sf(capitals, 
                                  
                                  coords = c("longitude", "latitude"), 
                                  
                                  crs = CRS_adm1)


#2.2) Extract the names of each country in the centroids' file and the capitals' file
wadm1_comp <- read_excel("../../data/clean/Pop_Centroids_GID1.xlsx")

wadm1_t <- wadm1_comp %>% 
   left_join(ADM1)

f <- wadm1_t %>% mutate(NAME_0= as.factor(NAME_0))

d<- capitales_spatialADM1 %>% mutate(CountryName=as.factor(CountryName))

t_p<- c(levels(f$NAME_0[duplicated(f$NAME_0)]))

t_d<- c(levels(d$CountryName[duplicated(d$CountryName)]))


wadm1_t <- st_as_sf(wadm1_t, 
                    
                    coords = c("lon", "lat"), 
                    
                    crs = CRS_adm1)

#2.3) Create a function that calculates the distance between capital and centroids 

funcion_dist_adm1<-  function(x,y) {
   
   c_by <- wadm1_t%>% filter(NAME_0==x) 
   ca_by<- capitales_spatialADM1 %>% filter(CountryName==y)
   
   nearest_capital <- st_nearest_feature(c_by, ca_by)
   dist <- st_distance(c_by,ca_by[nearest_capital,], by_element=TRUE) 
   
   pljoin <- cbind(c_by, st_drop_geometry(ca_by)[nearest_capital,])
   
   pljoin$dist <- (dist/1000) %>%
      drop_units()
   
   cap <- pljoin %>%  select(GID_1,dist,CapitalName) %>% 
      clean_names() %>% st_sf() %>% 
      rename('dist_km' = dist) %>% 
      st_drop_geometry()
   
   assign(x,cap,envir = .GlobalEnv)
   
}

#2.5) Run a Loop that calculates the distance for the rest of the countries

final_adm1 <- data.frame()
h <- data.frame()

for (i in t_p){
   
   for(j in t_d){
      
      if (i == j)
         
         h <- funcion_dist_adm1(i,j)
      
      final_adm1 <- rbind(final_adm1,h) %>% distinct()
   }
}



#2.6) Clean de data outcome

names(final_adm1) <- c('GID_1', 'dist_km_popcentr' , 'capital_name')

dist_popcentr_1 <- final_adm1


# ADM2: Capitals and distance to pop_centroids --------------------------------

centroids_adm2 <- left_join(centroids_adm2, ADM2) 

st_crs(centroids_adm2) <- CRS_adm2

centroids_adm2 <- st_as_sf(centroids_adm2, 
                           
                           coords = c("lon", "lat"), 
                           
                           crs = CRS_adm2)

#1.2) Assign the coordinate reference system from the ADM shape file to the capitals file.

CRS_adm2  <- st_crs(ADM2)

#1.3) Rewrite the capitals csv as an sf file.

capitales_spatialADM2 <- st_as_sf(capitals, 
                                  
                                  coords = c("longitude", "latitude"), 
                                  
                                  crs = CRS_adm2)

#2.2) Extract the names of each country in the centroids' file and the capitals' file
f_2 <- centroids_adm2 %>% mutate(NAME_0= as.factor(NAME_0))

d_2<- capitales_spatialADM2 %>% mutate(CountryName=as.factor(CountryName))

t_p_2<- c(levels(f_2$NAME_0[duplicated(f_2$NAME_0)]))
t_d_2<- c(levels(d_2$CountryName[duplicated(d_2$CountryName)]))

#2.3) Create a function that calculates the distance between capital and centroids 
funcion_dist_adm2<-  function(x,y) {
   
   c_by <- centroids_adm2%>% filter(NAME_0==x) 
   ca_by<- capitales_spatialADM2 %>% filter(CountryName==y)
   
   nearest_capital <- st_nearest_feature(c_by, ca_by)
   dist <- st_distance(c_by,ca_by[nearest_capital,], by_element=TRUE) 
   
   pljoin <- cbind(c_by, st_drop_geometry(ca_by)[nearest_capital,])
   
   pljoin$dist <- (dist/1000) %>%
      drop_units()
   
   cap <- pljoin %>%  select(GID_2,dist,CapitalName) %>% 
      clean_names() %>% st_sf() %>% 
      rename('dist_km' = dist) %>% 
      st_drop_geometry()
   
   
}

#2.5) Run a Loop that calculates the distance for the rest of the countries

final_adm2 <- data.frame() 
g <- data.frame()

for (i in t_p_2){
   
   for(j in t_d_2){
      
      if (i == j)
         
         g <- funcion_dist_adm2(i,j)
      
      final_adm2 <- rbind(final_adm2,g) %>% distinct()
   }
}


#2.6) Clean de data outcome

names(final_adm2) <- c('GID_2', 'dist_km_popcentr' , 'capital_name')

dist_popcentr_2 <- final_adm2
