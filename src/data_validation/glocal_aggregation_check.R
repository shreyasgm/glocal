########### Glocal Aggregation Check
####
#### Function: Checks aggregation between administrative levels of Glocal data
#### and returns inconsistencies
####
#### Required packages: dplyr and stringr
####
#### Inputs: any number of Glocal Datasets, in the specified folder
####
#### Outputs: agg_check_GID_X_vs_GID_y.csv
#### 
#### Assumptions: presumes that the regional columns are in the same
#### Placement across aggregate files, and begin with "GID_"; assumes
#### other than "GID_X" variables, that variables are consistent across all
#### datasets

# Load packages
packages <-
  c("tidyverse",
    "arrow",
    "sf",
    "ggcorrplot",
    "here")
sapply(packages, library, character.only = T)

# Set working directory appropriately
# setwd("/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas")
here::i_am("data_validation/glocal_aggregation_check.R")
PROJ <- here("data_validation/")
ROOT <- here()
DATA <- here(ROOT, "data")
#-------------------------------------------------------------------
input_path <- here(DATA, "processed", "imagery_aggregations")

#Specify output path
output_path <- here(PROJ, "tables")

#Specify paths to supporting data to get areas
shape_path <- here(DATA, "processed", "supporting_data")

######
### IMPORTING
######

files <- c("annualized_level_0.parquet",
          "annualized_level_1.parquet",
          "annualized_level_2.parquet")

#files <- list.files(input_path)

aggregate <- NULL

#Creates a list with a data frame for each level
for(i in 1:length(files)){
  
  aggregate[[i]] <- arrow::read_parquet(here(input_path, files[i]))

}

#Creates shapefile calculations
shape0 <- read_parquet(here(shape_path,'supporting_data_level_0.parquet'))
shape1 <- arrow::read_parquet(here(shape_path,'supporting_data_level_1.parquet'))
shape2 <- arrow::read_parquet(here(shape_path,'supporting_data_level_2.parquet'))

#pulls GID_0 regions for GID_1 data
regions_key_1 <- data.frame(GID_0 = shape1$GID_0, 
                            GID_1 = shape1$GID_1)

#Pulls GID_1 regions for GID_2 data
regions_key_2 <- data.frame(GID_0 = shape2$GID_0, 
                            GID_1 = shape2$GID_1, 
                            GID_2 = shape2$GID_2)

zenames <- colnames(aggregate[[1]])[!(colnames(aggregate[[1]]) %in% c("GID_0","year"))]
onenames <- colnames(aggregate[[2]])[!(colnames(aggregate[[2]]) %in% c("GID_1","year"))]
twonames <- colnames(aggregate[[3]])[!(colnames(aggregate[[3]]) %in% c("GID_2","year"))]

#Adds in level 0 classification for level 1 and level 1 for level 2
aggregate[[2]] <- merge(aggregate[[2]], regions_key_1, by.x = "GID_1", by.y = "GID_1")
aggregate[[3]] <- merge(aggregate[[3]], regions_key_2, by.x = "GID_2", by.y = "GID_2")

#sorts data
aggregate[[1]] <- aggregate[[1]] %>% arrange(GID_0, year)
aggregate[[2]] <- aggregate[[2]] %>% arrange(GID_1, year)
aggregate[[3]] <- aggregate[[3]] %>% arrange(GID_2, year)

#Reorders columns so region and year are first
aggregate[[1]] <- aggregate[[1]][,c("GID_0","year",zenames)]
aggregate[[2]]<- aggregate[[2]][,c("GID_0","GID_1","year",onenames)]
aggregate[[3]] <- aggregate[[3]][,c("GID_0","GID_1","GID_2","year",twonames)]


#calculates areas for level 0 shapes, and adds them into levels 0, 1 and 2.
areas0 <- shape0 %>% select(GID_0, area_0 = area_sq_km)
aggregate[[1]] <- merge(aggregate[[1]], areas0, by.x = "GID_0", by.y = "GID_0")
aggregate[[2]] <- merge(aggregate[[2]], areas0, by.x = "GID_0", by.y = "GID_0")
aggregate[[3]] <- merge(aggregate[[3]], areas0, by.x = "GID_0", by.y = "GID_0")

#Calculates level 1 areas and adds this to levels 1 and 2
areas1 <- shape1 %>% select(GID_1, area_1 = area_sq_km)
aggregate[[2]] <- merge(aggregate[[2]], areas1, by.x = "GID_1", by.y = "GID_1")
aggregate[[3]] <- merge(aggregate[[3]], areas1, by.x = "GID_1", by.y = "GID_1")

