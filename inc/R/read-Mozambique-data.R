# Set up ----

## libraries
require(sf)
require(dplyr)
library(readr)
library(stringr)

## working directory
here::i_am("inc/R/read-Mozambique-data.R")

moz <- read_sf(here::here("Data","Moz", 
                          "Moz_ecosystem_map_w_RLE_results_01Mar2021.shp"))
moz %>% slice(1)

tbl <- moz %>% filter(!is.na(IUCN_Funct))  %>% 
  mutate(efg_code=str_extract(IUCN_Funct,"[A-Z0-9\\.]+")) %>%
  st_drop_geometry() %>%
  transmute(
    eco_name = Name,
    category = Overall__1,
    area_km2 = `2016_Area`,
    efg_code
  )

write_csv(tbl, file = here::here("Data", "systematic-assessment-summaries",
                                 "mozambique-summary-RLE.csv"))
