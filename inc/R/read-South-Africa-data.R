## libraries
require(sf)
require(dplyr)
library(readxl)
library(stringr)
require(tidyr)
library(readr)

## working directory
here::i_am("inc/R/read-South-Africa-data.R")


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


zam <- read_sf(here::here("Data", "ZAF", "NBA2018_Marine_ThreatStatus_ProtectionLevel.gdb"))
zam %>% slice(1) 

zam_list <- 
  zam %>% 
  st_drop_geometry() %>% 
  filter(!is.na(BroadEcosystemGroup)) %>%
  group_by(BroadEcosystemGroup,Ecosystem_Primary) %>% 
  summarise(category=paste(unique(RLE_2018b),collapse=";"), 
            mapped_area=sum(Shape_Area),
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

write_csv(tbl, file = here::here("Data", "systematic-assessment-summaries",
                                 "south-africa-summary-RLE.csv"))



tbl <- zam_list %>% 
  left_join(za_xwalk,by=c("Ecosystem_Primary"="eco_name"))  %>% 
  transmute(efg_code, 
            biome_code = str_extract(efg_code, "[A-Z0-9]+"),
            mapped_area,
            estimated_area=sum(mapped_area*membership),
            category) %>%
  mutate(
    efg_code = case_when(
      is.na(efg_code) & BroadEcosystemGroup %in% "Abyss" ~ "M3.3",
      is.na(efg_code) & BroadEcosystemGroup %in% "Bay" ~ "FM1.2",
      is.na(efg_code) & BroadEcosystemGroup %in% "Canyon" ~ "M3.2",
      is.na(efg_code) & BroadEcosystemGroup %in% "Kelp forest" ~ "M1.2",
      is.na(efg_code) & BroadEcosystemGroup %in% "Sandy shore" ~ "MT1.3",
      is.na(efg_code) & BroadEcosystemGroup %in% "Shallow soft shelf" ~ "MT1.7",
      is.na(efg_code) & BroadEcosystemGroup %in% "Deep soft shelf" ~ "MT1.7",
      is.na(efg_code) & BroadEcosystemGroup %in% "Shallow rocky shelf" ~ "MT1.6",
      is.na(efg_code) & BroadEcosystemGroup %in% "Deep rocky shelf" ~ "MT1.5",
      is.na(efg_code) & BroadEcosystemGroup %in% "Rocky and mixed shore" ~ "MT1.1",
      is.na(efg_code) & BroadEcosystemGroup %in% "Island" ~ "MISSING",
      TRUE ~ efg_code
    )
  )

tbl %>% filter(is.na(efg_code)) %>% pull(BroadEcosystemGroup) %>% table

write_csv(tbl, file = here::here("Data", "systematic-assessment-summaries",
                                 "south-africa-marine-summary-RLE.csv"))
