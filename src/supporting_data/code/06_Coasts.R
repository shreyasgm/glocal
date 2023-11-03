# Binary variable that assigns 1 if an administrative area has coasts 
# and 0 in the contrary. 


#1. Load packages -----------------------------------------------------------
library(sf)
library(tidyverse)

#2. Load data ---------------------------------------------------------------

coasts <- st_read("../../data/raw/coastline/ne_10m_coastline.shp")

#3. ADM1 --------------------------------------------------------------------

#3.1 Perform a spatial match between the ADM file and the coastline file with a margin of error of 20 meters
Match1_coasts <- coasts %>%
   
   st_join(ADM1,
           join = st_is_within_distance, 
           left = TRUE,
           dist= 20) 

#3.2 Extract  the ADMs codes that  spatially matched with a coastline

Match1_CODES_coasts <- Match1_coasts %>% 
   
   select(GID_1, NAME_1,NAME_0)

para_binaria1_coasts <- Match1_CODES_coasts$GID_1


#3.3 Create dummy variable in the ADM file 

ADM1_base$coasts <- ""
ADM1_base$coasts <- ifelse(ADM1_base$GID_1 %in% para_binaria1_coasts, 1, 0)

#4. ADM2 --------------------------------------------------------------------

#4.1 Perform a spatial match between the ADM file and the coastline file with a margin of error of 20 meters
Match2_coasts <- coasts %>%
   
   st_join(ADM2,
           join = st_is_within_distance, 
           left = TRUE,
           dist= 20) 

#4.2 Extract  the ADMs codes that  spatially matched with a coastline

Match2_CODES_coasts <- Match2_coasts %>% 
   
   select(GID_2, NAME_2,NAME_0)

para_binaria2_coasts <- Match2_CODES_coasts$GID_2


#4.3 Create dummy variable in the ADM file 

ADM2_base$coasts <- ""
ADM2_base$coasts <- ifelse(ADM2_base$GID_2 %in% para_binaria2_coasts, 1, 0)
 