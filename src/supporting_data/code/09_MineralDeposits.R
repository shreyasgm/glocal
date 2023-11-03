# Dataset of mineral variables with deposit count by administrative level.


#1. Load packages -----------------------------------------------------------
library(tidyverse)
library(dplyr)
library(sf)
library(readr)
library(readxl)
library(stringr)

#2. Load data ---------------------------------------------------------------

minas <- read.csv("../../data/raw/mrds.csv")%>%  
   
   mutate(longitude = as.numeric(longitude),
          
          latitude = as.numeric(latitude)) %>%
   
   filter(!(is.na(longitude) | is.na(latitude)))


# Mineral deposits with missing lon or lat. 

missing <- read.csv("../../data/raw/mrds.csv")%>%  
   
   mutate(longitude = as.numeric(longitude),
          
          latitude = as.numeric(latitude)) %>%
   
   filter((is.na(longitude) | is.na(latitude)))

# Mineral list from https://mrdata.usgs.gov/mrds/map-commodity.html#home

tech_min <- c("Aluminum","Cadmium","Graphite","Lithium","Copper","Indium")

energy_min <- c("Coal","Petroleum (Oil)","Natural Gas","Uranium")

precious_min <- c("Emerald","Diamond","Gold",
                  "Gold, Refinery","Platinum","Ruby","Garnet","Semiprecious Gemstone",
                  "Sapphire","Quartz", "Gemstone")

other_min <- c("Abrasive", "Aggregate, Light Weight","Aluminum, Contained or Metal","Aluminum, High Alumina Clay",
               "Andalusite","Anthracite","Antimony","Arsenic","Asbestos","Bituminous",
               "Ash","Ball Clay","Barium-Barite","Bentonite","Beryllium",
               "Bismuth","Bloating Material","Boron-Borates",
               "Brick Clay","Bromine","Calcium","Carbon Dioxide", "Cement Rock","Cerium","Cesium","Chlorine","Chlorite",
               "Chromium","Chromium, Ferrochrome","Clay","Cobalt","Copper Oxide","Copper Sulfide","Corundum",
               "Diatomite","Dolomite","Emery","Feldspar","Fire Clay (Refractory)",
               "Flagstone","Flint","Fluorine-Fluorite","Fullers Earth","Gallium",
               "Geothermal","Germanium","Gilsonite","Granite","Granite, Dimension",
               "Gypsum-Anhydrite","Gypsum-Anhydrite, Alabaster","Hafnium",
               "Halite","Hectorite","Helium","Iodine","Iridium",
               "Iron","Iron Oxide Pigments","Iron, Pig Iron","Iron-Pyrite",
               "Kaolin","Kyanite","Lead","Lead, Refiner","Lead, Smelter",
               "Lignite","Limestone, Crushed/Broken","Limestone, Dimension",
               "Limestone, General","Limestone, High Calcium","Limestone, Ultra Pure",
               "Magnesite","Magnesium Compounds","Manganese",
               "Manganese, Ferromanganese","Marble, Dimension","Mercury",
               "Mica","Mineral Pigments","Molybdenum","Montmorillonite",
               "Nickel","Nickel Laterite","Nickel, Refiner",
               "Nickel, Smelter","Niobium (Columbium)","Nitrogen-Nitrates", 
               "Oil Sands","Oil Shale","Olivine","Osmium","Palladium",
               "Peat","Perlite","PGE","Phosphorus-Phosphates",
               "Potassium","Potassium, Potash","Pumice","Pyrite",
               "Pyrophyllite","Quartz","Radium","REE","Rhenium","Rhodium", 
               "Rock Asphalt","Rubidium","Ruthenium","Salt","Sand",
               "Sand and Gravel, Construction","Sand and Gravel, Industrial",
               "Sand and Gravel, Industrial/Frac Sand","Sandstone, Crushed/Broken",
               "Sandstone, Dimension", "Scandium","Selenium",
               "Silica","Silica, Ferrosilicon",
               "Silver","Silver, Refinery","Slate, Dimension","Soda Ash",
               "Sodium","Sodium Carbonate","Sodium Sulfate","Staurolite",
               "Stone","Stone, Crushed/Broken","Stone, Dimension",
               "Strontium","Subbituminous","Sulfides","Sulfur","Sulfur-Pyrite",
               "Sulfur, Sulfuric Acid","Talc-Soapstone","Tantalum",
               "Tantalum from Tin Slag","Tellurium","Thallium","Thorium",
               "Tin","Tin, Tailings","Titanium","Titanium-Heavy Minerals",
               "Titanium-Ilmenite","Titanium, Metal","Titanium, Pigment",
               "Titanium-Rutile","Travertine","Tripoli","Tungsten",
               "Tungsten, Mill Concentrate","Tungsten, Refinery",
               "Vanadium","Vermiculite","Volcanic Materials",
               "Water, Free","Wollastonite","Yttrium","Zeolites","Zinc",
               "Zinc, Refiner","Zinc, Smelter","Zirconium")