#Calculates level 2 areas and adds to level 2
shape2$area <- st_area(shape2)
areas2 <- data.frame(GID_2 = shape2$GID_2, area_2 = shape2$area)
aggregate[[3]] <- merge(aggregate[[3]], areas2, by.x = "GID_2", by.y = "GID_2")

#Creates area proportions for levels 1 and 2
aggregate[[2]] <- aggregate[[2]] %>% mutate(prop_1 = area_1/area_0)
aggregate[[3]] <- aggregate[[3]] %>% mutate(prop_1 = area_1/area_0)
aggregate[[3]] <- aggregate[[3]] %>% mutate(prop_2 = area_2/area_1)

################################################################################

########################### PLEASE SPECIFY VARIABLES ###########################

################################################################################

#### Specify which columns to compare - default is all non-"GID_X" columns
#Variables are indexed to the higher level
# Default - all columns (comment out if specifying a subset)

prefix <- "GID_" #Note: Change if the region prefix changes from "GID_X"
vars <- colnames(aggregate[[1]])
vars <- vars[str_detect(vars, prefix, negate = TRUE) == TRUE]
vars <- vars[!(vars %in% c("year","month"))] #Boots off "year" and "month"


#Alternative - Specify a subset - please comment out of if using the above
#vars <- c("viirs_custom_mean")


#Specify which variables are means, medians, or geographically weighted averages.
#Unspecififed variables are treated as sums.

#Simple means
means <- NULL
meancheck <- vars %in% means

#Geographically weighted means
geo_means <- c("temperature","precipitation_gpcc", "precipitation_gpcp",
               "precipitation_cru", "viirs_custom_mean", "elevation",
               "population_density", "ruggedness", "forest_loss_mean",
               "time_to_cities_mins", "time_to_large_cities_mins",
               "time_to_medium_cities_mins", "time_to_ports_mins",
               "time_to_airports_mins", "urban_time_to_airports_mins",
               "urban_time_to_large_cities_mins",
               "urban_time_to_medium_cities_mins", "urban_time_to_ports_mins")        

geo_meanscheck <- vars %in% geo_means

#Medians
medians <- c("viirs_custom_median")
mediancheck <- vars %in% medians

#Exemptions - do not aggregate check these
exemptions <- c("area_0", "area_1", "area_2", "prop_1", "prop_2","landcover_DW_null")

# Default years - all years in first set (comment out if specifying a subset)
years <- unique(aggregate[[1]]$year)
years <- sort(years)

# Specify a subset (use for loop)
# years <- 1997:2021

for(i in 1:length(files)){
aggregate[[i]] <- aggregate[[i]] %>% filter(year %in% years)
}

################################################################################


######
###INDEXING
######


levels <- NULL
pos <- NULL

#Returns an index of the administrative levels present in the dataset by
#isolating all column names with "GID_" and taking the max value. Further
#Returns the location of the columns in each dataset.

for(i in 1:length(files)){
  
  cols <- colnames(aggregate[[i]])
  cols <- cols[str_detect(cols, prefix, negate = TRUE) == FALSE]
  cols <- str_remove_all(cols, prefix)
  cols <- as.double(cols)
  levels <- c(levels, max(cols))
  pos <- c(pos, match(paste0(prefix,max(cols)), colnames(aggregate[[i]])))
  
}


######
###Aggregation Check
######

#Initializes Data set
discreps <- NULL
areas <- c("area_0", "area_1","area_2")
props <- c("prop_1","prop_2")
### The following loop compares two Glocal data sets against each other - 
# it aggregates the lower of the two files (more specific) based on the most
# specific region of the higher of the two files (less specific), and then
# subtracts the lower aggregate from the higher. For instance, for GID_1 and GID_2,
# it would sum each variable present in the GID_2 data set based off of GID_1 
# regions, and then minuses each variable in GID_1 by GID_2. If the remaining
# value is zero, aggregation is perfect - if positive, then it represents the
# amount of data unaccounted for in the lower regions, and if negative, represents
# the amount that is lost in aggregation.

