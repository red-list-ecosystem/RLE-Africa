# Set up ----

## libraries
require(dplyr)
library(treemapify)
library(ggplot2)
library(readr)
library(cowplot)
library(stringr)
library(units)

## working directory
here::i_am("inc/R/Treemap-systematic-assessments.R")


## Colours ----

# Tested this colour scheme with 
# https://pilestone.com/pages/color-blindness-simulator-1

clrs <- c(
  "NE" = "white",
  "DD" = "grey45",
  "LC" = "palegreen4",
  "NT" = "honeydew3",
  "VU" = "yellow3",
  "EN" = "orange",
  "CR" = "red4")



## Functions ----

treemap_plot <- function(X) {
  required_cols <- c("assessment_area", "category", "eco_name", "efg_code")
  stopifnot(required_cols %in% colnames(X))
  p <- ggplot(X, 
              aes(area=assessment_area, 
                  fill = category, 
                  label = eco_name,
                  subgroup = efg_code)) +
    geom_treemap(colour="black") +
    geom_treemap_subgroup_text(
      place = "bottomleft", 
      grow = FALSE, 
      alpha = 0.85, 
      colour = "whitesmoke", 
      fontface = "italic", 
      min.size = 0) +
    geom_treemap_subgroup_border(colour="black") +
    scale_fill_manual(values=clrs)
  return(p)
}


## Read tables ----

lookup <- c(eco_name = c("Name", "NAME", "Ecosystem_Primary"), 
            assessment_area = 
              c("area", "Area_ha", "area_km2", "estimated_area"),
            efg_code = "efg",
            category = "overall_risk_category")


WIO <- read_csv(here::here("Data", "systematic-assessment-summaries", 
                           "WIO-summary-RLE.csv")) %>% 
  rename(any_of(lookup)) %>% rename_with(~str_replace(.x,"[0-9]$",""))

madagascar <- read_csv(here::here("Data", "systematic-assessment-summaries",
                            "madagascar-summary-RLE.csv")) %>% 
  rename(any_of(lookup)) %>% rename_with(~str_replace(.x,"[0-9]$",""))

macaronesia <- read_csv(here::here("Data", "systematic-assessment-summaries",
                            "macaronesia-summary-RLE.csv")) %>% 
  rename(any_of(lookup)) %>% rename_with(~str_replace(.x,"[0-9]$",""))

congo <- read_csv(here::here("Data", "systematic-assessment-summaries",
                            "congo-summary-RLE.csv")) %>% 
  rename(any_of(lookup)) %>% rename_with(~str_replace(.x,"[0-9]$",""))

mozambique <- read_csv(here::here("Data", "systematic-assessment-summaries",
                            "mozambique-summary-RLE.csv")) %>% 
  rename(any_of(lookup)) %>% rename_with(~str_replace(.x,"[0-9]$",""))

southafrica <- read_csv(here::here("Data", "systematic-assessment-summaries",
                                   "south-africa-summary-RLE.csv"))%>% 
  rename(any_of(lookup)) %>% rename_with(~str_replace(.x,"[0-9]$",""))

southafrica_mar <- read_csv(here::here("Data", "systematic-assessment-summaries",
                                   "south-africa-marine-summary-RLE.csv"))%>% 
  rename(any_of(lookup)) %>% rename_with(~str_replace(.x,"[0-9]$",""))


### Strategic assessments ----

strategics <- read_csv(
  here::here("Data", "strategic-assessment-summaries",
  "all-strategic-assessments.csv"))

strategics <- 
  bind_rows(
    {strategics %>% 
      filter(area_units %in% 'km2') %>% 
      mutate(assessment_area=set_units(assessment_area,'km2'))
    },
    {strategics %>% 
      filter(area_units %in% 'ha') %>% 
      mutate(assessment_area=set_units(assessment_area,'ha'))
    }
  ) %>% 
  select(-area_units) ## everything now in km2

### Verify tables ----

## double checked:
# -	Included 11 strategic assessments, areas from assessment database or original publication,
# -	Corrected areas for Congo (from ha to km2), data from attribute tables,
# -	Checked areas for Mozambique (area in km2), data from attribute table represents estimated 2016 extent,
# -	Data from Madagascar was entered manually from publication and supplementary data,
# -	Data from WIO Coral reefs was entered manually from publication,
# -	Reviewed the Macaronesia units to remove duplicates and correct areas, area calculated from AOO grid,
# -	South Africa, had an issue with units assigned to more than one efg and areas were calculated erroneously or doubled counted, now units are assigned to one principal unit (to simplify the table), area from attribute table represents estimated 2014 extent for terrestrial (assuming it is km2) and “Type extent in km” for marine,


