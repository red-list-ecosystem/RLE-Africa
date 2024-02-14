# Load libraries ----

require(sf)
require(dplyr)
library(lwgeom)
require(vroom)
require(ggplot2)
library(jsonlite)
library(stringr)

# set up project root using `here` ----
here::i_am("inc/R/EFG-plot.R")

# read description of functional groups ----

EFGinfo <- readxl::read_excel(here::here("Data","IUCN-GET-profiles-exported-2023-06-14.xlsx"), sheet=2) %>% 
  mutate(`short name` = str_replace(`short name`,"Seas ", "Seasonal "))

biome_info <- read_json("https://raw.githubusercontent.com/red-list-ecosystem/typology-map-data/master/data/config/biomes.json",
                        simplifyVector = TRUE) 

biome_names <- biome_info[["title"]]$en
biome_ids <- biome_info$id

EFGinfo$biome_name <- biome_names[match(EFGinfo$`biome code`,biome_ids)] 
# %>% str_replace(" biome", "")

# read areas of functional groups per country ----

myMergedData <- vroom(
  dir(
    here::here("Data","area-calc","areas-per-country/"),
    full.names=T
    )
  )

# create summaries per group ----

DataEFGs <- 
  myMergedData %>% 
  mutate(code=gsub("([MFTS0-9\\.]+)-[a-z_.]+","\\1",code)) %>%
  group_by(code) %>% 
  summarise(
    countries=n_distinct(OBJECTID),
    major=sum(major)*100,
    minor=sum(minor)*100,
    both=sum(both)*100) %>% 
  mutate(biome=gsub("([MFTS0-9]+).[0-9]+","\\1",code)) %>% 
  left_join(select(EFGinfo,c(code,`short name`,biome_name)),by="code") %>%
  mutate(
    biome_name = str_replace_all(biome_name, "emi-", "emi"),
    `short name` = str_replace_all(`short name`, "emi-", "emi"),
    name=str_replace_all(`short name`," ","\n"))

# check summaries for all of Africa ----

DataEFGs %>% 
  filter(!biome %in% c("M2","M3")) %>% 
  arrange(desc(major)) 

DataEFGs %>% 
  filter(!biome %in% c("M2","M3"))  %>% 
  group_by(biome) %>% 
  summarise(EFGs=n_distinct(code)) %>% 
  arrange(desc(EFGs)) 

# groups of biomes by realm ----

DataEFGs %>% distinct(biome) %>% pull

terr.biomes <- sprintf("T%s",1:6)
fresh.biomes <- c(sprintf("F%s",1:2),"TF1","S1","SF1")
mar.biomes <- c(sprintf("MT%s",1:2),"MFT1","M1","FM1","SM1")

# test of base plot with error bars ----

p <- ggplot(
  DataEFGs %>% filter(major>0, biome %in% mar.biomes), 
  aes(y=`short name`, x=major, fill=biome_name)) + 
  geom_bar(width=1, stat='identity') + 
  theme_light() +
  theme(legend.position = "none")

p + 
  theme(axis.text.x = element_text(angle=45, vjust = 1, hjust=1)) + 
  xlab("Ecosystem Functional Group") + 
  ylab("Global major distribution (%)") + 
  geom_errorbar(aes(xmin=major,xmax=both))

# test of polar plot with error bars ----

p <- ggplot(
  DataEFGs %>% filter(major>0, biome %in% mar.biomes), 
  aes(x=`name`, y=major, fill=biome_name)) + 
  geom_bar(width=1, stat='identity') + 
  theme_light() +
  theme(legend.position = "none")

p + 
  coord_polar() + 
  labs(title="Ecosystems in Africa", 
       x="Ecosystem Functional Group", 
       y="Global major distribution (%)",
       fill="Biome") + 
  geom_errorbar(aes(ymin=major,ymax=both))


# Polar plot with shaded intervals ----

