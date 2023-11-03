*************************ADMINISTRATIVE AREA PROJECT****************************

Project description:
* This project generates a complete global dataset of relevant variables
for administrative area levels 1 and 2. 


Code files description: 
* The project is comprised of 14 .R scripts as described: 

  00_MasterFile.R : sources the rest of the scripts in the project. This is the 
                    only file the user will need to run in order to generate the
                    final output (2 datasets). 

  01_GeomCentroid.R : generates geometric centroid lon and lat of each 
                      administrative area for levels 1 and 2.

  02_Capital.R : generates a dummy variable that assigns 1 if an administrative 
                 area is a capital and 0 if not. 
  
  03_DistanceCentroidCapital.R : generates the distance in kilometers (km) from 
                                 geometric centroid of each administrative area 
                                 to the capital of its country. 

  04_Borders.R : generates a dummy variable that assigns 1 if an administrative 
                 area has a land border with other countries and 0 if not. 

  05_RiversLakes.R : generates a dummy variable that assigns 1 if an administrative 
                     area has a river or lake and 0 if not.

  06_Coasts.R : generates a dummy variable that assigns 1 if an administrative area 
                has coasts and 0 if not.

  07_PopWeightedCentroid.R : generates the population weighted centroids lon and lat
                             for each administrative area polygon. It also generates 
                             a dummy variable that assigns 1 if the coordinates are 
                             from population weighted centroid and 0 if they are the 
                             coordinates for geometric centroid (see Notes section). 
                             The population density raster is for 2020. 

  08_GasFlares.R : generates a dummy variable that assigns 1 if an administrative area 
                   has a gas flare and 0 if not. 

  09_MineralDeposits.R : generates a dataset of dummy variables for 5 categories: energy 
                         minerals, precious minerals, technology relevant minerals, other
                         minerals and mineral deposits. The first four variables assign 1 
                         if the administrative area has a mineral deposit with that type 
                         of mineral and 0 if not. The last variable assigns 1 if the
                         administrative area has a mineral deposit and 0 if not. 

  10_Airports.R : generates a dataset of three dummy variables for the presence or not of 
                  medium airports, large airports and international airports. 

  11_Ports.R : generates a dummy variable that assigns 1 if an administrative area has 
               a port and 0 if not. 

  12_DistancePopCentroidsCapital.R : generates the distance in kilometers (km) from 
                                 population weighted centroid of each administrative area 
                                 to the capital of its country. 
 
  99_FinalOutput.R : generates the final output datasets. There are 2 datasets, one 
                     for level 1 and one for level 2. 

Notes: 
* For the population weighted centroids, there where instances in which the raster file 
for population density did not have a value for an administrative region polygon. Most of 
these instances were islands. For these cases, we imputated the geometric centroid coordinates.
The dummy variable 'pop_centr' assigns 1 if the lat and lon coordinates are population centroids
and 0 if they are geometric centroids. 


Variable description: 

GID_1 or GID_2 : administrative area code for levels 1 or 2. 

capital : dummy variable that assigns 1 if an administrative area is a 
         capital and 0 if not. 

land_border : dummy variable that assigns 1 if an administrative area has
              a land border with other countries and 0 if not. 

dist_km : distance in kilometers (km) from geometric centroid of each 
          administrative area to the capital of its country. 

lon_geomcentr and lat_geomcentr : coordinates for geometric centroid of each 
                                  administrative area. 

rivers_lakes : dummy variable that assigns 1 if an administrative area has 
               a river or lake and 0 if not.

coasts : dummy variable that assigns 1 if an administrative area has coasts
         and 0 if not.

lon_popcentr and lat_popcentr : coordinates for population weighted centroid
                                of each administrative area. 

pop_centr : dummy variable that assigns 1 if the lat and lon coordinates 
            are population centroids and 0 if they are geometric centroids. 
 
dist_km_popcentr : distance in kilometers (km) from population weighted 
                   centroid of each administrative area to the capital of
                   its country. 

flare : dummy variable that assigns 1 if an administrative area has a gas
        flare and 0 if not. 

ports : dummy variable that assigns 1 if an administrative area has a port
       and 0 if not. 

int_airpots : dummy variable that assigns 1 if an administrative area has 
              an international airport and 0 if not. 

large_airpots : dummy variable that assigns 1 if an administrative area has 
                a large airport and 0 if not.

medium_airpots : dummy variable that assigns 1 if an administrative area has 
                  a medium airport and 0 if not.

min_deposit : dummy variable that assigns 1 if the administrative area has
              a mineral deposit and 0 if not. 

tech_min : dummy variable that assigns 1 if the administrative area has at 
           least one mineral deposit with technology relevant minerals and
           0 if not. 

energy_min : dummy variable that assigns 1 if the administrative area has at 
             least one mineral deposit with energy relevant minerals and
             0 if not. 

precious_min : dummy variable that assigns 1 if the administrative area has 
               at least one mineral deposit with precious minerals and 0 if not.

other_min : dummy variable that assigns 1 if the administrative area has 
            at least one mineral deposit with other minerals and 0 if not.