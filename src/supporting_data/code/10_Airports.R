# Dataset of airport count by administrative area. Classifies airports 
# as international, medium or large.  


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
library(jsonlite)


#1. Load Data ---------------------------------------------------------------

#1.1 ADM1
ADM1<-st_read("../data/raw/ADM/gadm36_1.shp")

#1.2 ADM2
ADM2<-st_read("../data/raw/ADM/gadm36_2.shp")

#1.3 Airports shape file

Airports <- st_read("../data/raw/Airports/Airports.shp")

#2. cleaning data ------------------------------------------------------------

#2.1 Airports Data: Separate longitude and latitude in two columns

lon_lat <- data.table::fread(text = paste0(Airports$coordinates, collapse = "\n"), data.table = FALSE)

colnames(lon_lat) <-c("longitude","latitude")

Airports<- cbind(Airports,lon_lat)

#2.2 Set the CRS from the ADM shape file to the airports file

CRS_adm1  <- st_crs(ADM1)

#2.3 Create the Airports Shape file

Airports <- st_as_sf(Airports , 
                     coords = c("longitude", "latitude"), 
                     crs = CRS_adm1)

#2.4 Create the International Airports file

airports_international <- Airports  %>% filter(grepl('International|international', name))

#2.5 Create the Large Airports file

airports_large <- Airports %>% filter(type=="large_airport")

#2.6 Create the Medium Airports file 

airports_medium <- Airports %>% filter(type=="medium_airport")

#2.7 Remove undesired objects from the environment to save space

remove(CRS_adm1,lon_lat)

#3. ADM1 --------------------------------------------------------------------

#3.1 International: Spatial match with ADM1 

sf::sf_use_s2(FALSE)

match_airports_international <- airports_international %>%
   
   st_join(ADM1,
           join = st_intersects, 
           left = TRUE) 


#3.2 International: Identify those (Nas) Int. Airports that did not match spatially 

nas_international <- match_airports_international[is.na(match_airports_international$GID_1),]

nas_international <- nas_international %>% select(name,iso_3)


#3.3 Identify the countries with administrative areas at a (ADM1) level in the (Nas) Int. Airports

# Extract GID_0 codes of countries with (ADM1)
names_countries_ADM1<- ADM1$GID_0 

# Filter the (NAs) Int. Airports by countries with ADM1

nas_countries_in_adm1 <-nas_international %>% filter(iso_3 %in% names_countries_ADM1) 

#3.4 International: (Nas) Int. Airports to the nearest ADM1

match_nas_international <- nas_countries_in_adm1 %>% 
   
   st_join(ADM1, 
           join = st_nearest_feature,
           left = TRUE) 

#3.5 International: Count all the Int. Airports in each ADM1

match_airports_international <-  match_airports_international[!is.na(match_airports_international$GID_1),]

match_airports_international <- match_airports_international %>%
   
   add_count(GID_1,name = "int_airports") %>% 
   
   select(GID_1,int_airports) %>% 
   
   st_drop_geometry() %>% 
   
   distinct()

match_nas_international <- match_nas_international %>% 
   
   add_count(GID_1,name = "int_airports") %>% 
   
   select(GID_1,int_airports) %>% 
   
   st_drop_geometry() %>% 
   
   distinct()


#3.6 International: Join (Nas) Int. Airports results with Int. Airports results

match_airports_international <- rbind(match_airports_international,match_nas_international)

match_airports_international <- match_airports_international  %>% 
   
   group_by(GID_1) %>% 
   
   summarise(int_airports=sum(int_airports))


#3.7 International: Join the total number of Int. Airports by GID_1 to the ADM1 file

ADM1_Airports <- ADM1 %>% left_join(match_airports_international,by="GID_1")

ADM1_Airports <- ADM1_Airports%>% 
   
   mutate(int_airports = coalesce(int_airports, 0))


#3.8 Large: Spatial match with ADM1 

sf::sf_use_s2(FALSE)

match_airports_large <- airports_large %>%
   
   st_join(ADM1,
           join = st_intersects, 
           left = TRUE) 


#3.9 Large: Identify those (Nas) Large. Airports that did not match spatially 