for(i in 1:(length(files)-1)){ #Creates column names and indices for the comparison
lev <- colnames(aggregate[[i]])
lev <- lev[str_detect(lev, prefix, negate = TRUE) == FALSE]
fronts <- length(lev)+1 #Pulls number of front matter columns - GID_X + year
lev <- sort(lev)
lev <- lev[length(lev)] #Pulls most specific level from data frame

#adds in the higher level's regions
discreps[[i]] <- aggregate[[i]] %>% select(all_of(1:fronts))

#adds in a merge column, 'regyear' which is the region + the year
discreps[[i]] <- discreps[[i]] %>% mutate(regyear = paste0(!!as.name(lev), year))


for(j in 1:length(vars)){

#aggregates by variable type - if not mean, geographic mean or median, then it is summed
lower <- if(meancheck[j] == TRUE){aggregate[[i+1]] %>% 
    group_by(!!as.name(lev), year) %>% 
    summarise(count = mean(!!as.name(vars[j]), na.rm = TRUE), .groups = "keep")} else if(
      mediancheck[j] == TRUE){aggregate[[i+1]] %>% 
          group_by(!!as.name(lev), year) %>% 
          summarise(count = median(!!as.name(vars[j]), na.rm = TRUE), .groups = "keep")} else if(
            geo_meanscheck[j] == TRUE){aggregate[[i+1]] %>% 
                group_by(!!as.name(lev), year) %>% 
                summarise(count = sum(!!as.name(vars[j])*!!as.name(props[i]), na.rm = TRUE), .groups = "keep")} else{aggregate[[i+1]] %>% 
              group_by(!!as.name(lev), year) %>%
              summarise(count = sum(!!as.name(vars[j]), na.rm = TRUE), .groups = "keep")}

#adds in regyear merge column
lower <- lower %>% mutate(regyear = paste0(!!as.name(lev), year))

#copies directly the higher level data to compare against, and adds regyear
upper <- aggregate[[i]] %>% select(all_of(1:fronts), !!as.name(vars[j]))
upper <- upper %>% mutate(regyear = paste0(!!as.name(lev), year))

#merges datasets
merged <- merge(upper, lower, by = "regyear", all = TRUE)
merged <- units::drop_units(merged)
merged[,vars[j]] <- replace_na(merged[,vars[j]], 0)
merged$count <- replace_na(merged$count, 0)
merged <- merged %>% mutate(diff = !!as.name(vars[j]) - count)
merged <- merged %>% mutate(share = ifelse(is.nan(diff/!!as.name(vars[j])),
                                           0,
                                           diff/!!as.name(vars[j])))
merged <- merged %>% select(regyear, diff, share)
colnames(merged)[2] <- paste0("count_",vars[j])
colnames(merged)[3] <- paste0("share_",vars[j])

#merges the merge column with the discrepancies master sheet
discreps[[i]] <- merge(discreps[[i]], merged, by = "regyear", all = TRUE)
}
}

#####
###Regional Consistency
#####

#This section removes regions that are not present in a lower level - i.e.
#Removes regions without sublevel 2 data from sublevel 1 aggregations.

####NOTE - THIS IS NOT MODULARIZED YET - ONLY WORKS IF FILES = adm_lev 0, 1 & 2####

#Compiles list of level 0 names in level 0.csv
ry0 <- aggregate[[1]] %>% 
  mutate(regyear = paste0(GID_0, year)) %>% 
  select(regyear) %>% 
  count(regyear) %>% 
  select(regyear) %>% 
  as.vector()
ry0 <- ry0[[1]] #strips list formatting

#Compiles list of level 0 names in level 1.csv
ry1 <- aggregate[[2]] %>%
  mutate(regyear = paste0(GID_0, year)) %>%
  select(regyear) %>%
  count(regyear) %>%
  select(regyear) %>%
  as.vector()
ry1 <- ry1[[1]] #strips list formatting

#Compiles list of level 0 names in level 2.csv
ry2 <- aggregate[[3]] %>%
  mutate(regyear = paste0(GID_0, year)) %>%
  select(regyear) %>%
  count(regyear) %>%
  select(regyear) %>%
  as.vector()
ry2 <- ry2[[1]] #strips list formatting


#Compiles list of level 1 names in level 1.csv
ry_1 <- aggregate[[2]] %>%
  mutate(regyear = paste0(GID_1, year)) %>%
  select(regyear) %>%
  count(regyear) %>%
  select(regyear) %>%
  as.vector()
ry_1 <- ry_1[[1]] #strips list formatting

#Compiles list of level 1 names in level 2.csv
ry_2 <- aggregate[[3]] %>%
  mutate(regyear = paste0(GID_1, year)) %>%
  select(regyear) %>%
  count(regyear) %>%
  select(regyear) %>%
  as.vector()
ry_2 <- ry_2[[1]] #strips list formatting

#Compiles exceptions
zero_in_zero_not_one <- ry0[!(ry0 %in% ry1)]
zero_in_one_not_two <- ry1[!(ry1 %in% ry2)]
one_in_one_not_two <- ry_1[!(ry_1 %in% ry_2)]

#filters out exceptions
discreps[[1]] <- discreps[[1]] %>% filter(!(regyear %in% zero_in_zero_not_one))
discreps[[2]] <- discreps[[2]] %>% filter(!(regyear %in% one_in_one_not_two))


#Writes .csvs for each comparison
for(i in 1:(length(files)-1)){
  
write_csv(discreps[[i]],here(output_path,"agg_check_GID_",i-1,"_","_vs_GID_",i,".csv"))
  
}

