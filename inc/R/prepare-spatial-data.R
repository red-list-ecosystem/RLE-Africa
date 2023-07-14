####
## IUCN Red List of Ecosystems in Africa
## J.R. Ferrer-Paris https://github.com/jrfep
## This is the Rscript used to prepare spatial data for mapping
####

## Set up  -------

### load libraries
require(sf)
require(dplyr)

here::i_am("inc/R/prepare-spatial-data.R")

## recommended spatial projections ----

##  Chamberlin trimetric conversion method
chb_proj <- "+proj=chamb +lat_1=22 +lon_1=0 +lat_2=22 +lon_2=45 +lat_3=-22 +lon_3=22.5 +datum=WGS84 +type=crs"
## Africa Lambert Conformal Conic
lcc_proj <- "+proj=lcc +lat_1=20 +lat_2=-23 +lat_0=0 +lon_0=25 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m no_defs"

# Location of Strategic assessments ----

g <- st_sfc(st_point(x=c(30.8729,31.4761)),#lake burullus
            st_point(x=c(46.47416,-20.37449)), # Tapia forest
            st_point(x=c(-16.49901060022063,13.652516407467148)), # Fathala forest
            st_point(x=c(18.95,-34.25)), # Cape Flats Sand Fynbos
            st_point(x=c(15,-31.5)), # Benguela
            st_point(x=c(-14.7,16)), # Gonakier
            st_point(x=c(45.138333,-12.843056)) # Mayotte
)

Strategic <- st_sf(
  data.frame(
    place=c("Burullus Protected Area\n(wetland, sand plain, salt marshes)",
            "Tapia Forest",
            "Fathala\nForest", 
            "Cape Flats Sand Fynbos",
            "Benguela\ncurrent",
            "Gonakier Forest",
            "Mayotte Mangroves")),
    g, 
    crs="+proj=longlat +datum=WGS84") %>% 
  st_transform(crs=lcc_proj)


# Location of Systematic assessments ----

## Read existing geospatial data ----

### : Africa map
Africa <- read_sf(here::here("Data","Africa.gpkg")) %>% 
  st_transform(crs=lcc_proj)

### Marine ecoregions
meow <- read_sf(here::here("Data","MEOW","MEOW","meow_ecos.shp"))

### Exclusive Economic zones
EEZ <- read_sf(here::here("Data","EEZ_land_union_v3_202003", "EEZ_Land_v3_202030.shp"))

### EU assessments
EURLH.mar <- read_sf(
  here::here("Data", "EURLH", "Geodatabases", 
             "North\ East\ Atlantic\ Sea\ geodatabase\ v03/"), 
  'NEA geodatabase')

EURLH.ter <- read_sf(
  here::here("Data", "EURLH", "Geodatabases", "Terrestrial\ geodatabase"), 
  'RDB_Final_Maps_Terrestrial')

###South Africa assessments
SA_mar <- read_sf(
  here::here("Data","ZAF", "NBA2018_Marine_ThreatStatus_ProtectionLevel.shp"))
#SA_mar %>% st_geometry() %>% plot # does not include Prince Edward Islands

## Merge and modify geospatial data -------

### Terrestrial -------

#### Extract the land area
Africa.land <- Africa %>% filter(!featurecla %in% "Marine area") %>% st_union

#### See DISCLAIMER on frontiers and national boundaries
# Morocco.whole <- Africa %>% filter(NAME_EN %in% c("Western Sahara","Morocco")) %>% st_union

#### Classify systematic terrestrial assessment: add a column for RLE progress by country
Africa %<>%
  mutate(RLE_progress=case_when(
    NAME_EN %in% c("Madagascar","South Africa","Mozambique") ~ "All ecosystem types",
    NAME_EN %in% c("Ethiopia","Uganda","Botswana","Ghana","Malawi") ~ "Preliminary/Rapid",
    NAME_EN %in% c("Democratic Republic of the Congo","Republic of the Congo","Central African Republic", "Gabon", "Equatorial Guinea") ~ "Thematic subset of ecosystem types",
    NAME_EN %in% c("Tunisia", "Rwanda") ~ "In progress",
    NAME_EN %in% c("Liberia","Sierra Leone","Guinea") ~ "In progress", # Santerre's work
    #NAME_EN %in% c(  "Namibia", "Cameroon","Angola") ~ "To confirm", # early stages according to provita inventory
    NAME_EN %in% c(  "Ivory Coast", "Senegal") ~ "In progress", ## Provita spreadsheet
    TRUE ~ "None",
  )) %>% 
  mutate(
    RLE_progress = factor(
      RLE_progress,
      levels = c("In progress","Preliminary/Rapid","Thematic subset of ecosystem types","All ecosystem types")))

### Marine -------

#### EEZ for South Africa, Madagascar 
EEZ.slc <- EEZ %>% 
  filter(grepl("South Africa|Madagascar",UNAME)) %>% st_transform(crs=st_crs(Africa))
# No need to include Prince Edward Islands

#### cut the European Union RLH data for the Macaronesian islands
EEZ.EU <- EEZ %>% 
  filter(grepl("Canary Islands|Madeira",UNAME)) %>% 
  st_transform(crs=st_crs(EURLH.mar))
EURLH.mar.qry <- EURLH.mar %>% st_intersection(EEZ.EU) 
EURLH.ter.qry <- EURLH.ter %>% st_intersection(EEZ.EU)

#distinct(EURLH.mar.qry,Habitat_na)
#distinct(EURLH.ter.qry,TYPE_NAME)
EURLH.mar <- EURLH.mar.qry %>% st_union %>% st_transform(crs=st_crs(Africa))
EURLH.ter <- EURLH.ter.qry %>% st_union %>% st_transform(crs=st_crs(Africa))

#### Use the MEOW data to extract the assessment area for the Western Indian Ocean (WIO)
WIO <- meow %>% filter(PROVINCE %in% "Western Indian Ocean") %>% st_union
WIO <- WIO %>% st_transform(crs=st_crs(Africa)) %>% st_difference(Africa.land)


## Write all output files  -------
write_sf(Strategic, dsn=here::here("Data","RLE-Africa-strategic.gpkg"))
write_sf(Africa, dsn=here::here("Data","RLE-Africa-terr-systematic.gpkg"))
write_sf(EEZ.slc, dsn=here::here("Data","RLE-Africa-mar-systematic.gpkg"))
write_sf(WIO, dsn=here::here("Data","RLE-Africa-mar-add-WIO.gpkg"))
write_sf(EURLH.ter, dsn=here::here("Data","RLE-Africa-ter-add-EU.gpkg"))
write_sf(EEZ.EU, dsn=here::here("Data","RLE-Africa-mar-add-EU.gpkg"))


