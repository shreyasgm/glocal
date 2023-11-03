########### Glocal Data Integrity Check
####
#### Function: Provides basic summary statistics and integrity for a variable
#### in a specified Glocal aggregation level
####
#### Required packages: tidyverse, stringr, moments, arrow, lubridate, here
####
#### Inputs: any Glocal Dataset (singular), specified variable
####
#### Outputs: [variable name]_integrity_report.pdf
#### 

#Checks if packages are installed and installs them if not
list.of.packages <- c("tidyverse","stringr","moments","arrow","lubridate","here")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages) != 0){install.packages(new.packages)} else{}


#Calling necessary packages
library(tidyverse)
library(stringr)
library(moments)
library(arrow)
library(lubridate)
library(here)
setwd(here())

################################################################################

########################### PLEASE SPECIFY VARIABLES ###########################

################################################################################


##### Specify the file to analyze the variable within #####
date <- read.csv('../Data/annualized_level_0.csv')

##### Specify the variable you wish to analyze #####
#NOTE: Please make sure the option not being used is commented out

#Option 1 - specify variables manually
#vars <- c("viirs_sum", "gdelt_coercion","fao_crop_production_yield")

#Option 2 - analyze all variables except those in `excludes`
excludes <- c("GID_0", "GID_1", "GID_2", "year", "month", "landcover_DW_null")
vars <- colnames(dat)[!(colnames(dat) %in% excludes)]

###### Specify output path root #####

output_root <- '../Outputs'

output_path <- NULL


### Creates output paths for each variable report
for(i in 1:length(vars)){
output_path[[i]] <- paste0(output_root,'/Report_', Sys.Date(),"_",vars[i])
}


### Creates folders for completeness visualizations and analysis data
for(i in 1:length(vars)){
  dir.create(file.path(paste0(output_path[[i]])),showWarnings = FALSE)
  dir.create(file.path(paste0(output_path[[i]],"/Completeness_PNGs/")),showWarnings = FALSE)
  dir.create(file.path(paste0(output_path[[i]],'/Completeness_PNGS/Year_Totals')),showWarnings = FALSE)
  dir.create(file.path(paste0(output_path[[i]],'/Completeness_PNGS/Country_Totals')),showWarnings = FALSE)
  dir.create(file.path(paste0(output_path[[i]],'/Analysis_Data')),showWarnings = FALSE)
  }

################################################################################

######
### IMPORTING
######

###NOTE: if any level of specificity beyond GID_2 or month is added, this needs
#to be updated

analysis.columns <- c("GID_0","GID_1","GID_2","year","month", vars)
dat <- dat[,colnames(dat) %in% analysis.columns] #data with year
anavar <- dat[,colnames(dat) %in% vars] %>% as.data.frame() #analysis variables only
if(length(anavar) == 1){colnames(anavar) <- vars[1]} else{} #re-adds name for single variables

#NOTE: More sophisticated work around needed if any other time fields than
#month or year are added


### adds a year-month field
dat <- if("month" %in% colnames(dat)) {dat %>% mutate(ym = make_date(year,month))} else {dat}

### specifies the level of specificity for time and space
timespec <- if("month" %in% colnames(dat)) {"ym"} else ("year")
timename <- if(timespec == "year"){"yearly"} else{"monthly"}
spatialspec <- colnames(dat)[str_detect(colnames(dat),"GID_")] %>% 
  sort() %>%
  tail(1)

#Excludes the listed regions

#Normally bugged regions
reg_exclude <- c("GG", "YI","US", "RB", "Not Available")

#Bugged regions + 90 GID_0 regions with no GID_1/GID_2 sub-data


reg_exclude <- c(reg_exclude, n_z_o_t, n_z_z_o)
#reg_exclude <- c("GG", "YI","US", "RB", "Not Available", 
#                 "ABW", "AIA", "ALA", "ASM", "ATA", "ATF", 
#                 "BES", "BHR", "BHS", "BLM", "BVT", "CCK", 
#                 "COG", "COK", "COM", "CUW", "CXR", "DMA", 
#                 "FLK", "GIB", "GUM", "HMD", "IOT", "ISR", 
#                 "JEY", "KIR", "LCA", "LSO", "MAF", "MCO", 
#                 "MDV", "MHL", "MKD", "MMR", "MNE", "MNP", 
#                 "MYT", "NFK", "NIU", "PCN", "PLW", "PRI", 
#                 "SGP", "SGS", "SPM", "SXM", "SYC", "TCA", 
#                 "TON", "TTO", "UMI", "VAT", "VGB", "WLF", 
#                 "XAD", "XCA", "XCL", "XNC", "XPI", "XSP")

  
  