nas_large <- match_airports_large[is.na(match_airports_large$GID_1),]

nas_large <- nas_large %>% select(name,iso_3)


#3.10 Identify the countries with administrative areas at a (ADM1) level in the (Nas) Large. Airports

# Extract GID_0 codes of countries with (ADM1)
names_countries_ADM1<- ADM1$GID_0 

# Filter the (NAs) Large. Airports by countries with ADM1

nas_countries_in_adm1 <-nas_large %>% filter(iso_3 %in% names_countries_ADM1)

nas_countries_in_adm1 <-nas_countries_in_adm1[-2,] # Particular case: eliminate not precise point

#3.11 Large: (Nas) Large. Airports to the nearest ADM1

match_nas_large <- nas_countries_in_adm1 %>% 
   
   st_join(ADM1, 
           join = st_nearest_feature,
           left = TRUE) 

#3.12 Large: Count all the Large. Airports in each ADM1

match_airports_large <-  match_airports_large[!is.na(match_airports_large$GID_1),]

match_airports_large <- match_airports_large %>%
   
   add_count(GID_1,name = "large_airports") %>% 
   
   select(GID_1,large_airports) %>% 
   
   st_drop_geometry() %>% 
   
   distinct()

match_nas_large <- match_nas_large %>% 
   
   add_count(GID_1,name = "large_airports") %>% 
   
   select(GID_1,large_airports) %>% 
   
   st_drop_geometry() %>% 
   
   distinct()


#3.13 Large: Join (Nas) Large. Airports results with Large. Airports results

match_airports_large <- rbind(match_airports_large,match_nas_large)

match_airports_large <- match_airports_large  %>% 
   
   group_by(GID_1) %>% 
   
   summarise(large_airports=sum(large_airports))


#3.14 Large: Join the total number of Large. Airports by GID_1 to the ADM1 file

ADM1_Airports <- ADM1_Airports %>% left_join(match_airports_large,by="GID_1")

ADM1_Airports <- ADM1_Airports%>% 
   
   mutate(large_airports = coalesce(large_airports, 0))

#3.15 Medium: Spatial match with ADM1 

sf::sf_use_s2(FALSE)

match_airports_medium <- airports_medium %>%
   
   st_join(ADM1,
           join = st_intersects, 
           left = TRUE) 


#3.16 Medium: Identify those (Nas) Medium. Airports that did not match spatially 

nas_medium <- match_airports_medium[is.na(match_airports_medium$GID_1),]

nas_medium <- nas_medium %>% select(name,iso_3)

#3.17 Identify the countries with administrative areas at a (ADM1) level in the (Nas) Medium. Airports

# Extract GID_0 codes of countries with (ADM1)

names_countries_ADM1<- ADM1$GID_0 

# Filter the (NAs) Medium. Airports by countries with ADM2

nas_countries_in_adm1 <- nas_medium %>% filter(iso_3 %in% names_countries_ADM1) 

#3.18 Medium: (Nas) Medium. Airports to the nearest ADM1

match_nas_medium <- nas_countries_in_adm1 %>% 
   
   st_join(ADM1, 
           join = st_nearest_feature,
           left = TRUE) 

#3.19 Medium: Count all the Medium. Airports in each ADM1

match_airports_medium <-  match_airports_medium[!is.na(match_airports_medium$GID_1),]

match_airports_medium <- match_airports_medium %>%
   
   add_count(GID_1,name = "medium_airports") %>% 
   
   select(GID_1,medium_airports) %>% 
   
   st_drop_geometry() %>% 
   
   distinct()

match_nas_medium <- match_nas_medium %>% 
   
   add_count(GID_1,name = "medium_airports") %>% 
   
   select(GID_1,medium_airports) %>% 
   
   st_drop_geometry() %>% 
   
   distinct()

#3.20 Medium: Join (Nas) Medium. Airports results with Medium. Airports results

match_airports_medium <- rbind(match_airports_medium,match_nas_medium)

match_airports_medium <- match_airports_medium %>% 
   
   group_by(GID_1) %>% 
   
   summarise(medium_airports=sum(medium_airports))