all_data <- 
  bind_rows(
    strategics %>% drop_units(),
    southafrica %>% 
              mutate(assessment="South Africa (terrestrial)"),
            mozambique %>% mutate(assessment="Mozambique"),
            madagascar %>% mutate(assessment="Madagascar"), 
            congo %>% mutate(assessment="Congo basin")) %>%
  bind_rows(southafrica_mar %>% mutate(assessment="South Africa (marine)"), 
            macaronesia %>% 
              mutate(assessment="Macaronesia"), 
            WIO %>% mutate(assessment="Western Indian Ocean")) %>%
  group_by(assessment, eco_name) %>%
  summarise(efg_code = paste(unique(efg_code), collapse = ";"),
            assessment_area = max(assessment_area),
            category = first(category),
            .groups="keep")

EFGinfo <- readxl::read_excel(here::here("Data","IUCN-GET-profiles-exported-2023-06-14.xlsx"), sheet=2) %>% 
  transmute(efg_code = code, efg_name = str_replace(`short name`,"Seas ", "Seasonal "))

all_data <- all_data %>% 
  left_join(EFGinfo, by=c("efg_code"))

# this is the output from files combined above
write_csv(
  all_data,
  here::here("Data", "systematic-assessment-summaries",
             "Supplementary-table-systematic-assessment-summary.csv"))
# We can read the file shared by David, which contains the data above + his comments and edits 
here::here("Data", 
           "All-assessments-summary-JRFP-DK.xlsx")

## Main systematic assessments; plots for MS ----

### All together ----

all_data <- bind_rows(southafrica,mozambique,madagascar,congo) %>% 
  filter(!is.na(assessment_area),!is.na(efg_code)) %>%
  mutate(efg_code=str_extract(efg_code,"[A-Z0-9]+"),
         category = if_else(category %in% "NE","DD",category),
         category = factor(category, levels=names(clrs)))

all_plot <- treemap_plot(all_data) +
  labs(fill = "Risk category")

### Madagascar ----

other_efgs <- c("T3.1", "FM1")
other_efgs <- c("F2","F1","FM1", "T3.4", "TF1.1", "MFT1.1", "MFT1.2", "MT2.1", "M1.1", "T3.1")
mada_data <- madagascar %>% 
  filter(!is.na(assessment_area)) %>%
  mutate(
    category = if_else(category %in% "NE","DD",category),
    efg_code = if_else(efg_code %in% other_efgs, "others: T3.4, TF1, F1, F2, FM1, MFT1, MT1, M1.1, T3.1", efg_code),
    efg_code = str_wrap(efg_code,18)) 

mada_plot <- treemap_plot(mada_data) +
  labs(title = "Ecosystems of Madagascar") + theme(legend.position = "none")

mada_plot +
  labs(subtitle='Each box is an assessment unit\ngrouped by biome or ecosystem functional groups.', fill='Risk category')

### Congo ----

other_efgs <- c("T1.3", "MFT1.2", "TF1.1")


congo_data <- congo %>%
  mutate(efg_code = if_else(efg_code %in% other_efgs, "others: TF1.1, T1.3, MFT1.2", efg_code),
         efg_code = str_wrap(efg_code,12))


congo_plot <- treemap_plot(congo_data) +
  labs(title = "Congo basin") + theme(legend.position = "none")

congo_plot

### Mozambique ----
mft_efgs <- c("MFT", "MFT1.1", "MFT1.2", "MFT1.3")
other_efgs <- c("MT1.3", "T1.3", "MT2.1","T4.5", 
                "F2.2", "F2.3", "F1.5", "T3.1", "T1.1")
mozambique_data <- mozambique %>% 
  mutate(efg_code = case_when(
    efg_code %in% other_efgs ~ "others: T1.1, T1.3, T3.1, T4.5, F2, F1, MT1, MT2",
    efg_code %in% mft_efgs ~ "MFT1",
    TRUE ~ efg_code),
    efg_code = str_wrap(efg_code,18))

moz_plot <- treemap_plot(mozambique_data) +
  labs(title = "Mozambique") + theme(legend.position = "none")

moz_plot

### South Africa ----

zaf_data <- southafrica %>% 
  filter(!is.na(assessment_area))

zaf_data %>% 
  group_by(efg_code) %>% 
  summarise(total=sum(assessment_area)) %>% 
  arrange(total)

other_efgs <- c("T1.2", "T1.3", "T2.3", "T2.4",  
                "T3.1", "T4.4", "T5.5", 
                "MT2.1", "MFT1.2")

