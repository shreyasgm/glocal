# Binary variable that assigns 1 if an administrative area has a land border 
# with other countries and 0 in the contrary. 


#1. Load packages -----------------------------------------------------------
library(sf)
library(tidyverse)

#2. ADM1  -------------------------------------------------------------------

#2.1 Identify the administrative areas that are neighbors 
sf::sf_use_s2(TRUE)
neighb <- st_touches(ADM1)

#2.2 Identify ADMs codes that differ at a GID_0 level (country level)

ADM1_base$vecinos <- ""
ADM1_base$vecinos <- as.list(ADM1_base$vecinos)

for(i in 1:nrow(neighb)){
   ADM1_base$vecinos[i] <- list(ADM1_base$GID_1[neighb[[i]]])
}


ADM1_base$vecinos2 <- ""
ADM1_base$vecinos2 <- as.integer(ADM1_base$vecinos2)

for(i in 1:nrow( ADM1_base)){
   pruebita <- c()
   if(!identical(ADM1_base$vecinos[[i]], character(0))){
      for(j in 1:length(ADM1_base$vecinos[[i]])){
         if(!str_detect( ADM1_base$vecinos[[i]][j], ADM1_base$GID_0[i])){
            pruebita <- append(pruebita,  ADM1_base$vecinos[[i]][j])
         }
      }
   }
   
#2.3  Create the dummy variable
   
   if(length(pruebita) > 0){
      ADM1_base$vecinos2[i] = 1  
   } else {
      ADM1_base$vecinos2[i] = 0
   }
}

ADM1_base <- ADM1_base %>% 
   select(-vecinos) %>% 
   rename("border" = vecinos2)
  
#3. ADM2 --------------------------------------------------------------------

#3.1 Identify the administrative areas that are neighbors 
sf::sf_use_s2(TRUE)
neighb_2 <- st_touches(ADM2)

#3.2 Identify ADMs codes that differ at a GID_0 level (country level)
ADM2_base$vecinos <- ""
ADM2_base$vecinos <- as.list(ADM2_base$vecinos)

for(i in 1:nrow(neighb_2)){
   ADM2_base$vecinos[i] <- list(ADM2_base$GID_2[neighb_2[[i]]])
}

ADM2_base$vecinos2 <- ""
ADM2_base$vecinos2 <- as.integer(ADM2_base$vecinos2)

for(i in 1:nrow(ADM2_base)){
   pruebita <- c()
   if(!identical(ADM2_base$vecinos[[i]], character(0))){
      for(j in 1:length(ADM2_base$vecinos[[i]])){
         if(!str_detect(ADM2_base$vecinos[[i]][j],ADM2_base$GID_0[i])){
            pruebita <- append(pruebita, ADM2_base$vecinos[[i]][j])
         }
      }
   }
   
#3.3  Create the dummy variable   
   if(length(pruebita) > 0){
      ADM2_base$vecinos2[i] = 1  
   } else {
      ADM2_base$vecinos2[i] = 0
   }
}

ADM2_base<- ADM2_base%>% 
   select(-vecinos) %>% 
   rename("border" = vecinos2)

