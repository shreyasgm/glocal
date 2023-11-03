# Distance from geometric centroid of each administrative area to its 
# corresponding capital. 


#1. Load packages  ----------------------------------------------------------
library(tidyverse)
library(sf)

#2. ADM1 -----------------------------------------------------------------

#2.1 Extract the names of each country in the centroids file and the capitals file

f <- centroids_adm1 %>% mutate(NAME_0= as.factor(NAME_0))

d <- capitales_spatialADM1 %>% mutate(CountryName=as.factor(CountryName))

t_p <- c(levels(f$NAME_0[duplicated(f$NAME_0)]))

t_d <- c(levels(d$CountryName[duplicated(d$CountryName)]))

#2.2 Create a function that calculates the distance between capital and centroids 

funcion_dist_adm1<-  function(x,y) {
   
   c_by <- centroids_adm1%>% filter(NAME_0==x) 
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
   
}


#2.3 Run a Loop that calculates the distance for the rest of the countries

final_adm1 <- data.frame()

for (i in t_p){
   
   for(j in t_d){
      
      if (i == j)
         
         h<- funcion_dist_adm1(i,j)
      
      final_adm1 <- rbind(final_adm1,h) %>% distinct()
   }
}

#2.4 Clean de data outcome

names(final_adm1)[1] <- 'GID_1'

tt <- left_join(base1_capitales, final_adm1, by=c("GID_1"))

centroids_log_lat_ADM1 <- centroids_adm1 %>% select(GID_1) %>% 
   
   mutate(lon_geomcentroid = unlist(map(centroids_adm1$geometry,1)),
          lat_geomcentroid = unlist(map(centroids_adm1$geometry,2))) %>%
   st_drop_geometry() 

g_ADM1  <- left_join(tt,centroids_log_lat_ADM1, by=c("GID_1")) %>% 
   
   select(GID_1,capital,dist_km,lon_geomcentroid,lat_geomcentroid)

##2.5 Solution task ADM1: capitals and centroids 
ADM1_base <- g_ADM1

#3. ADM2 --------------------------------------------------------------------

#3.1 Extract the names of each country in the centroids' file and the capitals' file
f_2 <- centroids_adm2 %>% mutate(NAME_0= as.factor(NAME_0))

d_2<- capitales_spatialADM2 %>% mutate(CountryName=as.factor(CountryName))

t_p_2<- c(levels(f_2$NAME_0[duplicated(f_2$NAME_0)]))
t_d_2<- c(levels(d_2$CountryName[duplicated(d_2$CountryName)]))

#3.2 Create a function that calculates the distance between capital and centroids 
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


#3.3 Run a Loop that calculates the distance for the rest of the countries

final_adm2 <- data.frame() 

for (i in t_p_2){
   
   for(j in t_d_2){
      
      if (i == j)
         
         g<- funcion_dist_adm2(i,j)
      
      final_adm2 <- rbind(final_adm2,g) %>% distinct()
   }
}



#3.4 Clean de data outcome

names(final_adm2)[1] <- 'GID_2'



tt_2 <- left_join(base2_capitales, final_adm2, by=c("GID_2"))

centroids_log_lat_ADM2 <- centroids_adm2 %>% select(GID_2) %>% 
   mutate(lon_geomcentroid = unlist(map(centroids_adm2$geometry,1)),
          lat_geomcentroid = unlist(map(centroids_adm2$geometry,2))) %>%
   st_drop_geometry() 



g_ADM2  <- left_join(tt_2,centroids_log_lat_ADM2, by=c("GID_2")) %>% 
   
   select(GID_2,capital,dist_km,lon_geomcentroid,lat_geomcentroid)


##3.5  Solution task ADM2: capitals and centroids ADM2
ADM2_base <- g_ADM2


 