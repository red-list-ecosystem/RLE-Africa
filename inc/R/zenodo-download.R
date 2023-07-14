#R --vanilla
####
## IUCN Red List of Ecosystems in Africa
## J.R. Ferrer-Paris https://github.com/jrfep
## Script to download of data from a Zenodo repository
####

require(zen4R)
library(parallel)
here::i_am("inc/R/zenodo-download.R")

setwd(here::here("Data","area-calc"))
#Version 2.1.1
doi = "10.5281/zenodo.5090419"

download_zenodo(doi=doi, parallel = TRUE, parallel_handler = parLapply, cl = makeCluster(2))


# all versions 10.5281/zenodo.3546513
#zenodo <- suppressWarnings(ZenodoManager$new())
#rec <- zenodo$getRecordById("5090419")
#rec$downloadFiles(path = "Data/")

#OR:
#cd Data/
#wget --continue https://zenodo.org/api/files/4991f687-63f1-4ec8-ab92-75c8fcd5bd6a/all-maps-raster-geotiff.tar.bz2
#tar -xjvf all-maps-raster-geotiff.tar.bz2

q()