regions <- dat$GID_0 %>% unique() %>% as.vector()
regions <- regions[!(regions %in% reg_exclude)]
regions <- sort(regions) #Alphabetizes

#####
### METADATA
#####
#Check dictionary.csv for field completion for Units, Source and License.
#Returns the entries for these inputs if they are available, flags them if not.

dictionary <- read.csv("../Data/dictionary.csv", header = TRUE)

metadata <- NULL
for(i in 1:length(vars)){

metacheck <- data.frame(metadata = c("Units","Source","License"),
                        status = rep(FALSE,3),
                        entry = rep(NA,3))

varrow <- dictionary[str_detect(dictionary$Variables, vars[i]),]
if(nrow(varrow) > 1){varrow <- varrow[1,]} else{}

metacheck$status[1] <- !is.na(varrow$Measured.Variable...Units[1])
if(metacheck$status[1]){
  metacheck$entry[1] <- varrow$Measured.Variable...Units[1]} else{}

metacheck$status[2] <- !is.na(varrow$Source[1])
if(metacheck$status[2]){
  metacheck$entry[2] <- varrow$Source[1]} else{}

metacheck$status[3] <- !is.na(varrow$License[1])
if(metacheck$status[3]){
  metacheck$entry[3] <- varrow$License[1]} else{}

metadata[[i]] <- metacheck
}

#####
### ANALYSIS - SUMMARY STATISTICS
#####

###simple summaries

#Initializes basic summaries
basic_summary <- NULL

#Runs a simple report for each variable, manually running SD and skewness
for(i in 1:length(anavar)){

add <- anavar[,i] %>% summary()

sd <- data.frame(SD = sd(anavar[,i], na.rm = TRUE))

skew <- data.frame(skew = skewness(anavar[,i], na.rm = TRUE))
  
add <- c(add,sd,skew) %>% as.data.frame()

basic_summary[[i]] <- add[,c(1,2,3,4,8,9,5,6,7)]

}









#####
### TEMPORAL INTEGRITY
#####
#This area checks for NA values between the first NA value and the last 
#NA value (i.e. the time-frame the data is available). It aggregates the
#Percentage of NA values.

#Discovers the availability period of the data based off the first and last
#non-NA value and saves it as a date range

bounds <- NULL

for(i in 1:length(vars)){

bounds[[i]] <- dat %>% filter(
          !is.na(
            !!as.name(
              vars[i]
              ))) %>%
    summarise(min = min(!!as.name(timespec)), max = max(!!as.name(timespec)))

bounds[[i]] <- bounds[[i]][1,1]:bounds[[i]][1,2]
bounds[[i]] <- if(timespec == "ym"){as.Date(bounds[[i]], origin = "1970-01-10")} else{bounds[[i]]}
}  

#If data is monthly, removes all dates not the first day of the month from
#bounding date range (Lubridate does not save ranges by date)

for(i in 1:length(bounds)){
bounds[[i]] <- if(timespec == "ym"){
  data.frame(time = bounds[[i]]) %>% filter(day(time) == 1) %>% as.vector()} else{
    bounds[[i]]}

bounds[[i]] <- if(timespec == "ym"){ #removes "time" column name
bounds[[i]]$time} else{
    bounds[[i]]}

}  

#Removes NA rows before the first non-NA observation and after the last non-NA
#observation for the variable

dat_bounded <- NULL
anavar_bounded <- NULL

for(i in 1:length(vars)){

dat_bounded[[i]] <- dat %>%
  filter(!!as.name(timespec) %in% as.Date(bounds[[i]], origin = "1970-01-01")) 

anavar_bounded[[i]] <- dat_bounded[[i]][,colnames(dat_bounded[[i]] %in% vars)]

}

