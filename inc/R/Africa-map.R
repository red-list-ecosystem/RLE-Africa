####
## IUCN Red List of Ecosystems in Africa
## J.R. Ferrer-Paris https://github.com/jrfep
## This is the Rscript used to generate the output map for the manuscript
####

## Set up  -------

### load libraries
require(sf)
require(dplyr)
library(lwgeom)
require(vroom)
require(ggplot2)
require(magrittr)
require(tmap)

## Read Geospatial data  -------

#  Chamberlin trimetric conversion method
chb_proj <- "+proj=chamb +lat_1=22 +lon_1=0 +lat_2=22 +lon_2=45 +lat_3=-22 +lon_3=22.5 +datum=WGS84 +type=crs"
# Africa Lambert Conformal Conic
lcc_proj <- "+proj=lcc +lat_1=20 +lat_2=-23 +lat_0=0 +lon_0=25 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m no_defs"

# Read existing geospatial data
Africa <- read_sf("Data/Africa.gpkg") %>% st_transform(crs=lcc_proj)

meow <- read_sf("Data/MEOW/MEOW/meow_ecos.shp")

EEZ <- read_sf("Data/EEZ_land_union_v3_202003/EEZ_Land_v3_202030.shp")
EEZ.slc <- EEZ %>% filter(grepl("South Africa|Madagascar",UNAME)) # should we include Prince Edward Islands?
EEZ.EU <- EEZ %>% filter(grepl("Canary Islands|Madeira",UNAME)) %>% st_transform(crs=st_crs(EURLH.mar))

EURLH.mar <- read_sf("Data/EURLH/Library/Project\ data\ deliverables/Geodatabases/North\ East\ Atlantic\ Sea\ geodatabase\ v03/", 'NEA geodatabase')
EURLH.ter <- read_sf("Data/EURLH/Library/Project\ data\ deliverables/Geodatabases/Terrestrial\ geodatabase", 'RDB_Final_Maps_Terrestrial')

#South Africa marine area
SA_mar <- read_sf("Data/ZAF/NBA2018_Marine_ThreatStatus_ProtectionLevel.shp")
#SA_mar %>% st_geometry() %>% plot # does not include Prince Edward Islands

# Create points for Strategic assessments
g <- st_sfc(st_point(x=c(30.8729,31.4761)),#lake burullus
            st_point(x=c(46.47416,-20.37449)), # Tapia forest
            st_point(x=c(-16.49901060022063,13.652516407467148)), # Fathala forest
            st_point(x=c(18.52,-34.57)), # Cape Flats Sand Fynbos
            st_point(x=c(15,-31.5)), # Benguela
            st_point(x=c(-14.7,16)), # Gonakier
            st_point(x=c(45.138333,-12.843056)) # Mayotte
)
Strategic <- st_sf(data.frame(place=c("Burullus Protected Area\n(wetland, sand plain, salt marshes)","Tapia Forest","Fathala Forest", "Cape Flats Sand Fynbos","Benguela current","Gonakier Forest","Mayotte Mangroves")),g,crs="+proj=longlat +datum=WGS84") %>% st_transform(crs=st_crs(Africa))


## Merge and modify geospatial data -------

# See DISCLAIMER on frontiers and national boundaries
Morocco.whole <- Africa %>% filter(NAME_EN %in% c("Western Sahara","Morocco")) %>% st_union

# add a column for RLE progress by country
Africa %<>%
  mutate(RLE_progress=case_when(
    NAME_EN %in% c("Madagascar","South Africa","Mozambique") ~ "All ecosystems",
    NAME_EN %in% c("Ethiopia","Uganda","Botswana","Ghana","Malawi") ~ "Preliminary/Rapid",
    NAME_EN %in% c("Democratic Republic of the Congo","Republic of the Congo","Central African Republic", "Gabon", "Equatorial Guinea") ~ "Subset of ecosystems",
    NAME_EN %in% c("Tunisia", "Rwanda") ~ "In progress",
    NAME_EN %in% c("Liberia","Sierra Leone","Guinea") ~ "In progress", # Santerre's work
    #NAME_EN %in% c(  "Namibia", "Cameroon","Angola") ~ "To confirm", # early stages according to provita inventory
    NAME_EN %in% c(  "Ivory Coast", "Senegal") ~ "In progress", ## Provita spreadsheet
    TRUE ~ "None",
  )) %>% mutate(RLE_progress=factor(RLE_progress,levels=c("In progress","Preliminary/Rapid","Subset of ecosystems","All ecosystems")))


#Extract the land area
Africa.land <- Africa %>% filter(!featurecla %in% "Marine area") %>% st_union

# Use the MEOW data to extract the assessment area for the Western Indian Ocean (WIO)
WIO <- meow %>% filter(PROVINCE %in% "Western Indian Ocean") %>% st_union
WIO <- WIO %>% st_transform(crs=st_crs(Africa)) %>% st_difference(Africa.land)

## cut the European Union RLH data for the Macaronesian islands
EURLH.mar.qry <- EURLH.mar %>% st_intersection(EEZ.EU)
EURLH.ter.qry <- EURLH.ter %>% st_intersection(EEZ.EU)
#distinct(EURLH.mar.qry,Habitat_na)
#distinct(EURLH.ter.qry,TYPE_NAME)

EURLH.mar <- EURLH.mar.qry %>% st_union
EURLH.ter <- EURLH.ter.qry %>% st_union


## Interactive exploration of the data -------

# this is a interactive option to explore the map for inconsistencies
# tmap_mode("view")
# tm_shape(Africa   %>% select(NAME_EN,RLE_progress)) +
#  tm_polygons(col="RLE_progress")
### tm_shape(SA_mar) + tm_polygons() # problems with some polygons
# tm_shape(EEZ) + tm_polygons()

## Final map for output -------


bls <- RColorBrewer::brewer.pal(3,"Blues")
ogs <- RColorBrewer::brewer.pal(4,"Oranges")

tmap_mode("plot")
tm_shape(Africa.land,
         ylim=c(-4134891,4187812),
         xlim=c(-5261966,4751028)) +
  tm_fill(col='grey88') +
  tm_shape(Africa %>% filter(!featurecla %in% "Marine area",
                             !NAME_EN %in% c("Western Sahara","Morocco"))) +
  tm_borders(col='grey99') +
  tm_shape(WIO) + tm_fill(bls[2]) +
  tm_shape(EEZ.slc) + tm_fill(col=bls[3]) +
  tm_shape(Africa  %>% filter(RLE_progress != "None") %>% select(NAME_EN,RLE_progress)) +
  tm_polygons(col="RLE_progress", palette = "Oranges",title="Systematic Assessments\nTerrestrial/Freshwater") + #+ tm_text('NAME_EN',size="AREA")
  tm_shape(Strategic) + tm_text('place',size=.7,just=-.1) + tm_dots(size=.5) +
  tm_layout(legend.position = c("left","bottom")) +
  tm_add_legend(type="fill",col=bls[2:3],title="Marine",labels=c('Subset of ecosystems','All ecosystems')) +
  tm_add_legend(type="symbol",col='black',title="Strategic assessment",labels=c('Locations')) +
  tm_shape(EEZ.EU) + tm_fill(col=bls[3]) +
  tm_shape(EURLH.ter) + tm_polygons(col=ogs[4])
