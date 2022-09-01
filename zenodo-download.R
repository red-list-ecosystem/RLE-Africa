#R --vanilla
require(zen4R)
library(parallel)
setwd("Data")
#Version 2.1.1 
doi = "10.5281/zenodo.5090419"

download_zenodo(doi=doi, parallel = TRUE, parallel_handler = parLapply, cl = makeCluster(2))


# all versions 10.5281/zenodo.3546513
zenodo <- suppressWarnings(ZenodoManager$new())
rec <- zenodo$getRecordById("5090419")
rec$downloadFiles(path = "Data/")

#OR:
#cd Data/
#wget --continue https://zenodo.org/api/files/4991f687-63f1-4ec8-ab92-75c8fcd5bd6a/all-maps-raster-geotiff.tar.bz2
#tar -xjvf all-maps-raster-geotiff.tar.bz2 

q()