#Runs a density plot for each variable to show distribution. Filters NAs.

rawdat <- NULL 

for(i in 1:length(vars)){

setwd(here())
setwd(output_path[[i]])
  
rawdat[[i]] <- dat_bounded[[i]][colnames(dat_bounded[[i]]) == vars[i]] %>%
  filter(!is.na(!!as.name(vars[i])))
  
ggplot(rawdat[[i]]) + geom_density(aes(!!as.name(vars[i]))) +
  ggtitle(paste0("Distribution Plot for `",vars[i],"` in ",spatialspec, ", ", timename)) +
  labs(caption = paste0("Report run ", Sys.Date())) +
  theme(plot.title = element_text(hjust = .5), plot.caption = element_text(hjust = .5))

ggsave("./Analysis_Data/Distribution.png")
}

setwd(here())

#Calculates the amount of observations of each time period that are not NA
#within the availability area.

complete_share <- NULL

for(i in 1:length(vars)){

complete_share[[i]] <- data.frame(time = bounds[[i]], complete_share = 0)  

for(j in 1:length(bounds[[i]])){
  
denom <- dat_bounded[[i]] %>% 
    select(!!as.name(spatialspec), 
           !!as.name(timespec), 
           !!as.name(vars[i])) %>%
    filter(!!as.name(timespec) == bounds[[i]][j]) %>%
    nrow()
  
numer <- dat_bounded[[i]] %>% 
  select(!!as.name(spatialspec), 
         !!as.name(timespec), 
         !!as.name(vars[i])) %>%
  filter(!!as.name(timespec) == bounds[[i]][j]) %>%
  filter(!is.na(!!as.name(vars[i]))) %>%
  nrow()

complete_share[[i]][j,2] <- if(is.nan(numer/denom)){0}else{numer/denom}

}
}


#Runs a bar plot that shows the share of each year that is not NA.

for(i in 1:length(vars)){
  
  setwd(here())
  setwd(output_path[[i]])

  ggplot(complete_share[[i]], aes(time)) + geom_bar(aes(weight = complete_share)) +
    ggtitle(paste0("Yearly Completeness for `",vars[i],"` in ",spatialspec, ", ", timename)) +
    labs(caption = paste0("Report run ", Sys.Date())) +
    theme(plot.title = element_text(hjust = .5), plot.caption = element_text(hjust = .5))
  
  ggsave("./Analysis_Data/Yearly_Completeness.png")
}


#Creates a yearly value for the availability period (relevant if data is in
#month format)

year_bound <- NULL

for(i in 1:length(vars)){
year_bound[[i]] <- dat_bounded[[i]]$year %>% unique()
}

reg_completeness <- NULL
reg_year_share <- NULL

#Calculates the share of available data in each region for the availability period-
#showing how much of a variable for a given region is not NA.

for(i in 1:length(vars)){

    
reg_completeness[[i]] <- data.frame(region = rep(regions, length(year_bound[[i]])))

reg_completeness[[i]] <- reg_completeness[[i]] %>% arrange(region)

reg_completeness[[i]] <- cbind(reg_completeness[[i]],
                               data.frame(year = rep(year_bound[[i]], length(regions)), 
                               complete_share = 0))



for(k in 1:length(regions)){
  
for(j in 1:length(year_bound[[i]])){

  denom <- dat_bounded[[i]] %>%
           filter(year == year_bound[[i]][j] &
                  GID_0 == regions[k]) %>%
           nrow()
  
  numer <- dat_bounded[[i]] %>%
           filter(year == year_bound[[i]][j] &
                  GID_0 == regions[k] &
                  !is.na(!!as.name(vars[i]))) %>%
           nrow()
    
  reg_completeness[[i]][j + ((k-1)*length(year_bound[[i]])),3] <- if(is.nan(numer/denom)){0}else{numer/denom}
  

}
}
}