coord_plot <- function(dat, flt, plot_title) {
  p <- ggplot(dat %>% filter(major>0, biome %in% flt)) + 
    geom_bar(aes(x=name, y=major, fill=str_wrap(biome_name, width=18)), 
             width=1, stat='identity',alpha=.3, col='black') + 
    geom_bar(aes(x=name, y=both, fill=str_wrap(biome_name, width=18)),
             width=1, stat='identity',alpha=.3, col='black') + 
    theme_light() +
    coord_polar() + 
    labs(title=plot_title, 
         x="Ecosystem Functional Group",
         y="Global major distribution (%)", fill="Biomes") +
    theme(
      legend.position = "right",
      legend.text = element_text(size=8),
      legend.spacing.y = unit(0.2, 'cm'),
      legend.spacing.x = unit(0.2, 'cm')) +
    ## important additional element
    guides(fill = guide_legend(byrow = TRUE))
  
  return(p)
}

plotT <- 
  coord_plot(
    DataEFGs,
    terr.biomes, 
    "Terrestrial realm") 

plotF <- 
  coord_plot(
    DataEFGs,
    fresh.biomes, 
    "Freshwater and Subterranean (+ transitions)") 

plotM <- 
  coord_plot(
    DataEFGs,
    mar.biomes, 
    "Marine realm (+ transitions)") 


ggsave(here::here("Output","Fig1a-Terrestrial-EFG.png"), 
       plotT, width=7, height=5)
ggsave(here::here("Output","Fig1b-Freshwater-EFG.png"), 
       plotF, width = 7, height = 5)
ggsave(here::here("Output","Fig1c-Marine-EFG.png"), 
       plotM, width = 7, height = 5)


# Alternative with horizontal bars ----

coord_plot <- function(dat, flt, plot_title, add_note=T) {
  dts <- dat %>% filter(both>0.01, biome %in% flt)
  lvs <- unique(c(dts %>% pull(`biome`),
           dts %>% pull(`short name`))) %>% sort()
  dts <- dts %>% mutate(efg_name=factor(`short name`, levels=lvs), 
                        yloc=as.numeric(efg_name))
  brks <- unique(dts %>% pull(`short name`))
  grps <- dts %>% distinct(biome,biome_name) %>%
    mutate(biome=factor(`biome`, levels=lvs), 
           yloc=as.numeric(biome))
  
    p <- ggplot() + 
      scale_y_discrete(limits=rev, breaks=brks, drop=FALSE) +
      geom_text(data=grps,
                aes(y=biome, x=0.1,
                    label=biome_name, col=biome),
                adj=0, size=3) +
    geom_bar(data=dts, aes(y=efg_name, x=major, fill=`biome`), 
             width=1, stat='identity',alpha=.3, col='black') + 
    geom_bar(data=dts, aes(y=efg_name, x=both, fill=`biome`),
             width=1, stat='identity',alpha=.3, col='black') +
    theme_bw() +
      labs(title=plot_title, 
           y=element_blank(),
           x="Global major distribution (%)", fill="Biomes") +
      theme(
        legend.position = "none",
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()
      )
    if (add_note) {
      p <- p + 
        geom_text(data=dts %>% filter(both<2),
                  aes(y=efg_name, x=both,
                      label=sprintf("%0.3f %%",both)),
                  adj=-.1, size=2.5) 
    }
  return(p)
}

plotThoz <-  
  coord_plot(DataEFGs, terr.biomes, plot_title="Terrestrial realm") 
plotFhoz <-  coord_plot(DataEFGs, fresh.biomes, 
                        plot_title="Freshwater and Subterranean (+ transitions)") 

plotMhoz <- coord_plot(DataEFGs,
                       mar.biomes, 
                       plot_title="Marine realm (+ transitions)",
                         add_note = FALSE)

ggsave(here::here("Output","Fig1a-Terrestrial-EFG-horiz.png"), 
       plotThoz,
       width=7,
       height=5)
ggsave(here::here("Output","Fig1b-Freshwater-EFG-horiz.png"), 
       plotFhoz,
       width=7,
       height=5)
ggsave(here::here("Output","Fig1c-Marine-EFG-horiz.png"), 
       plotMhoz,
       width=7,
       height=5)