#3. ADM1 --------------------------------------------------------------------
CRS_adm1  <- st_crs(ADM1)


minas_adm1 <- st_as_sf(minas,
                       coords = c("longitude", "latitude"),
                       crs = CRS_adm1)


sf::sf_use_s2(FALSE)

MinasADM1 <- minas_adm1 %>%
   st_join(ADM1,
           join = st_intersects, 
           left = TRUE) 

M1 <- MinasADM1 %>% 
   select(mrds_id, NAME_0, NAME_1, GID_0, GID_1) %>% 
   st_drop_geometry()

M2 <- MinasADM2 %>% 
   select(mrds_id, NAME_0, NAME_2, GID_0, GID_1, GID_2) %>%  
   st_drop_geometry()

plantas_adm1 <- anti_join(M1, M2)

MinasADM1_p <- semi_join(MinasADM1, plantas_adm1)

MinasADM1_prueba_1 <- MinasADM1_p %>%
   select(site_name, region, country, commod1, commod2, commod3, GID_0, NAME_0, 
          GID_1, NAME_1, geometry)
MinasADM1_prueba_1$commodities <- " "
MinasADM1_prueba_1<- MinasADM1_prueba_1[,c(1,2,3,4,5,6,12,7,8,9,10,11)]

for (i in 1:nrow(MinasADM1_prueba_1)){
   MinasADM1_prueba_1$commodities[i] <- paste(c(MinasADM1_prueba_1$commod1[i], 
                                                MinasADM1_prueba_1$commod2[i], 
                                                MinasADM1_prueba_1$commod3[i]), 
                                              collapse = " ,")
}

mines_gid1 <- MinasADM1_prueba_1 %>% 
   dplyr::select(1:12)

# Loop to create columns for each category

for (i in 1:length(categ_min)){
   mines_gid1[,categ_min[i]] <- ""
}

# Loop using str_detect on each row of the commodities column to create a 
# binary variable for technology minerals 
for (i in 1:nrow(mines_gid1)) {
   
   for(j in 1:length(tech_min)) {
      
      if(str_detect(mines_gid1$commodities[i],tech_min[j])){
         
         mines_gid1$tech_min[i] = 1
      }
   }
   
   if(mines_gid1$tech_min[i] == ""){
      mines_gid1$tech_min[i] = 0
   }
}

# Loop using str_detect on each row of the commodities column to create a 
# binary variable for energy minerals 
for (i in 1:nrow(mines_gid1)) {
   
   for(j in 1:length(energy_min)) {
      
      if(str_detect(mines_gid1$commodities[i],energy_min[j])){
         
         mines_gid1$energy_min[i] = 1
      }
   }
   
   if(mines_gid1$energy_min[i] == ""){
      mines_gid1$energy_min[i] = 0
   }
}

# Loop using str_detect on each row of the commodities column to create a 
# binary variable for precious minerals 
for (i in 1:nrow(mines_gid1)) {
   
   for(j in 1:length(precious_min)) {
      
      if(str_detect(mines_gid1$commodities[i],precious_min[j])){
         
         mines_gid1$precious_min[i] = 1
      }
   }
   
   if(mines_gid1$precious_min[i] == ""){
      mines_gid1$precious_min[i] = 0
   }
}

# Loop using str_detect on each row of the commodities column to create a 
# binary variable for other minerals 
for (i in 1:nrow(mines_gid1)) {
   
   for(j in 1:length(other_min)) {
      
      if(str_detect(mines_gid1$commodities[i],other_min[j])){
         
         mines_gid1$other_min[i] = 1
      }
   }
   
   if(mines_gid1$other_min[i] == ""){
      mines_gid1$other_min[i] = 0
   }
}

table_mines_gid1 <- mines_gid1 %>% 
   select(10, 13:16) %>% 
   st_drop_geometry() %>% 
   mutate_at(c(2:5), as.numeric) %>% 
   group_by(GID_1) %>% 
   summarise(across(.cols = c(1:4), sum)) %>% 
   mutate(sum_mins = select(., 2:5) %>% rowSums(na.rm = TRUE)) 

for(i in 1:nrow(table_mines_gid1)){
   if(table_mines_gid1$sum_mins[i] > 0){
      table_mines_gid1$min_deposit[i] = 1
   }
   
   if(table_mines_gid1$sum_mins[i] == 0){
      table_mines_gid1$min_deposit[i] = 0
   }
}