#Runs a bar plot that shows the share of each region that is not NA for the availability
#Period.

  for(i in 1:length(vars)){
    
    reg_year_share[[i]] <- data.frame(region = regions, year_share = 0)
    
    for(j in 1:length(regions)){
      
  denom <- length(year_bound[[i]])
  numer <- reg_completeness[[i]] %>%
            filter(region == regions[j]) %>%
            summarise(sum = sum(complete_share)) %>% as.vector()

      reg_year_share[[i]][j,2] <- if(is.nan(numer[[1]][1]/denom)){0} else{numer[[1]][1]/denom}   
 
}
}

#Stratifies region names into categories for completeness- zero, zero to .25,
#.25 - .5, .5 - .75, and .75 - 1, and full

regs_zero_comp <- NULL
regs_q1_comp <- NULL
regs_q2_comp <- NULL
regs_q3_comp <- NULL
regs_q4_comp <- NULL
regs_total_comp <- NULL
regs_comp_summary <- NULL

for(i in 1:length(vars)){

  regs_zero_comp[[i]] <- reg_year_share[[i]] %>% 
                         filter(year_share == 0) %>%
                         select(region) %>%
                         as.vector()
  regs_zero_comp[[i]]  <- regs_zero_comp[[i]][[1]]
  
  regs_q1_comp[[i]] <- reg_year_share[[i]] %>% 
                       filter(between(year_share,0.0001,.25)) %>%
                       select(region) %>%
                       as.vector()
  regs_q1_comp[[i]]  <- regs_q1_comp[[i]][[1]]
  
  regs_q2_comp[[i]] <- reg_year_share[[i]] %>% 
                       filter(between(year_share,.250001,.5)) %>%
                       select(region) %>%
                       as.vector()
  regs_q2_comp[[i]]  <- regs_q2_comp[[i]][[1]]

  regs_q3_comp[[i]] <- reg_year_share[[i]] %>% 
                       filter(between(year_share,.50001,.75)) %>%
                       select(region) %>%
                       as.vector()
  regs_q3_comp[[i]]  <- regs_q3_comp[[i]][[1]]

  regs_q4_comp[[i]] <- reg_year_share[[i]] %>% 
                       filter(between(year_share,.750001,.9999)) %>%
                       select(region) %>%
                       as.vector()
  regs_q4_comp[[i]]  <- regs_q4_comp[[i]][[1]]
  
  regs_total_comp[[i]] <- reg_year_share[[i]] %>% 
                          filter(year_share == 1) %>%
                          select(region) %>%
                          as.vector()
  regs_total_comp[[i]]  <- regs_total_comp[[i]][[1]]
  
  regs_comp_summary[[i]] <- data.frame(
                            level = c("zero", "0-.25", ".25-.5",
                                      ".5-.75", ".75-1", "full"),
                            counts = c(regs_zero_comp[[i]] %>% length(),
                                       regs_q1_comp[[i]] %>% length(),
                                       regs_q2_comp[[i]] %>% length(),
                                       regs_q3_comp[[i]] %>% length(),
                                       regs_q4_comp[[i]] %>% length(),
                                       regs_total_comp[[i]] %>% length()))
}

#Orders levels

levels_order <- c("zero", "0-.25", ".25-.5",
                  ".5-.75", ".75-1", "full")

#Writes a bar plot to show the number of regions in the completeness brackets
#Outlined above

for(i in 1:length(vars)){
  
  setwd(here())
  setwd(output_path[[i]])
  
  ggplot(regs_comp_summary[[i]], aes(factor(level, levels_order))) +
    geom_bar(aes(weight = counts)) +
    xlab("Level of Completion") + ylab("Countries") +
    ggtitle(paste0("Count of Countries by Completion Level \n for `",
                   vars[i],"` ",timename,", ",spatialspec)) +
    labs(caption = paste0("Report run ", Sys.Date())) +
    theme(plot.title = element_text(hjust = .5),
          plot.caption = element_text(hjust = .5))
  ggsave("./Analysis_Data/Completeness_Distribution.png")
  
}

#Runs a histogram for the number of regions that fall into each quartil for
#completeness - This is parsed seperately if there are subregions/sub-times

