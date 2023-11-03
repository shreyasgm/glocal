## Master file: Sources code for administrative level variables ## 

# Downloading all R Scripts from working directory  

scripts <- list.files(path = ".", pattern='_', 
                       all.files=TRUE, full.names=TRUE) 

# Selecting all scripts except Master file

scripts <- scripts[2:14]  

#Sourcing scripts using lapply
lapply(scripts, source)
