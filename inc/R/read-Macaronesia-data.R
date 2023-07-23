require(sf)
require(dplyr)
library(readr)
library(units)
library(stringr)
here::i_am("inc/R/read-Macaronesia-data.R")

EEZ <- read_sf(here::here("Data","EEZ_land_union_v3_202003", "EEZ_Land_v3_202030.shp"))

### EU assessments
EURLH.mar <- read_sf(
  here::here("Data", "EURLH", "Geodatabases", 
             "North\ East\ Atlantic\ Sea\ geodatabase\ v03/"), 
  'NEA geodatabase')

EURLH.ter <- read_sf(
  here::here("Data", "EURLH", "Geodatabases", "Terrestrial\ geodatabase"), 
  'RDB_Final_Maps_Terrestrial')

RLH <- read_csv(here::here("Data", "EURLH","EURLH.csv"))

#### cut the European Union RLH data for the Macaronesian islands
EEZ.EU <- EEZ %>% 
  filter(grepl("Canary Islands|Madeira",UNAME)) %>% 
  st_transform(crs=st_crs(EURLH.mar))
EURLH.mar.qry <- EURLH.mar %>% st_intersection(EEZ.EU) %>% st_drop_geometry()
EURLH.ter.qry <- EURLH.ter %>% st_intersection(EEZ.EU) %>% st_drop_geometry()

cell_area <- EURLH.mar %>% st_area %>% mean %>% set_units('km2')

RLH_results <- RLH %>% select("Habitat Group":"Habitat Type Name",
               "Overall Category EU28") %>% 
  mutate(code=str_replace(`Habitat Type Name`,"<p>","") %>% 
           str_extract("[A-Z0-9a-z\\.]+")) %>% 
  filter(`Habitat Subgroup` %in% c("North East Atlantic",NA)) %>%
  select(code,`Overall Category EU28`)

tblT <- EURLH.ter.qry  %>% 
  group_by(code=str_replace(TYPE_CODE,"_","."), eco_name=TYPE_NAME) %>% 
  summarise(area_shape=sum(Shape_Area), 
            area=n()*cell_area,.groups="keep") %>%
  left_join(RLH_results, by="code")

tblT <- tblT %>%
  mutate(efg_code=case_when(
    grepl("dune", eco_name) ~ "MT2.1",
    grepl("sand beach", eco_name) ~ "MT1.3",
    grepl("heath", eco_name) ~ "T3.2",
    grepl("woodland", eco_name) ~ "T4.4",
    grepl("laurophyll", eco_name) ~ "T2.4",
    grepl("xerophytic scrub", eco_name) ~ "T5.2",
    grepl("volcanic", eco_name) ~ "T3.4",
    grepl("cliff and shore", eco_name) ~ "MT1.1",
    grepl("cliff|outcrops", eco_name) ~ "T3.4",
    grepl("sedge", eco_name) ~ "TF1.4",
    grepl("salt marsh", eco_name) ~ "MTF1.3",
    grepl("grassland", eco_name) ~ "T4.5",
    grepl("temporary", eco_name) ~ "F2.3",
    grepl("waterbody", eco_name) ~ "F2.2",
    grepl("riparian scrub", eco_name) ~ "T3.1",
    grepl("genistoid scrub", eco_name) ~ "T3.2",
    grepl("halo-nitrophilous scrub", eco_name) ~ "MT2.1",
    grepl("Phoenix", eco_name) ~ "TF1.2",
  )) 

tblT %>% 
  filter(!is.na(efg_code)) %>%
  pull(eco_name)

tblM <- EURLH.mar.qry  %>% 
  group_by(code=Habitat_co, eco_name=Habitat_na) %>% 
  summarise(area=n()*cell_area, .groups="keep") %>%
  left_join(RLH_results, by="code")

tblM <- tblM %>%
  mutate(efg_code=case_when(
    grepl("mearl beds", eco_name) ~ "M1.10",
    grepl("Seagrass", eco_name) ~ "M1.1",
    grepl("cochlear beds", eco_name) ~ "M1.4",
    grepl("seaweed", eco_name) ~ "M1.2",
    grepl("algae", eco_name) ~ "M1.2",
    grepl("algal", eco_name) ~ "M1.10",
    grepl("rock", eco_name) ~ "M1.6",
  )) 

tblM %>% 
  filter(is.na(efg_code)) %>%
  pull(eco_name)

combined_table <- tblM %>% bind_rows(tblT) %>%
  mutate(category = case_when(
    `Overall Category EU28` %in% "Data Deficient" ~ "DD",
    `Overall Category EU28` %in% "Least Concern" ~ "LC",
    `Overall Category EU28` %in% "Near Threatened" ~ "NT",
    `Overall Category EU28` %in% "Vulnerable" ~ "VU",
    `Overall Category EU28` %in% "Endangered" ~ "EN",
    `Overall Category EU28` %in% "Critically Endangered" ~ "CR",
    TRUE ~ "NE"
  ))

write_csv(combined_table, 
          file = 
            here::here("Data", "systematic-assessment-summaries",
                     "macaronesia-summary-RLE.csv"))

