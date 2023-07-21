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
library(readr)

## working directory
here::i_am("inc/R/Treemap-systematic-assessments.R")


## Read tables ----
WIO <- read_csv(here::here("Data", "systematic-assessment-summaries", 
                           "WIO-summary-RLE.csv"))
mada <- read_csv(here::here("Data", "systematic-assessment-summaries",
                            "madagascar-summary-RLE.csv"))
macaronesia <- read_csv(here::here("Data", "systematic-assessment-summaries",
                            "macaronesia-summary-RLE.csv"))
congo <- read_csv(here::here("Data", "systematic-assessment-summaries",
                            "congo-summary-RLE.csv"))
mozambique <- read_csv(here::here("Data", "systematic-assessment-summaries",
                            "mozambique-summary-RLE.csv"))


## Colours ----

clrs <- c(
  "NE" = "white",
  "DD" = "grey",
  "LC" = "green4",
  "NT" = "green",
  "VU" = "yellow",
  "EN" = "orange",
  "CR" = "red")

## Plots ----

ggplot(macaronesia, 
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

ggsave(here::here("Output", "Treemap-Example-terrestrial-Macaronesia.png"))


## South Africa ----

ggplot(southafrica, aes(area=estimated_area, fill = category, label = NAME,
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



## WIO ----

# Fix needed: data is missing...

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


ggplot(congo, aes(area=Area_ha, fill = overall_risk_category, label = eco_name,
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


ggplot(mozambique, aes(area=area_km, fill = category, label = eco_name,
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



