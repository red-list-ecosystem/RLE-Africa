# Set up ----

## libraries
require(dplyr)
require(RPostgreSQL)
require(magrittr)
library(sf)


lme_admin <- read_sf("https://github.com/red-list-ecosystem/typology-map-data/raw/master/data/analysis/lme_admin.topo.json") %>%
  st_drop_geometry()


## working directory
here::i_am("inc/R/misc/query-EFG-countries-database.R")

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
qry <- "select * from all_region_group_areas"
qry_website <- dbGetQuery(con,qry)


qry_website <- qry_website %>% mutate(occurrence = str_replace_all(occurrence,c("1"="major","2"="minor")))

table_occurrence_all_countries <- lme_admin %>% left_join(qry_website, by = "region_id") %>% select(region_id, title_EN, layer_id, occurrence,area)

library(readr)
write_csv(file = here::here("Data","efg-occurrence-area-by-country-or-marine-region.csv"),
          table_occurrence_all_countries)

dbDisconnect(con)