zaf_data <- zaf_data %>% 
  mutate(
    efg_code = case_when(
      is.na(efg_code) ~ "unclassified",
      efg_code %in% other_efgs ~ 
        "others: T1.2, T1.3, T2.3, T2.4, T3.1, T4.4, T5.5, MT2.1, MFT1",
      TRUE ~ efg_code),
    efg_code = str_wrap(efg_code,18))

zaf_plot <- treemap_plot(zaf_data) +
  labs(title = "South Africa") + theme(legend.position = "none")
zaf_plot



### Create and export grid of plots ----

pgrid <- plot_grid(
  congo_plot + labs(title = element_blank()), 
  mada_plot + labs(title = element_blank()),
  zaf_plot + labs(title = element_blank()), 
  moz_plot + labs(title = element_blank()),
  labels = c("A", "B", "C","D"),
  hjust = -1,
  vjust=3,
  greedy = TRUE
)

# extract a legend that is laid out horizontally
legend_b <- get_legend(
  all_plot + 
    guides(fill = guide_legend(nrow = 1)) +
    theme(legend.position = "bottom")
)
plot_grid(pgrid, legend_b, ncol = 1, rel_heights = c(1, .1))

ggsave(here::here("Output", "Treemap-Example-4-assessments.png"),
       width = 7.5, height = 7)


## Preliminary systematic assessments for Supplement ----

### Macaronesia ----

other_efgs <- c("T4.5","F2.2", "TF1.4","F2.3", "MTF1.3")
macaronesia_data <- macaronesia %>% 
  mutate(efg_code = if_else(efg_code %in% other_efgs, "others: MFT1, F2, TF1, T4.5", efg_code),
         efg_code = str_wrap(efg_code,18),
         category = if_else(category %in% "NE","DD",category))

macaronesia_plot <- treemap_plot(macaronesia_data) 

macaronesia_plot +
  theme_cowplot(12) +
  labs(
    title = "Ecosystems of Macaronesia (Canary Island and Madeira)",
    subtitle='Each tile is an assessment unit, size proportional to area\ngrouped by biome or ecosystem functional groups.', fill='Risk category')

ggsave(here::here("Output", "Treemap-Example-terrestrial-Macaronesia.png"))

### WIO ----

WIO_plot <- treemap_plot(WIO) 
WIO_plot +
  labs(title = "Coral reefs of Western Indian Ocean",subtitle='Each box is an assessment unit\ngrouped by biome or ecosystem functional groups.', fill='Risk category')

### South Africa Marine ----

zafm_data <- southafrica_mar %>% 
  filter(!is.na(assessment_area))

zafm_data %>% 
  group_by(efg_code) %>% 
  summarise(total=sum(assessment_area)) %>% 
  arrange(total)

mts_efgs <- c("MISSING")

other_efgs <- c("MT1.1", 
                "MT1.3","M3.4",
                "MT1.4","M1.3", 
                "M1.6","FM1.2", 
                "M3.2", "M1.2")


zafm_data <- zafm_data %>% 
  mutate(
    efg_code = case_when(
      efg_code %in% mts_efgs ~ 
        "unclassified",
      efg_code %in% other_efgs ~ 
        "others: MT1, M1.2, M1.3, M1.6, M3.2, M3.4, FM1.2",
      TRUE ~ efg_code),
    efg_code = str_wrap(efg_code,18))

zafm_plot <- treemap_plot(zafm_data)  + theme(legend.position = "none")
zafm_plot +
  labs(title = "South Africa")



### Create and export grid of plots ----
# extract a legend that is laid out vertically
legend_c <- get_legend(
  all_plot + 
    guides(fill = guide_legend(ncol = 1)) +
    theme(legend.position = "right")
)

pgrid <- plot_grid(
  zafm_plot,
  macaronesia_plot + theme(legend.position = "none"),
  WIO_plot + theme(legend.position = "none"), 
   legend_c,
  labels = c("A", "B", "C"),
  hjust = -1,
  vjust=2,
  greedy = TRUE
)

pgrid

ggsave(here::here("Output", "Treemap-preliminary-assessments.png"),
       width = 7.5, height = 7)





## Export output plots ----

ggsave(moz_plot,
       filename = 
         here::here("Output", "Treemap-Example-terrestrial-Mozambique.png"))
ggsave(congo_plot,
       filename = 
         here::here("Output", "Treemap-Example-terrestrial-Congo.png"))
ggsave(zaf_plot,
       filename = 
         here::here("Output", "Treemap-Example-terrestrial-South-Africa.png"))
ggsave(WIO_plot,
       filename = 
         here::here("Output", "Treemap-Example-terrestrial-WIO.png"))

ggsave(mada_plot,
       filename = 
         here::here("Output", "Treemap-Example-terrestrial-Madagascar.png"))



