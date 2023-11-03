########### Glocal Structural Continuity Check
####
#### Function: First checks for missing rows for regions - i.e. years in which 
#### a region does not have an observation. Then, compares all Glocal data sets
#### pairwise for consistency of regions between administrative levels,
#### returning regions present in one level and missing in a lower file.
####
#### Required packages: tidyverse, here, arrow, lubridate
####
#### Inputs: any number of Glocal Datasets
####
#### Outputs: temporal continuity checks and missing region checks.

#Finds uninstalled packages and installs them
list.of.packages <- c("tidyverse", "here", "arrow","lubridate")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages) != 0){install.packages(new.packages)} else{}

#Calling necessary packages
library(tidyverse)
library(here)
library(arrow)
library(lubridate)
setwd(here())

################################################################################

############################# PLEASE SPECIFY PATHS #############################

################################################################################

#Specify file with data
input_path <- '../Data'

#creates output paths

dir.create(file.path(paste0('../Outputs/Regional_Continuity_Report_', Sys.Date())),
           showWarnings = FALSE)

dir.create(file.path(paste0('../Outputs/Regional_Continuity_Report_', Sys.Date(),
                            "/Temporal_Continuity")),showWarnings = FALSE)

dir.create(file.path(paste0('../Outputs/Regional_Continuity_Report_', Sys.Date(),
                            "/Missing_Regions")),showWarnings = FALSE)

output_path <- paste0('../Outputs/Regional_Continuity_Report_', Sys.Date())

################################################################################

######
### IMPORTING
######

#NOTE - please use on option below and comment out the other

#To compare all files in "Data" (note - will break if files like "dictionary" are included)
#files <- list.files(input_path)

#To compare a select subset of data sets
files <- c("annualized_level_0.csv", 
           "annualized_level_1.csv",
           "annualized_level_2.csv",
           "monthly_level_0.parquet", 
           "monthly_level_1.parquet",
           "monthly_level_2.parquet")

#Initializes length and file repositories.
length <- 1:length(files)
aggregate <- NULL

#Creates a list with a data frame for each level
for(i in length){
if(tools::file_ext(files[i]) == "csv"){
aggregate[[i]] <- read.csv(paste0(input_path,"/", files[i]))} else{
aggregate[[i]] <- read_parquet(paste0(input_path,"/", files[i]))}
aggregate[[i]] <- if("month" %in% colnames(aggregate[[i]])) {
  aggregate[[i]] %>% mutate(ym = make_date(year,month))} else {
    aggregate[[i]]}
}

#######
###LABELING
#######
#This section pulls names off of shapefiles for the higher level regions.

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
zenamesm <- colnames(aggregate[[4]])[!(colnames(aggregate[[4]]) %in% c("GID_0","year","month"))]
onenamesm <- colnames(aggregate[[5]])[!(colnames(aggregate[[5]]) %in% c("GID_1","year","month"))]
twonamesm <- colnames(aggregate[[3]])[!(colnames(aggregate[[3]]) %in% c("GID_2","year","month"))]

#Adds in level 0 classification for level 1 and level 1 for level 2
aggregate[[2]] <- merge(aggregate[[2]], regions_key_1, by.x = "GID_1", by.y = "GID_1")
aggregate[[3]] <- merge(aggregate[[3]], regions_key_2, by.x = "GID_2", by.y = "GID_2")
aggregate[[5]] <- merge(aggregate[[5]], regions_key_1, by.x = "GID_1", by.y = "GID_1")
aggregate[[6]] <- merge(aggregate[[6]], regions_key_2, by.x = "GID_2", by.y = "GID_2")

#sorts data
aggregate[[1]] <- aggregate[[1]] %>% arrange(GID_0, year)
aggregate[[2]] <- aggregate[[2]] %>% arrange(GID_1, year)
aggregate[[3]] <- aggregate[[3]] %>% arrange(GID_2, year)
aggregate[[4]] <- aggregate[[4]] %>% arrange(GID_0, year, month)
aggregate[[5]] <- aggregate[[5]] %>% arrange(GID_1, year, month)
aggregate[[6]] <- aggregate[[6]] %>% arrange(GID_2, year, month)

#Reorders columns so region and year are first
aggregate[[1]] <- aggregate[[1]][,c("GID_0","year",zenames)]
aggregate[[2]]<- aggregate[[2]][,c("GID_0","GID_1","year",onenames)]
aggregate[[3]] <- aggregate[[3]][,c("GID_0","GID_1","GID_2","year",twonames)]
aggregate[[4]] <- aggregate[[4]][,c("GID_0","year","month",zenamesm)]
aggregate[[5]]<- aggregate[[5]][,c("GID_0","GID_1","year","month",onenamesm)]
aggregate[[6]] <- aggregate[[6]][,c("GID_0","GID_1","GID_2","year","month",twonamesm)]



######
###INDEXING
######

prefix <- "GID_" #Note: Change if the region prefix changes from "GID_"
levels <- NULL
pos <- NULL
timespecs <- NULL
levnames <- NULL
#Returns an index of the administrative levels present in the dataset by
#isolating all column names with "GID_" and taking the max value. Further
#Returns the location of the columns in each dataset.

