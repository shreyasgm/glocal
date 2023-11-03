# Binary variable that assigns 1 if an administrative area has a gas flare 
# and 0 in the contrary. 


# Load packages -----------------------------------------------------------
library(dplyr)
library(sf)

# Load data ---------------------------------------------------------------

GADM1 <- ADM1 

GADM2 <- ADM2

#2.1 Loading every flare file

shplist <- list.files(path = "G:/.shortcut-targets-by-id/12VQ5dQlqDB7i3rWB_L2mcatCfv502hnT/research/13_GasFlares/data/raw", pattern='.shp$', 
                      all.files=TRUE, full.names=TRUE)

#2.2 Reading every file using st_read
allshp <- lapply(shplist, st_read)

shp_flares <- data.frame()

#2.3 Loop to merge files into one dataframe

for(i in 1:length(allshp)){
   
   shp_flares <- rbind(shp_flares, allshp[[i]])
}

# ADM1 --------------------------------------------------------------------

# Spatial match between GID1 level and flares  

sf::sf_use_s2(FALSE)

flares_GID1 <- shp_flares %>%
   st_join(GADM1,
           join = st_intersects,
           left = TRUE) 

flares_GID1 <- flares_GID1 %>% 
   select(GID_0, GID_1, NAME_1, geometry) %>% 
   na.omit() %>% 
   st_drop_geometry()

flares_GID1$flare <- 1

flares_GID1 <- flares_GID1 %>% 
   unique()

G_ADM1 <- GADM1 %>% 
   st_drop_geometry()

f_GID1 <- left_join(G_ADM1, flares_GID1, by = c("GID_1", "NAME_1"))


compareNA <- function(v1, v2) #This function treats NAs as values when comparing elementwise
{
   same <- (v1 == v2) | (is.na(v1) & is.na(v2))
   same[is.na(same)] <- FALSE
   return(same)
}

for(i in 1:nrow(f_GID1)){
   f_GID1$flare[i] <- if_else(compareNA(f_GID1$flare[i],1), 1, 0)
}

f_GID1 <- f_GID1 %>% 
   select(GID_1, flare)


# ADM2 --------------------------------------------------------------------

sf::sf_use_s2(FALSE)

flares_GID2 <- shp_flares %>%
   st_join(GADM2,
           join = st_intersects,
           left = TRUE) 

flares_GID2 <- flares_GID2 %>% 
   select(GID_0, GID_2, NAME_2) %>% 
   na.omit() %>% 
   st_drop_geometry()

flares_GID2$flare <- 1

flares_GID2 <- flares_GID2 %>% 
   unique()

G_ADM2 <- GADM2 %>% 
   st_drop_geometry()

f_GID2 <- left_join(G_ADM2, flares_GID2, by = c("GID_2", "NAME_2"))


compareNA <- function(v1, v2) 
{
   same <- (v1 == v2) | (is.na(v1) & is.na(v2))
   same[is.na(same)] <- FALSE
   return(same)
}

for(i in 1:nrow(f_GID2)){
   f_GID2$flare[i] <- if_else(compareNA(f_GID2$flare[i],1), 1, 0)
}

f_GID2 <- f_GID2 %>% 
   select(GID_2, flare)
