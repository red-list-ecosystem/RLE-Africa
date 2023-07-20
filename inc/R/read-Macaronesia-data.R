require(sf)
require(dplyr)
library(readr)
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

RLH_results <- RLH %>% select("Habitat Group":"Habitat Type Name",
               "Overall Category EU28") %>% 
  mutate(code=str_replace(`Habitat Type Name`,"<p>","") %>% 
           str_extract("[A-Z0-9a-z\\.]+"))

tblT <- EURLH.ter.qry  %>% 
  group_by(code=str_replace(TYPE_CODE,"_","."), TYPE_NAME) %>% 
  summarise(area=sum(Shape_Area), .groups="keep") %>%
  left_join(RLH_results, by="code")

tblT <- tblT %>%
  mutate(efg_code=case_when(
    grepl("dune", TYPE_NAME) ~ "MT2.1",
    grepl("sand beach", TYPE_NAME) ~ "MT1.3",
    grepl("heath", TYPE_NAME) ~ "T3.2",
    grepl("woodland", TYPE_NAME) ~ "T4.4",
    grepl("laurophyll", TYPE_NAME) ~ "T2.4",
    grepl("xerophytic scrub", TYPE_NAME) ~ "T5.2",
    grepl("volcanic", TYPE_NAME) ~ "T3.4",
    grepl("cliff and shore", TYPE_NAME) ~ "MT1.1",
    grepl("cliff|outcrops", TYPE_NAME) ~ "T3.4",
    grepl("sedge", TYPE_NAME) ~ "TF1.4",
    grepl("salt marsh", TYPE_NAME) ~ "MTF1.3",
    grepl("grassland", TYPE_NAME) ~ "T4.5",
    grepl("temporary", TYPE_NAME) ~ "F2.3",
    grepl("waterbody", TYPE_NAME) ~ "F2.2",
    grepl("riparian scrub", TYPE_NAME) ~ "T3.1",
    grepl("genistoid scrub", TYPE_NAME) ~ "T3.2",
    grepl("halo-nitrophilous scrub", TYPE_NAME) ~ "MT2.1",
    grepl("Phoenix", TYPE_NAME) ~ "TF1.2",
  )) 

tblT %>% 
  filter(!is.na(efg_code)) %>%
  pull(TYPE_NAME)

tblM <- EURLH.mar.qry  %>% 
  group_by(code=Habitat_co, Habitat_na) %>% 
  summarise(area=n()*10000, .groups="keep") %>%
  left_join(RLH_results, by="code")

tblM <- tblM %>%
  mutate(efg_code=case_when(
    grepl("mearl beds", Habitat_na) ~ "M1.10",
    grepl("Seagrass", Habitat_na) ~ "M1.1",
    grepl("cochlear beds", Habitat_na) ~ "M1.4",
    grepl("seaweed", Habitat_na) ~ "M1.2",
    grepl("algae", Habitat_na) ~ "M1.2",
    grepl("algal", Habitat_na) ~ "M1.10",
    grepl("rock", Habitat_na) ~ "M1.6",
  )) 

tblM %>% 
  filter(is.na(efg_code)) %>%
  pull(Habitat_na)


library(ggplot2)
library(treemapify)

tbl <- tblM %>% bind_rows(tblT) %>%
  mutate(category = case_when(
    `Overall Category EU28` %in% "Data Deficient" ~ "DD",
    `Overall Category EU28` %in% "Least Concern" ~ "LC",
    `Overall Category EU28` %in% "Near Threatened" ~ "NT",
    `Overall Category EU28` %in% "Vulnerable" ~ "VU",
    `Overall Category EU28` %in% "Endangered" ~ "EN",
    `Overall Category EU28` %in% "Critically Endangered" ~ "CR",
  ))
clrs <- c(
  "NE" = "white",
  "DD" = "grey",
  "LC" = "green4",
  "NT" = "green",
  "VU" = "yellow",
  "EN" = "orange",
  "CR" = "red")

ggplot(tbl, 
       aes(area=`area`, fill = category, label = code,
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
    title = "Ecosystems of Macaronesia (Canary Island and Madeira)",
    subtitle='Each box is an assessment unit\ngrouped by biome or ecosystem functional groups.', fill='Risk category')