if(timespec == "year" & spatialspec == "GID_0"){

for(i in 1:length(vars)){ #If there are no subregions/sub-times

  setwd(here())
  setwd(output_path[[i]])

  ggplot(reg_year_share[[i]]) +
    geom_histogram(aes(x = year_share), binwidth = .1, color = "white") +
    xlab("Countries by Share of Years with Data") + ylab("Count") +
    ggtitle(paste0("Distributions of Regions by Completeness\n for `",
                   vars[i],"` ",timename,", ",spatialspec)) +
    labs(caption = paste0("Report run ", Sys.Date())) +
    theme(plot.title = element_text(hjust = .5),
          plot.caption = element_text(hjust = .5))
  ggsave("./Analysis_Data/Completeness_Histogram.png")
}

} else{
  
for(i in 1:length(vars)){#If there are subregions or sub-times
  
  setwd(here())
  setwd(output_path[[i]])

  ggplot(reg_completeness[[i]]) +
    geom_histogram(aes(x = complete_share), binwidth = .1, color = "white") +
    xlab("Country-Years by Share of Subregions With Complete Data") + ylab("Count") +
    ggtitle(paste0("Distributions of Regions by Completeness\n for `",
                   vars[i],"` ",timename,", ",spatialspec)) +
    labs(caption = paste0("Report run ", Sys.Date())) +
    theme(plot.title = element_text(hjust = .5),
          plot.caption = element_text(hjust = .5))
  ggsave("./Analysis_Data/Completeness_Histogram.png")
  
}
}


#Runs a facet graph for all-time completion share for each region present

  slices <- ceiling(length(regions)/10)
  
  for(i in 1:length(vars)){
    
    setwd(here())
    setwd(paste0(output_path[[i]],"/Completeness_PNGs/Country_Totals"))
    
    for(j in 1:slices){
      
      start <- (j-1)*10 + 1
      end <- if(j*10 > length(regions)){
        length(regions)} else{
          j*10}
      
      slice <- reg_year_share[[i]][start:end,]  
      
      ggplot(slice, aes(region)) +
        geom_bar(aes(weight = year_share)) +
        xlab("Region") + ylab("Share of Years With Data") +
        ggtitle(paste0("Completeness Share for `", vars[i], "` ", timename,", ", spatialspec)) +
        labs(caption = paste0("Report run ", Sys.Date(), ", slide ", j,"/",slices)) +
        theme(plot.title = element_text(hjust = .5), plot.caption = element_text(hjust = .5))
      ggsave(paste0(Sys.Date(),"_",vars[i],"_",slice[1,1],"_to_",tail(slice,1)[1,1],'.png'))
    }
  }
  

#Runs a line graph for each country demonstrating completeness over time
  
slices <- ceiling(length(regions)/5)

for(i in 1:length(vars)){
  
setwd(here())
setwd(paste0(output_path[[i]],"/Completeness_PNGs/Year_Totals"))

for(j in 1:slices){

start <- (j-1)*length(year_bound[[i]])*5 + 1
end <- if(j*length(year_bound[[i]])*5 > length(regions)*length(year_bound[[i]])){
  length(regions)*length(year_bound[[i]])} else{
  j*length(year_bound[[i]])*5}

slice <- reg_completeness[[i]][start:end,]  

ggplot(slice) +
  geom_line(aes(x = year, y = complete_share)) +
  facet_grid(rows = vars(region)) + xlab("Year") + ylab("Completeness") +
  ylim(0,1) +
  ggtitle(paste0("Completeness Share for `", vars[i], "` ", timename,", ", spatialspec)) +
  labs(caption = paste0("Report run ", Sys.Date(), ", slide ", j,"/",slices)) +
  theme(plot.title = element_text(hjust = .5), plot.caption = element_text(hjust = .5))
  ggsave(paste0(Sys.Date(),"_",vars[i],"_",slice[1,1],"_to_",tail(slice,1)[1,1],'.png'))
}
}
setwd(here())

#####
###ANOMALIES
#####

parameters <- read.csv('../Data/anomaly_parameters.csv')
anom_lesser <- NULL
anom_greater <- NULL
anom_exact <- NULL
anom_increase <- NULL
anom_decrease <- NULL
params <- NULL

