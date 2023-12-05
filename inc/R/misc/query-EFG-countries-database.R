# Set up ----

## libraries
require(sf)
require(dplyr)
require(RPostgreSQL)
require(xml2)
require(stringr)
require(foreign)
require(units)
require(magrittr)
require(readxl)
require(tidyr)
library(treemapify)

## working directory
here::i_am("inc/R/List-RLE-assessments.R")

## Database credentials

if (file.exists("~/.database.ini")) {
  tmp <-     system("grep -A4 psqlaws $HOME/.database.ini",intern=TRUE)[-1]
  dbinfo <- gsub("[a-z]+=","",tmp)
  names(dbinfo) <- gsub("([a-z]+)=.*","\\1",tmp)
}


# List of assessment units in those countries ----

drv <- dbDriver("PostgreSQL") ## remember to update .pgpass file
con <- dbConnect(drv, dbname = dbinfo[["database"]],
                 host = dbinfo[["host"]],
                 port = dbinfo[["port"]],
                 user = dbinfo[["user"]])


dbListTables(con)
qry <- "select * from region_group_areas limit 2"
qry <- "select * from all_region_group_areas limit 2"
dbGetQuery(con,qry)

qry <- "select * from layers limit 2"
dbGetQuery(con,qry)

qry <- "select ogc_fid, area_km2 from eez_valid limit 2"
dbGetQuery(con,qry)

dbDisconnect(con)
