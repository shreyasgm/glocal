# Binary variable that assigns 1 if an administrative area has a river or  
# lake and 0 in the contrary. 


#1. Load packages -----------------------------------------------------------
library(sf)
library(tidyverse)
 
#2. Load data ---------------------------------------------------------------

Rios_lagos <- st_read("../data/raw/rivers_lakes/ne_10m_rivers_lake_centerlines_scale_rank.shp")

#3. ADM1 --------------------------------------------------------------------

#3.1) Perform a spatial match between the ADM file and the rivers and lakes file with a margin error of 20 mts.
sf::sf_use_s2(TRUE)

Match1_rios<-Rios_lagos %>%
   st_join(ADM1,
           join = st_is_within_distance, 
           left = TRUE,
           dist= 20) 

#3.2) Extract  the ADMs codes that matched spatially with a river or lake.
Match1_CODES_rios <- Match1_rios %>% 
   
   select(GID_1, NAME_1,NAME_0,name )

para_binaria1_rios <- Match1_CODES_rios$GID_1


#3.3) Create dummy variable in the ADM file 
ADM1_base <- ADM1_base %>% 
   
   select("GID_1","capital","border","dist_km","lon_geomcentroid","lat_geomcentroid") %>% 
   
   mutate(rios_lagos= if_else(GID_1 %in% para_binaria1_rios, 1, 0))

 
#4. ADM2 --------------------------------------------------------------------

#4.1 Perform a spatial match between the ADM file and the rivers and lakes file with a margin error of 20 mts.

sf::sf_use_s2(TRUE)

Match2_rios <-Rios_lagos %>%
   st_join(ADM2,
           join = st_is_within_distance, 
           left = TRUE,
           dist= 20) 

#4.2 Extract  the ADMs codes that matched spatially with a river or lake.

Match2_CODES_rios <- Match2_rios %>% 
   
   select(GID_2, NAME_2,NAME_0,name )

para_binaria2_rios <- Match2_CODES_rios$GID_2

#4.3 Create dummy variable in the ADM file 

ADM2_base <- ADM2_base %>% 
   
   select("GID_2","capital","border","dist_km","lon_geomcentroid","lat_geomcentroid") %>% 
   
   mutate(rios_lagos= if_else(GID_2 %in% para_binaria2_rios, 1, 0))

