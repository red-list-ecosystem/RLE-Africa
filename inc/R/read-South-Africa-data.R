## libraries
require(sf)
require(dplyr)
library(readxl)
library(stringr)
#require(foreign)
#require(units)
#require(magrittr)
require(tidyr)
#library(readr)

## working directory
here::i_am("inc/R/read-South-Africa-data.R")


# Fix needed: data is missing...
za <- read_sf(here::here("Data", "ZAF", "NBA2018_Terrestrial_ThreatStatus_ProtectionLevel.gdb"))
za %>% slice(1) %>% select(RLEv5)

za %>% 
  st_drop_geometry() %>% 
  group_by(RLEv5) %>% 
  summarise(biomes=n_distinct(BIOME),
            ecos=n_distinct(NAME))

za_list <- 
  za %>% 
  group_by(BIOME,NAME) %>% 
  summarise(category=paste(unique(RLEv5),collapse=";"), 
            mapped_area=sum(SA_Nat2014),
            .groups="keep")

xwalk_file <- here::here("Data", "ZAF", "GETcrosswalk_SouthAfricaTerrestrial_V2_17012020_DK.xlsx")

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
  left_join(za_xwalk,by=c("NAME"="eco_name")) %>% 
  group_by(efg_code) %>% 
  summarise(
    n=n_distinct(NAME),
    estimated_area=sum(mapped_area*membership),
    category=paste(unique(category),collapse=";"))

tbl <- za_list %>% 
  left_join(za_xwalk,by=c("NAME"="eco_name"))  %>% 
  transmute(efg_code, 
            biome_code = str_extract(efg_code, "[A-Z0-9]+"),
            mapped_area,
            estimated_area=sum(mapped_area*membership),
            category)

