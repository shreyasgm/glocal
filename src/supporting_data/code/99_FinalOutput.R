# Merging outputs from variables into a dataset for each administrative level 


# Packages ----------------------------------------------------------------
library(rio)
library(tidyverse)

#1. ADM1  -------------------------------------------------------------------

# Merging datasets from variables into one dataset for ADM1
ds_adm1 <- reduce(list(ADM1_base, wadm1_comp, dist_popcentr_1, f_GID1,
                       ADM1_Ports, ADM1_Airports, table_gid1),
                     left_join, 
                     by = 'GID_1')

export(ds_adm1, '../data/clean/Dataset_ADM1.xlsx')

#2. ADM2 --------------------------------------------------------------------
ds_adm2 <- reduce(list(ADM2_base, wadm2_comp, dist_popcentr_2, f_GID2, 
                       ADM2_Ports, ADM2_Airports, table_gid2),
                  left_join, 
                  by = 'GID_1')

export(ds_adm2, '../data/clean/Dataset_ADM2.xlsx')

 