for(i in 1:length(vars)){

params[[i]] <- parameters %>% select(1, !!as.name(vars[i]))

param_dat <- dat_bounded[[i]] %>%
  filter(!is.na(!!as.name(vars[i]))) %>%
  mutate(regyear = paste0(!!as.name(spatialspec),"_",!!as.name(timespec))) %>%
  group_by(!!as.name(spatialspec)) %>%
  mutate(shift = (!!as.name(vars[i]) - lag(!!as.name(vars[i])))/lag(!!as.name(vars[i]))) %>%
  ungroup()

anom_lesser[[i]] <- param_dat %>%
  filter(!!as.name(vars[i]) < params[[i]][1,2]) %>%
  select(regyear, !!as.name(vars[i])) %>%
  arrange(!!as.name(vars[i]))

anom_greater[[i]] <- param_dat %>%
  filter(!!as.name(vars[i]) > params[[i]][2,2]) %>%
  select(regyear, !!as.name(vars[i])) %>%
  arrange(desc(!!as.name(vars[i])))

anom_exact[[i]] <- param_dat %>%
  filter(!!as.name(vars[i]) == params[[i]][3,2]) %>%
  select(regyear, !!as.name(vars[i]))

anom_increase[[i]] <- param_dat %>%
  filter(shift > params[[i]][4,2]) %>%
  select(regyear, !!as.name(vars[i]), shift) %>%
  arrange(shift)

anom_decrease[[i]] <- param_dat %>%
  filter(shift < params[[i]][5,2]) %>%
  select(regyear, !!as.name(vars[i]), shift) %>%
  arrange(shift)
}

######
###EXPORT
######
#This section exports all data created to each variable to be used for the
#.Rmd to reference and generate the report.

for(i in 1:length(vars)){
  
setwd(here())
setwd(paste0(output_path[[i]],'/Analysis_Data'))

write.csv(c(vars[i],timespec,timename,spatialspec), 'meta.csv', row.names = FALSE)
write.csv(basic_summary[[i]], 'simple_summary.csv', row.names = FALSE)
write.csv(bounds[[i]], 'bounds.csv', row.names = FALSE)
write.csv(complete_share[[i]], 'complete_share.csv', row.names = FALSE)
write.csv(year_bound[[i]], 'year_bound.csv', row.names = FALSE)
write.csv(reg_completeness[[i]], 'reg_completeness.csv', row.names = FALSE)
write.csv(reg_year_share[[i]], 'reg_year_share.csv', row.names = FALSE)
write.csv(regs_zero_comp[[i]], 'regs_zero_comp.csv', row.names = FALSE)
write.csv(regs_q1_comp[[i]], 'regs_q1_comp.csv', row.names = FALSE)
write.csv(regs_q2_comp[[i]], 'regs_q2_comp.csv', row.names = FALSE)
write.csv(regs_q3_comp[[i]], 'regs_q3_comp.csv', row.names = FALSE)
write.csv(regs_q4_comp[[i]], 'regs_q4_comp.csv', row.names = FALSE)
write.csv(regs_total_comp[[i]], 'regs_total_comp.csv', row.names = FALSE)
write.csv(regs_comp_summary[[i]], 'regs_comp_summary.csv', row.names = FALSE)
write.csv(params[[i]], 'anomaly_parameters.csv', row.names = FALSE)
write.csv(anom_lesser[[i]], "anom_lesser.csv", row.names = FALSE)
write.csv(anom_greater[[i]], "anom_greater.csv", row.names = FALSE)
write.csv(anom_exact[[i]], "anom_exact.csv", row.names = FALSE)
write.csv(anom_increase[[i]], "anom_increase.csv", row.names = FALSE)
write.csv(anom_decrease[[i]], "anom_decrease.csv", row.names = FALSE)
write.csv(metadata[[i]], "metadata_completeness.csv", row.names = FALSE)
}


#Runs .RMD for each variable
for(i in 1:length(vars)){
setwd(here())
write.csv(c(paste0(output_path[[i]],"/Analysis_Data")), 'pathfinder.csv', row.names = FALSE)  
rmarkdown::render('integrity_report.Rmd', 'pdf_document',
                  output_file = paste0(output_path[[i]],"/", vars[i],
                                       "_integrity_report.pdf"))
}

