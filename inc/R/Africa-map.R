####
## IUCN Red List of Ecosystems in Africa
## J.R. Ferrer-Paris https://github.com/jrfep
## This is the Rscript used to generate the output map for the manuscript
## See DISCLAIMER on frontiers and national boundaries
####

## Set up  -------

### load libraries
require(sf)
require(dplyr)
library(lwgeom)
require(magrittr)
require(tmap)

here::i_am("inc/R/Africa-map.R")

## Read Geospatial data  -------

# Africa Lambert Conformal Conic
lcc_proj <- "+proj=lcc +lat_1=20 +lat_2=-23 +lat_0=0 +lon_0=25 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m no_defs"

lvls <- c("In progress", "Preliminary/Rapid", "Thematic subset of ecosystem types",
          "All ecosystem types")
Africa <- read_sf(here::here("Data","RLE-Africa-terr-systematic.gpkg")) %>% 
  mutate(RLE_progress = factor(RLE_progress, levels=lvls))
Africa.land <- Africa %>% filter(!featurecla %in% "Marine area") %>% st_union

RLE_mar_sys <- read_sf(here::here("Data","RLE-Africa-mar-systematic.gpkg")) 
RLE_mar_WIO <- read_sf(here::here("Data","RLE-Africa-mar-add-WIO.gpkg")) 
RLE_mar_EU <- read_sf(here::here("Data","RLE-Africa-mar-add-EU.gpkg")) 
RLE_ter_EU <- read_sf(here::here("Data","RLE-Africa-ter-add-EU.gpkg")) 

Strategic <- read_sf(here::here("Data","RLE-Africa-strategic.gpkg"))
#Strategic <- Strategic %>% 
#  st_transform(crs=st_crs(Africa))

## Interactive exploration of the data -------

# this is a interactive option to explore the map for inconsistencies
# tmap_mode("view")
# tm_shape(Africa   %>% select(NAME_EN,RLE_progress)) +
#  tm_polygons(col="RLE_progress")
### tm_shape(SA_mar) + tm_polygons() # problems with some polygons
# tm_shape(EEZ) + tm_polygons()

## Map figure for output -------

bls <- RColorBrewer::brewer.pal(3,"Blues")
ogs <- RColorBrewer::brewer.pal(4,"Oranges")

tmap_mode("plot")

africa_map <-
  tm_shape(Africa.land,
         ylim=c(-4134891,4187812),
         xlim=c(-5261966,4751028)) +
  tm_fill(col='grey88') +
  tm_shape(Africa %>% filter(!featurecla %in% "Marine area",
                             !NAME_EN %in% c("Western Sahara","Morocco"))) +
  tm_borders(col='grey99') +
  tm_shape(RLE_mar_WIO) + tm_fill(bls[2]) +
  tm_shape(RLE_mar_sys) + tm_fill(col=bls[3]) +
  tm_shape(Africa  %>% filter(RLE_progress != "None") %>% select(NAME_EN,RLE_progress)) +
  tm_polygons(col="RLE_progress", 
              palette = "Oranges",
              title="Systematic Assessments\nTerrestrial/Freshwater") + 
  #+ tm_text('NAME_EN',size="AREA")
  tm_shape(Strategic %>% slice(1)) + 
  tm_text('place',size=.7,just=c(-.1)) + 
  tm_dots(size=.5) +
  tm_shape(Strategic %>% slice(c(3,5))) + 
  tm_text('place',size=.7,just=c(1.2)) + 
  tm_dots(size=.5) +
  tm_shape(Strategic %>% slice(-c(1,3,5))) + 
  tm_dots(size=.3,shape=1) +
  tm_layout(legend.position = c("left","bottom")) +
  tm_add_legend(type="fill",
                col=bls[2:3],
                title="Marine",
                labels=c('Thematic subset of ecosystem types',
                         'All ecosystems types')) +
  tm_add_legend(type="symbol",
                shape=c(19,1),
                size=c(.5,.3),
                col=c('black'),
                title="Strategic assessments",
                labels=c('Included in review','Others')) +
  tm_shape(RLE_mar_EU) + tm_fill(col=bls[3]) +
  tm_shape(RLE_ter_EU) + tm_polygons(col=ogs[4])

africa_map

## This map includes:
## [√] All marine areas
## [√] Work by Senterre in progress
## [√] All countries mentioned in Andrew's Email
## [√] Adding Mayotte (WIO)
## [√] Canary islands / EU RLH marine/terrestrial


## Save output file  -------

tmap_save(africa_map, 
          here::here("Output","Assessment-map.png"), 
                     height = 5) # height interpreted in inches

