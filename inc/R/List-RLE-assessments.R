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

# List of country iso codes in Africa ----
Africa <- read_sf(here::here("Data","Africa.gpkg")) 
Africa %>% st_drop_geometry %>% pull(ISO_A2) -> country.codes

# List of assessment units in those countries ----

drv <- dbDriver("PostgreSQL") ## remember to update .pgpass file
con <- dbConnect(drv, dbname = dbinfo[["database"]],
                 host = dbinfo[["host"]],
                 port = dbinfo[["port"]],
                 user = dbinfo[["user"]])

# use the 'overlap' opperator: &&

qrystr <- "SELECT asm_id, eco_id, eco_name,
    DATE(assessment_date), overall_risk_category,
    unnest(countries) as country, efg_code, level, assigned_by 
  FROM rle.assessment_units 
  LEFT JOIN rle.assessment_overall USING(eco_id) 
  LEFT JOIN rle.assessment_get_xwalk USING(eco_id) 
  WHERE countries && '{%s}'::text[]"

qry <- sprintf(qrystr,paste(country.codes,collapse=","))

assessments_africa <- dbGetQuery(con,qry)
dbDisconnect(con)


## Overview ----

dim(assessments_africa)
table(assessments_africa$efg_code)
table(assessments_africa$country)


## Combine with spatial data from national assessments ----

### South Africa ----
# Fix needed: data is missing...
za <- read_sf(here::here("Data","VEGMAP2018_Final.gdb"))
za %>% slice(1)
za %>% 
  st_drop_geometry() %>% 
  group_by(NBA2018_RLE_Status) %>% 
  summarise(biomes=n_distinct(BIOME_18),
            ecos=n_distinct(Name_18))

za %>% 
  mutate(mapped_area=
           st_area(Shape) %>% set_units("km^2")) %>% 
  st_drop_geometry %>% 
  group_by(BIOME_18,Name_18) %>% 
  summarise(category=paste(unique(NBA2018_RLE_Status),collapse=";"), 
            mapped_area=sum(mapped_area)) -> za_list


xwalk_file <- sprintf("%s/proyectos/UNSW/ecosphere-db/input/xwalks/GETcrosswalk_SouthAfricaTerrestrial_V2_17012020_DK.xlsx", Sys.getenv("HOME"))

xwalk <- read_excel(xwalk_file, sheet=4) %>% 
  rename("eco_name"=`SA Vegetation Class (vNVM2018). Note classes in blue font are described in`) %>% 
  filter(!is.na(eco_name))

newcolnames <- colnames(xwalk) %>% 
  str_replace( "^TM ","MT") %>% 
  str_replace("^FM ","FM") %>% 
  str_replace("^MFT ","MFT")

colnames(xwalk) <- newcolnames


xwalk %>% 
  pivot_longer(`T1.1Tropical/Subtropical lowland rainforests`:`MFT1.3 Coastal saltmarshes`,names_to = "efg", values_to="membership") %>% 
  filter(!is.na(membership)) %>% 
  transmute(eco_name, efg_code=str_extract(efg,"[A-Z0-9\\.]+"), membership) -> za_xwalk

za_list %>% 
  left_join(za_xwalk,by=c("Name_18"="eco_name")) %>% 
  group_by(efg_code) %>% 
  summarise(
    n=n_distinct(Name_18),
    estimated_area=sum(mapped_area*membership),
    category=paste(unique(category),collapse=";"))

## South Africa Marine data 
SA_mar <- read_sf(
  here::here("Data","ZAF", "NBA2018_Marine_ThreatStatus_ProtectionLevel.shp"))

 SA_mar %>% 
   st_drop_geometry() %>% 
   group_by(RLE_2018b) %>% 
   summarise(eco=n_distinct(MarineEco_))

 SA_mar %>% st_drop_geometry() %>% slice(1) %>% print.AsIs()
 SA_mar %>% st_drop_geometry() %>% pull(Ecosystem_) %>% table
 SA_mar %>% st_drop_geometry() %>% pull(BroadEcosy) %>% table
 
### Madagascar ----


### Congo ----

Congo <- read.dbf(here::here("Data","Congo","Congo_Basin_Forest_Ecosystems.tif.vat.dbf"))
head(Congo)

Congo_xwalk <- 
assessments_africa %>% 
  filter(asm_id %in% "Shapiro_CongoBasin_2020") %>% 
  mutate(Code=str_replace(eco_id,"Shapiro_CongoBasin_2020_","") %>% as.numeric)

Congo %>% 
  left_join(Congo_xwalk) %>% 
  select(Orig_Class, New_Class, Forest_Typ, eco_name, 
         overall_risk_category, efg_code, Area_ha) %>% 
  unique -> Congo_list

Congo_list %>% 
  mutate(efg_code=case_when(
    is.na(eco_name) ~ "T4.2",
    grepl("Montane Dense",New_Class) ~ "T1.3", 
    grepl("Evergreen",Forest_Typ) ~ "T1.1",
    grepl("Deciduous",Forest_Typ) ~ "T1.2", 
    TRUE~efg_code),
         Area_ha=set_units(Area_ha,'ha')) %>% 
  group_by(efg_code) %>% 
  summarise(n=n(),
            mapped_area=sum(Area_ha) %>% 
              set_units("km^2"),
            category = paste((overall_risk_category),collapse=";"))


head(Congo_list)      

### Mozambique ----

moz <- read_sf(here::here("Data","Moz","Moz_ecosystem_map_w_RLE_results_01Mar2021.shp"))
moz %>% slice(1)

moz %>% 
  mutate(mapped_area=st_area(geometry) %>% 
           set_units("km^2")) %>% 
  st_drop_geometry %>% 
  group_by(IUCN_Funct) %>% 
  summarise(n=n_distinct(Name),
            category=paste(unique(Overall__1),collapse=";"), 
            mapped_area=sum(mapped_area)) -> moz_list

moz_list

sum(moz_list$n)


## Read XML documents ----
## Fix needed: need to find a public location for these files, this path is broken

cape_flats <- read_xml(sprintf("%s/respaldo/databases/XML_v1.0/Strategic/Keith_CapeFlatsSandFynbos_2013_1.xml",Sys.getenv("HOME")))
cape_flats %>% xml_find_all(".//Case-Study-Name") %>% xml_text()
cape_flats %>% xml_find_all(".//Spatial-point") 

gonakier <- read_xml(sprintf("%s/respaldo/databases/XML_v1.0/Strategic/Keith_GonakierForest_2013_1.xml",Sys.getenv("HOME")))
gonakier %>% xml_find_all(".//Case-Study-Name") %>% xml_text()
gonakier %>% xml_find_all(".//Spatial-point") 

