# Binary variable that assigns 1 if an administrative area is a capital 
# and 0 in the contrary. 

#1. Load packages -----------------------------------------------------------
library(readr)
library(readxl)
library(sf)
library(tidyverse)

#2. Load Data --------------------------------------------------------------------

# Capitals data
capitales <-  read.csv("../data/raw/GADM/countries_capitals_ggmp.csv")%>%  
   
   mutate(longitude = as.numeric(longitude),
          
          latitude = as.numeric(latitude)) %>% 
   
   na.omit()

#3. ADM1 -----------------------------------------------------------------

#3.1 Assign the coordinate reference system from the ADM shape file to the capitals file.

CRS_adm1  <- st_crs(ADM1)

#3.2 Rewrite the capitals csv as an sf file.

capitales_spatialADM1 <- st_as_sf(capitales, 
                                  
                                  coords = c("longitude", "latitude"), 
                                  
                                  crs = CRS_adm1)

#3.3 Perform a spatial match between the ADM file and the capitals file.

sf::sf_use_s2(FALSE)

Match1_capitales <- capitales_spatialADM1 %>%
   
   st_join(ADM1,
           join = st_intersects, 
           left = TRUE) 

#3.4 Extract  the ADMs codes that matched spatially with a capital location.

Match1_CODES_capitales <- Match1_capitales %>% 
   
   select(GID_1) %>% 
   na.omit()

para_binaria1_capitales <- Match1_CODES_capitales$GID_1

#3.5 Create dummy variable in the ADM file 

base1_capitales <- ADM1 %>% 
   
   select("GID_1") %>% 
   
   mutate(capital= if_else(GID_1 %in% para_binaria1_capitales, 1, 0)) %>% 
   
   st_drop_geometry()
 
#4. ADM2 --------------------------------------------------------

#4.1 Repeat the process for ADM2 

# Assign the coordinate reference system from the ADM shape file to the capitals file.

CRS_adm2  <- st_crs(ADM2)

# Rewrite the capitals csv as an sf file.

capitales_spatialADM2 <- st_as_sf(capitales, 
                                  
                                  coords = c("longitude", "latitude"), 
                                  
                                  crs = CRS_adm2)

# Perform a spatial match between the ADM file and the capitals file.
sf::sf_use_s2(FALSE)

Match2_capitales <- capitales_spatialADM2 %>%
   
   st_join(ADM2,
           join = st_intersects, 
           left = TRUE) 

# Extract  the ADMs codes that matched spatially with a capital location.

Match2_CODES_capitales <- Match2_capitales %>% 
   
   select(GID_2) %>% 
   na.omit()

para_binaria2_capitales <- Match2_CODES_capitales$GID_2

# Create dummy variable in the ADM file 

base2_capitales <- ADM2 %>% 
   
   select("GID_2") %>% 
   
   mutate(capital= if_else(GID_2 %in% para_binaria2_capitales, 1, 0)) %>% 
   
   st_drop_geometry()
 