#3.21 Medium: Join the total number of Medium. Airports by GID_1 to the ADM1 file

ADM1_Airports <- ADM1_Airports %>% left_join(match_airports_medium,by="GID_1")

ADM1_Airports <- ADM1_Airports %>% 
   
   mutate(medium_airports = coalesce(medium_airports, 0))

#3.22 Remove undesired objects from the environment to save space

remove(ADM1,match_airports_international,match_airports_large,match_airports_medium,
       match_nas_international,match_nas_large,match_nas_medium,nas_international,nas_large,
       nas_medium,nas_countries_in_adm1,names_countries_ADM1)
#4. ADM2 --------------------------------------------------------------------

#4.1 International: Spatial match with ADM2

sf::sf_use_s2(FALSE)

match_airports_international <- airports_international %>%
   
   st_join(ADM2,
           join = st_intersects, 
           left = TRUE) 

#4.2 International: Identify those (Nas) Int. Airports that did not match spatially 

nas_international <- match_airports_international[is.na(match_airports_international$GID_2),]

nas_international <- nas_international %>% select(name,iso_3)

#4.3 Identify the countries with administrative areas at a secundary level (ADM2) in the (Nas) Int. Airports

# Extract GID_0 codes of countries with (ADM2)
names_countries_ADM2<- ADM2$GID_0 

# Filter the (NAs) Int. Airports by countries with ADM2

nas_countries_in_adm2 <-nas_international %>% filter(iso_3 %in% names_countries_ADM2) 

#4.4 International: (Nas) Int. Airports to the nearest ADM2

match_nas_international <- nas_countries_in_adm2 %>% 
   
   st_join(ADM2, 
           join = st_nearest_feature,
           left = TRUE) 

#4.5 International: Count all the Int. Airports in each ADM2

match_airports_international <-  match_airports_international[!is.na(match_airports_international$GID_2),]

match_airports_international <- match_airports_international %>%
   
   add_count(GID_2,name = "int_airports") %>% 
   
   select(GID_2,int_airports) %>% 
   
   st_drop_geometry() %>% 
   
   distinct()

match_nas_international <- match_nas_international %>% 
   
   add_count(GID_2,name = "int_airports") %>% 
   
   select(GID_2,int_airports) %>% 
   
   st_drop_geometry() %>% 
   
   distinct()


#4.6 International: Join (Nas) Int. Airports results with Int. Airports results

match_airports_international <- rbind(match_airports_international,match_nas_international)

match_airports_international <- match_airports_international  %>% 
   
   group_by(GID_2) %>% 
   
   summarise(int_airports=sum(int_airports))

#4.7 International: Join the total number of Int. Airports by GID_2 to the ADM2 file

ADM2_Airports <- ADM2 %>% left_join(match_airports_international,by="GID_2")

ADM2_Airports <- ADM2_Airports %>% 
   
   mutate(int_airports = coalesce(int_airports, 0))


#4.8 Large: Spatial match with ADM2 

sf::sf_use_s2(FALSE)

match_airports_large <- airports_large %>%
   
   st_join(ADM2,
           join = st_intersects, 
           left = TRUE) 


#4.9 Large: Identify those (Nas) Large. Airports that did not match spatially 

nas_large <- match_airports_large[is.na(match_airports_large$GID_2),]

nas_large <- nas_large %>% select(name,iso_3)

#4.10 Identify the countries with administrative areas at a secundary level (ADM2) in the (Nas) Large. Airports

# Extract GID_0 codes of countries with (ADM2)
names_countries_ADM2<- ADM2$GID_0 

# Filter the (NAs) Large. Airports by countries with ADM2

nas_countries_in_adm2 <-nas_large %>% filter(iso_3 %in% names_countries_ADM2) 

#4.11 Large: (Nas) Large. Airports to the nearest ADM2

match_nas_large <- nas_countries_in_adm2 %>% 
   
   st_join(ADM2, 
           join = st_nearest_feature,
           left = TRUE) 

#4.12 Large: Count all the Large. Airports in each ADM2

match_airports_large <-  match_airports_large[!is.na(match_airports_large$GID_2),]

