### load libraries
require(sf)
require(dplyr)
require(tmap)

here::i_am("inc/R/Africa-map.R")

## Read Geospatial data  -------


lvls <- c("In progress", "Preliminary/Rapid", "Thematic subset of ecosystem types",
          "All ecosystem types")
Africa <- read_sf(here::here("Data","RLE-Africa-terr-systematic.gpkg")) %>% 
  mutate(RLE_progress = factor(RLE_progress, levels=lvls))


## Subregions to consider -------

#Hillary suggest that Mozambique Malawi and Zimbawe and Zambia should be southern africa
#this does not work very well
#st_snap_to_grid(size = 0.001) %>% st_make_valid() %>% 
  #group_by(SUBREGION) %>% summarise(geometry=st_combine(geometry)) %>% st_make_valid() %>% 
  
Subregions_Hillary <- list(`Southern Africa` = list("NA","ZA","BW","SZ","LS"),
     `Western Africa` = list("SL", "GN", "LR", "CI", "ML", "SN", "NG", "BJ", "NE", "BF", "TG", "GH", "GW", "MR", "GM", "SH", "CV"),
     `Eastern Africa` = list("ET", "SS", "SO", "KE", "MW", "TZ", "ZM", "DJ", "ER", "ZW", "MZ","BI", "RW", "UG", "MG", "SC", "MU", "KM"),
     `Northern Africa` = list("MA", "LY",  "TN",  "SD",  "DZ",  "EG" ),
     `Marine areas` = list("LME31", "LME46", "LME47", "LME51", "LME54"))


## Map visualisation -------

tmap_mode("view")
tm_shape(Africa   %>% select(NAME_EN,RLE_progress)) +
  tm_polygons(col="RLE_progress")

#tmap_mode("view")
#tm_shape(SA_mar) + tm_polygons() # problems with some polygons



