# Dataset of port count by administrative area.


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
library(fuzzyjoin)

#1. Load Data ---------------------------------------------------------------

# ADM1:  
ADM1<-st_read("../data/raw/ADM/gadm36_1.shp")

# ADM2
ADM2<-st_read("../data/raw/ADM/gadm36_2.shp")

# Ports
Ports <-st_read("../data/raw/Ports/wld_trs_ports_wfp.shp")

#2. Clean Data --------------------------------------------------------------

#2.1 Ports Data: Filter by indicated type and size

type  <- c("Sea","sea","Sea Port","River","Lake","Other","Unknown")
size  <- c("Small","small","Unknown","Medium","Large","Other","Big")

Ports <- Ports %>% filter(prttype %in% type,
                          prtsize %in% size)

#2.2 Remove undesired objects from the environment to save space

remove(size,type)

#3. ADM1 --------------------------------------------------------------------

#3.1 Spatial match between Ports and ADM1

sf::sf_use_s2(FALSE)

Match1_Ports <- Ports %>%
   
   st_join(ADM1,
           join = st_intersects, 
           left = TRUE) 

#3.2 Identify those (Nas) Ports that did not match spatially with an ADM1[They are outside the polygons]

nas_ <-Match1_Ports[is.na(Match1_Ports$GID_1),]

nas_ <- nas_ %>% select(portname,code,country,iso3_op)


#3.3 Identify the countries with administrative areas at a ADM1 level in the (Nas) Ports

nas_$`iso3_op`[nas_$iso3_op == "IRN,AFG"] <- "IRN" # Particular case

nas_$`iso3_op`[nas_$iso3_op == "LBN,SYR"] <- "LBN" # Particular case

nas_$`iso3_op`[nas_$iso3_op == "OMN,YEM"] <- "OMN" # Particular case

nas_$`iso3_op`[nas_$iso3_op == "NAM, ZWE"] <- "NAM" # Particular case

nas_$`iso3_op`[nas_$country == "Lebanon"] <- "LBN" # Particular case

# Extract GID_0 codes of countries with (ADM1)
names_countries_ADM1<- ADM1$GID_0 

# Filter the (NAs) Ports by countries with ADM2

nas_countries_in_adm1 <-nas_ %>% filter(iso3_op %in% names_countries_ADM1) 

#3.4 Match (Nas) Ports to the nearest ADM1
Match_nas <- nas_countries_in_adm1 %>% 
   
   st_join(ADM1, 
           join = st_nearest_feature,
           left = TRUE) 

#3.5 Count all the Ports in each ADM1

Match1_Ports <-  Match1_Ports[!is.na(Match1_Ports$GID_1),]

Match1_Ports <- Match1_Ports %>%
   
   add_count(GID_1,name = "ports") %>% 
   
   select(GID_1,ports) %>% 
   
   st_drop_geometry() %>% 
   
   distinct()

Match_nas <- Match_nas %>% 
   
   add_count(GID_1,name = "ports") %>% 
   
   select(GID_1,ports) %>% 
   
   st_drop_geometry() %>% 
   
   distinct()

#3.6 Join (Nas) Ports results with Ports results

Match1_Ports <- rbind(Match1_Ports,Match_nas)

Match1_Ports <- Match1_Ports  %>% 
   
   group_by(GID_1) %>% 
   
   summarise(ports=sum(ports))


#3.7 Join the total number of Ports by GID_1 to the ADM1 file

ADM1_Ports <- ADM1 %>% left_join(Match1_Ports,by="GID_1")

ADM1_Ports <- ADM1_Ports %>% 
   
   mutate(ports = coalesce(ports, 0))

#3.8 Remove undesired objects from the environment to save space

remove(ADM1,Match1_Ports,Match_nas,nas_,names_countries_ADM1,nas_countries_in_adm1)

#4. ADM2 --------------------------------------------------------------------

#4.1 Spatial match between Ports and ADM2

sf::sf_use_s2(FALSE)

Match2_Ports <- Ports %>%
   
   st_join(ADM2,
           join = st_intersects, 
           left = TRUE) 

#4.2 Identify those (Nas) Ports that did not match spatially with an ADM2 [They are outside the polygons]

nas_ <- Match2_Ports[is.na(Match2_Ports$GID_2),]

nas_ <- nas_ %>% select(portname,code,country,iso3_op)

#4.3 Identify the countries with administrative areas at a secundary level (ADM2) in the (Nas) Ports

nas_$`iso3_op`[nas_$iso3_op == "LBN,SYR"] <- "LBN" # Particular case

nas_$`iso3_op`[nas_$iso3_op == "OMN,YEM"] <- "OMN" # Particular case

nas_$`iso3_op`[nas_$iso3_op == "NAM, ZWE"] <- "NAM" # Particular case

# Extract GID_0 codes of countries with (ADM2)
names_countries_ADM2<- ADM2$GID_0 

# Filter the (NAs) Ports by countries with ADM2

nas_countries_in_adm2 <-nas_ %>% filter(iso3_op %in% names_countries_ADM2) 

#4.4 Match (Nas) Ports to the nearest ADM2
Match_nas <- nas_countries_in_adm2 %>% 
   
   st_join(ADM2, 
           join = st_nearest_feature,
           left = TRUE) 

#4.5 Count all the Ports in each ADM2

Match2_Ports<-  Match2_Ports[!is.na(Match2_Ports$GID_2),]

Match2_Ports <- Match2_Ports %>%
   
   add_count(GID_2,name = "ports") %>% 
   
   select(GID_2,ports) %>% 
   
   st_drop_geometry() %>% 
   
   distinct()

Match_nas <- Match_nas %>% 
   
   add_count(GID_2,name = "ports") %>% 
   
   select(GID_2,ports) %>% 
   
   st_drop_geometry() %>% 
   
   distinct()

#4.6 Join (Nas) Ports results with Ports results

Match2_Ports <- rbind(Match2_Ports,Match_nas)

Match2_Ports <- Match2_Ports  %>% 
   
   group_by(GID_2) %>% 
   
   summarise(ports=sum(ports))


#4.7 Join the total number of Ports by GID_2 to the ADM2 file

ADM2_Ports <- ADM2 %>% left_join(Match2_Ports,by="GID_2")

ADM2_Ports <- ADM2_Ports %>% 
   
   mutate(ports = coalesce(ports, 0))

#4.8 Remove undesired objects from the environment to save space

remove(ADM2,Match2_Ports,nas_,nas_countries_in_adm2,Ports,names_countries_ADM2,Match_nas)



































#5. Exporting files ------------------------------------------------------

# ADM1

ADM1_Ports<- ADM1_Ports %>% st_drop_geometry()

export(ADM1_Ports,"../data/clean/ADM1_Ports.xlsx")

# ADM2

ADM2_Ports<- ADM2_Ports %>% st_drop_geometry()

export(ADM2_Ports,"../data/clean/ADM2_Ports.xlsx")


