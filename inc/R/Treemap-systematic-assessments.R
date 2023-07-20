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



## South Africa ----

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



# extract biome code, summarise category per biome and create barplot...
tbl <- assessments_africa %>% 
  filter(country %in% "MG", asm_id %in% "Carre_RLE_Madagascar_2020") %>%
  mutate(code=str_extract(efg_code,"[A-Z0-9]+"),
         cat=factor(overall_risk_category, levels=names(clrs)))

ce <- tbl %>% 
  filter(!is.na(cat), !is.na(code)) %>% 
  group_by(code, cat) %>%
  summarise(total=n(),.groups="keep") %>%
  arrange(code, desc(cat))

ce <- ce %>%
  group_by(code) %>%
  mutate(label_y = cumsum(total)/sum(total))

ce



ggplot(ce, aes(x = code, y = total, fill = cat)) +
  geom_col(position = "fill") +
  geom_text(aes(y = label_y, label = total), 
            nudge_y=-.02, #vjust = 1.5, 
            colour = "black", size=3, angle=90) +
  scale_fill_manual(values=clrs) +
  theme_minimal() +
  #labs(title=COL_pol$FORMAL_EN) +
  theme(legend.position = "none") +
  labs(x = element_blank(), y = element_blank()) + 
  coord_flip()
## ggsave(filename = "Madagascar-RLE-cat-EFG-barplot.png", width=5, height = 3, units = "in")


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
 