ADM1 <- ADM1 %>% 
   st_drop_geometry()

table_gid1 <- left_join(ADM1, table_mines_gid1) %>% 
   select(GID_1, min_deposit, tech_min, energy_min, precious_min, other_min) %>% 
   mutate_at(2:6, ~replace_na(.,0))

#4. ADM2 --------------------------------------------------------------------
CRS_adm2  <- st_crs(ADM2)


minas_adm2 <- st_as_sf(minas,
                       coords = c("longitude", "latitude"),
                       crs = CRS_adm2)


sf::sf_use_s2(FALSE)

MinasADM2 <- minas_adm2 %>%
   st_join(ADM2,
           join = st_intersects, 
           left = TRUE) 


MinasADM2_prueba_2 <- MinasADM2 %>% 
   select(site_name, region, country, commod1, commod2, commod3, GID_0, NAME_0, 
          GID_2, NAME_2, geometry)

MinasADM2_prueba_2$commodities <- " "
MinasADM2_prueba_2<- MinasADM2_prueba_2[,c(1,2,3,4,5,6,12,7,8,9,10,11)]

for (i in 1:nrow(MinasADM2_prueba_2)){
   MinasADM2_prueba_2$commodities[i] <- paste(c(MinasADM2_prueba_2$commod1[i], 
                                                MinasADM2_prueba_2$commod2[i], 
                                                MinasADM2_prueba_2$commod3[i]), 
                                              collapse = " ,")
}

mines_gid2 <- MinasADM2_prueba_2 %>% 
   dplyr::select(1:12)

# Loop to create columns for each category

for (i in 1:length(categ_min)){
   mines_gid2[,categ_min[i]] <- ""
}

# Loop using str_detect on each row of the commodities column to create a 
# binary variable for technology minerals 
for (i in 1:nrow(mines_gid2)) {
   
   for(j in 1:length(tech_min)) {
      
      if(str_detect(mines_gid2$commodities[i],tech_min[j])){
         
         mines_gid2$tech_min[i] = 1
      }
   }
   
   if(mines_gid2$tech_min[i] == ""){
      mines_gid2$tech_min[i] = 0
   }
}

# Loop using str_detect on each row of the commodities column to create a 
# binary variable for energy minerals 
for (i in 1:nrow(mines_gid2)) {
   
   for(j in 1:length(energy_min)) {
      
      if(str_detect(mines_gid2$commodities[i],energy_min[j])){
         
         mines_gid2$energy_min[i] = 1
      }
   }
   
   if(mines_gid2$energy_min[i] == ""){
      mines_gid2$energy_min[i] = 0
   }
}

# Loop using str_detect on each row of the commodities column to create a 
# binary variable for precious minerals 
for (i in 1:nrow(mines_gid2)) {
   
   for(j in 1:length(precious_min)) {
      
      if(str_detect(mines_gid2$commodities[i],precious_min[j])){
         
         mines_gid2$precious_min[i] = 1
      }
   }
   
   if(mines_gid2$precious_min[i] == ""){
      mines_gid2$precious_min[i] = 0
   }
}

# Loop using str_detect on each row of the commodities column to create a 
# binary variable for other minerals 
for (i in 1:nrow(mines_gid2)) {
   
   for(j in 1:length(other_min)) {
      
      if(str_detect(mines_gid2$commodities[i],other_min[j])){
         
         mines_gid2$other_min[i] = 1
      }
   }
   
   if(mines_gid2$other_min[i] == ""){
      mines_gid2$other_min[i] = 0
   }
}

table_mines_gid2 <- mines_gid2 %>% 
   select(10, 13:16) %>% 
   st_drop_geometry() %>% 
   mutate_at(c(2:5), as.numeric) %>% 
   group_by(GID_2) %>% 
   summarise(across(.cols = c(1:4), sum)) %>% 
   mutate(sum_mins = select(., 2:5) %>% rowSums(na.rm = TRUE)) 

for(i in 1:nrow(table_mines_gid2)){
   if(table_mines_gid2$sum_mins[i] > 0){
      table_mines_gid2$min_deposit[i] = 1
   }
   
   if(table_mines_gid2$sum_mins[i] == 0){
      table_mines_gid2$min_deposit[i] = 0
   }
}

ADM2 <- ADM2 %>% 
   st_drop_geometry()

table_gid2 <- left_join(ADM2, table_mines_gid2) %>% 
   select(GID_2, min_deposit, tech_min, energy_min, precious_min, other_min) %>% 
   mutate_at(2:6, ~replace_na(.,0))




