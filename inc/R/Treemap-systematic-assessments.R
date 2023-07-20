# Set up ----

## libraries
require(sf)
require(dplyr)
library(readxl)
library(stringr)
#require(foreign)
#require(units)
#require(magrittr)
require(tidyr)
library(treemapify)
library(ggplot2)

## working directory
here::i_am("inc/R/Treemap-systematic-assessments.R")


## South Africa ----

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



clrs <- c(
  "NE" = "white",
  "DD" = "grey",
  "LC" = "green4",
  "NT" = "green",
  "VU" = "yellow",
  "EN" = "orange",
  "CR" = "red")


ggplot(tbl, aes(area=estimated_area, fill = category, label = NAME,
               subgroup = efg_code)) +
  geom_treemap() +
  geom_treemap_subgroup_text(
    place = "bottomleft", 
    grow = F, 
    alpha = 0.35, 
    #colour = thm_clrs[1], 
    fontface = "italic", 
    min.size = 0) +
  geom_treemap_subgroup_border() +
  scale_fill_manual(values=clrs) +
  labs(
    title = "Terrestrial ecosystems in South Africa",
    subtitle='Each box is an assessment unit\ngrouped by ecosystem functional groups.', fill='Risk category')

ggsave(here::here("Output", "Treemap-Example-terrestrial-South-Africa.png"))



## Madagascar ----

# Fix needed: data is missing...
library(readr)
WIO <- read_csv(here::here("Data", "WIO", "WIO-M1.3-results.csv"))


ggplot(WIO, aes(area=area_km2, fill = category, label = eco_name,
                 subgroup = efg_code)) +
  geom_treemap() +
  geom_treemap_subgroup_text(
    place = "bottomleft", 
    grow = F, 
    alpha = 0.35, 
    #colour = thm_clrs[1], 
    fontface = "italic", 
    min.size = 0) +
  geom_treemap_subgroup_border() +
  scale_fill_manual(values=clrs) +
  labs(
    title = "Coral reefs of Western Indian Ocean",
    subtitle='Each box is an assessment unit\ngrouped by biome or ecosystem functional groups.', fill='Risk category')

ggsave(here::here("Output", "Treemap-Example-terrestrial-WIO.png"))

## Madagascar ----

# Fix needed: data is missing...
library(readr)
mada <- read_csv(here::here("Data", "Mada", "madagascar-summary-RLE.csv"))


ggplot(mada, aes(area=area_km2, fill = category, label = eco_name,
                subgroup = efg)) +
  geom_treemap() +
  geom_treemap_subgroup_text(
    place = "bottomleft", 
    grow = F, 
    alpha = 0.35, 
    #colour = thm_clrs[1], 
    fontface = "italic", 
    min.size = 0) +
  geom_treemap_subgroup_border() +
  scale_fill_manual(values=clrs) +
  labs(
    title = "Ecosystems of Madagascar",
    subtitle='Each box is an assessment unit\ngrouped by biome or ecosystem functional groups.', fill='Risk category')

ggsave(here::here("Output", "Treemap-Example-terrestrial-Madagascar.png"))



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

tbl <- Congo_list %>% filter(!is.na(efg_code))
ggplot(tbl, aes(area=Area_ha, fill = overall_risk_category, label = eco_name,
                 subgroup = efg_code)) +
  geom_treemap() +
  geom_treemap_subgroup_text(
    place = "bottomleft", 
    grow = F, 
    alpha = 0.35, 
    #colour = thm_clrs[1], 
    fontface = "italic", 
    min.size = 0) +
  geom_treemap_subgroup_border() +
  scale_fill_manual(values=clrs) +
  labs(
    title = "Ecosystems of the Congo basin",
    subtitle='Each box is an assessment unit\ngrouped by biome or ecosystem functional groups.', fill='Risk category')

ggsave(here::here("Output", "Treemap-Example-terrestrial-Congo.png"))

### Mozambique ----

moz <- read_sf(here::here("Data","Moz","Moz_ecosystem_map_w_RLE_results_01Mar2021.shp"))
moz %>% slice(1)

tbl <- moz %>% filter(!is.na(IUCN_Funct))  %>% 
  mutate(efg_code=str_extract(IUCN_Funct,"[A-Z0-9\\.]+"))

ggplot(tbl, aes(area=`2016_Area`, fill = Overall__1, label = Name,
                subgroup = efg_code)) +
  geom_treemap() +
  geom_treemap_subgroup_text(
    place = "bottomleft", 
    grow = F, 
    alpha = 0.35, 
    #colour = thm_clrs[1], 
    fontface = "italic", 
    min.size = 0) +
  geom_treemap_subgroup_border() +
  scale_fill_manual(values=clrs) +
  labs(
    title = "Ecosystems of Mozambique",
    subtitle='Each box is an assessment unit\ngrouped by biome or ecosystem functional groups.', fill='Risk category')

ggsave(here::here("Output", "Treemap-Example-terrestrial-Mozambique.png"))