match_airports_large <- match_airports_large %>%
   
   add_count(GID_2,name = "large_airports") %>% 
   
   select(GID_2,large_airports) %>% 
   
   st_drop_geometry() %>% 
   
   distinct()

match_nas_large <- match_nas_large %>% 
   
   add_count(GID_2,name = "large_airports") %>% 
   
   select(GID_2,large_airports) %>% 
   
   st_drop_geometry() %>% 
   
   distinct()


#4.13 Large: Join (Nas) Large. Airports results with Large. Airports results

match_airports_large <- rbind(match_airports_large,match_nas_large)

match_airports_large <- match_airports_large  %>% 
   
   group_by(GID_2) %>% 
   
   summarise(large_airports=sum(large_airports))


#4.14 Large: Join the total number of Large. Airports by GID_2 to the ADM2 file

ADM2_Airports <- ADM2_Airports %>% left_join(match_airports_large,by="GID_2")

ADM2_Airports <- ADM2_Airports%>% 
   
   mutate(large_airports = coalesce(large_airports, 0))


#4.15 Medium: Spatial match with ADM2 

sf::sf_use_s2(FALSE)

match_airports_medium <- airports_medium %>%
   
   st_join(ADM2,
           join = st_intersects, 
           left = TRUE) 

#4.16 Medium: Identify those (Nas) Medium. Airports that did not match spatially 

nas_medium <- match_airports_medium[is.na(match_airports_medium$GID_2),]

nas_medium <- nas_medium %>% select(name,iso_3)


#4.17 Identify the countries with administrative areas at a secundary level (ADM2) in the (Nas) Medium. Airports

# Extract GID_0 codes of countries with (ADM2)

names_countries_ADM2<- ADM2$GID_0 

# Filter the (NAs) Medium. Airports by countries with ADM2

nas_countries_in_adm2 <- nas_medium %>% filter(iso_3 %in% names_countries_ADM2) 

#4.18 Medium: (Nas) Medium. Airports to the nearest ADM2

match_nas_medium <- nas_countries_in_adm2 %>% 
   
   st_join(ADM2, 
           join = st_nearest_feature,
           left = TRUE) 

#4.19 Medium: Count all the Medium. Airports in each ADM2

match_airports_medium <-  match_airports_medium[!is.na(match_airports_medium$GID_2),]

match_airports_medium <- match_airports_medium %>%
   
   add_count(GID_2,name = "medium_airports") %>% 
   
   select(GID_2,medium_airports) %>% 
   
   st_drop_geometry() %>% 
   
   distinct()

match_nas_medium <- match_nas_medium %>% 
   
   add_count(GID_2,name = "medium_airports") %>% 
   
   select(GID_2,medium_airports) %>% 
   
   st_drop_geometry() %>% 
   
   distinct()

#4.20 Medium: Join (Nas) Medium. Airports results with Medium. Airports results

match_airports_medium <- rbind(match_airports_medium,match_nas_medium)

match_airports_medium <- match_airports_medium %>% 
   
   group_by(GID_2) %>% 
   
   summarise(medium_airports=sum(medium_airports))


#4.21 Medium: Join the total number of Medium. Airports by GID_2 to the ADM2 file

ADM2_Airports <- ADM2_Airports %>% left_join(match_airports_medium,by="GID_2")

ADM2_Airports <- ADM2_Airports %>% 
   
   mutate(medium_airports = coalesce(medium_airports, 0))

#4.22 Remove undesired objects from the environment to save space

remove(ADM2,Airports,airports_international,airports_large,airports_medium,
       match_airports_international,match_airports_medium,match_airports_large,
       match_nas_international,match_nas_large,match_nas_medium,nas_countries_in_adm2,
       nas_international,nas_large,nas_medium,names_countries_ADM2)

#5. Exporting files ---------------------------------------------------------------

# ADM1

ADM1_Airports <- ADM1_Airports %>% st_drop_geometry()

export(ADM1_Airports,"../data/clean/ADM1_Airports.xlsx")

# ADM2

ADM2_Airports <- ADM2_Airports %>% st_drop_geometry()

export(ADM2_Airports,"../data/clean/ADM2_Airports.xlsx")