for(i in length){
cols <- colnames(aggregate[[i]])
cols <- cols[str_detect(cols, prefix, negate = TRUE) == FALSE]
cols <- str_remove_all(cols, prefix)
cols <- as.double(cols)
timespecs <- c(timespecs, if("month" %in% colnames(aggregate[[i]])){'monthly'} else{"yearly"})
levels <- c(levels, max(cols))
levnames <- c(levnames, paste0(max(cols),if(timespecs[i] == "monthly"){"m"}else{"y"}))
pos <- c(pos, match(paste0(prefix,max(cols)), colnames(aggregate[[i]])))
}



##############################################################
#######          REGIONAL TEMPORAL CONTINUITY          #######
##############################################################
#Generates a list of regions 
reg_complete <- NULL

for(i in length){

timespec <- if("month" %in% colnames(aggregate[[i]])){'ym'} else{"year"}



bounds <- aggregate[[i]] %>% summarise(min = min(!!as.name(timespec)),
                                            max = max(!!as.name(timespec)))
bounds <- bounds$min:bounds$max
bounds <- if(timespec == "ym"){as.Date(bounds, origin = "1970-01-10")} else{bounds}

bounds <- if(timespec == "ym"){
  data.frame(time = bounds) %>% filter(day(time) == 1) %>% as.vector()} else{
    bounds}

bounds <- if(timespec == "ym"){ #strips list formatting
  bounds$time} else{
    bounds}

regions <- unique(aggregate[[i]][,pos[i]]) %>% as.vector()
regions <- if(length(regions) == 1){regions[[1]]} else{regions}

missings <- NULL
miss_totals <- NULL
miss_shares <- NULL

for(j in 1:length(regions)){

present <- aggregate[[i]] %>%
    filter(!!as.name(colnames(aggregate[[i]])[pos[i]]) == regions[j]) %>%
    select(timespec) %>%
    unique() %>%
    as.vector()
present <- present[[1]] #strips list format

zero_flag <- identical(bounds[!(bounds %in% present)], integer(0))

missing <- if(zero_flag == TRUE){0} else{
  bounds[!(bounds %in% present)]}
miss_total <- if(zero_flag == TRUE){0} else{length(missing)}
miss_share <- if(zero_flag == TRUE){0} else{miss_total/length(bounds)}


missings <- c(missings, paste(missing, collapse = " "))
miss_totals <- c(miss_totals, miss_total)
miss_shares <- c(miss_shares, miss_share)
}


reg_complete[[i]] <- data.frame(
           region = regions,
           missing_count = miss_totals,
           missing_share = miss_shares,
           missing = missings)
}


for(i in length){
write.csv(reg_complete[[i]], 
          file = paste0(output_path, "/Temporal_Continuity", "/level_",
          levels[i],"_", timespecs[[i]],"_regional_continuity_report.csv"))
  }



##############################################################
#######             ENTIRELY MISSING REGIONS           #######
##############################################################

#Creates a list of regions entirely excluded from one data set to the next.

#Initializes vector of missing variables
missing_reg <- NULL

#Compares all region names in one level against all other levels. In the event
#That it is comparing a lower level with a higher level, it will return any 
#missing regions from the administrative level of the higher file - i.e. if
#it compares level_2.csv with level_0.csv, it will return GID_0 regions in
#level_2.csv but not level_0.csv as there are no GID_2 regions in level_0.csv

for(i in length){

seq <- length[!length %in% i]

for(j in seq){
  
it <- match(j, seq)
itt <- (length(seq) * (i-1))+it

regs1 <- if(levels[j] > levels[i]){unique(aggregate[[i]][,pos[i]])} else{
                                   unique(aggregate[[i]][,pos[j]])}
regs1 <- if(length(regs1) == 1){regs1[[1]]} else{regs1}


regs2 <- if(levels[j] > levels[i]){unique(aggregate[[j]][,pos[i]])}else{
                                   unique(aggregate[[j]][,pos[j]]) %>% as.vector()}
regs2 <- if(length(regs2) == 1){regs2[[1]]} else{regs2}

missing_reg[[itt]] <- if(identical(regs1[!regs1 %in% regs2], character(0))){NA} else{regs1[!regs1 %in% regs2]}

}
}

names <- NULL

#Creates a vector of column names for each of the comparisons
for(i in length){

seq <- length[!length %in% i]
  
for(j in seq){

names <- c(names, paste0("in_",levnames[i],"_not_",levnames[j]))

}
}


#Finds the longest set of missing values to make the data set rectangular
except_lengths <- NULL

for(i in 1:length(missing_reg)){

except_lengths <- c(except_lengths, length(missing_reg[[i]])) 
  
}

max_size <- max(except_lengths)


#Makes the data set rectangular by adding NA's to all shorter lists
for(i in 1:length(missing_reg)){
length(missing_reg[[i]]) <- max_size  
}


exceptions <- NULL

#Converts the list into a matrix
for(i in 1:length(missing_reg)){
  
exceptions <- cbind(exceptions, missing_reg[[i]])
  
}

#converts the matrix into a dataframe
exceptions <- as.data.frame(exceptions)

#Applies column names
colnames(exceptions) <- names

write.csv(exceptions, paste0(output_path,'/Missing_Regions/Missing_Regions.csv'), row.names = FALSE)

#### The output reports a table containing any regions present in one data
#### set and absent in a lower level. For instance, if region "GG" is present
#### in GID_0 for annualized_level_0.csv but absent in GID_0 in
#### annualized_level_1.csv, it will return "GG" in the "in_0_not_1" column. If
#### "GG" is present in the GID_0 field for level_1.csv but not level_0.csv, it
#### will return "GG" in the "in_1_not_0" field.