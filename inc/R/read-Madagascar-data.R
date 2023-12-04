require(sf)
require(dplyr)
library(readr)
library(magrittr)
library(xml2)
here::i_am("inc/R/read-Madagascar-data.R")

##shp <- read_sf(here::here("Data","Mada","layers","100001.shp"))
##shp %>% st_drop_geometry() # not very informative
##shp %>% st_area %>% set_units("km^2")

# we could read Mada/Moat\ _\ Murray\ Madagascar\ ecosystem\ types.qgs as an xml file
shpinfo <- read_xml(here::here("Data","Mada", "Moat\ _\ Murray\ Madagascar\ ecosystem\ types.qgs"))
shpinfo %>% 
  xml_find_all(".//legendlayer") %>% 
  xml_attr("name") %>% 
  str_split_fixed(" ",n=2) %>% 
  data.frame()  -> mada.ecos 
colnames(mada.ecos) <- c("code","name")

mada.ecos %<>% tibble()
#shpinfo %>% xml_find_first(".//legendlayer") %>% xml_attr("name")
#shpinfo %>% xml_find_all(".//legendlayer[starts-with(@name,100001)]") %>% xml_attr("name")

mada.ecos %<>% 
  mutate(file=sprintf("%s/%s.shp",here::here("Data","Mada","layers"),code)) %>% 
  mutate(efile=file.exists(file),
         mapped_area=set_units(0,"km^2"),
         npols=0,
         lon=as.numeric(NA),
         lat=as.numeric(NA))


for (j in 1:nrow(mada.ecos)) {
  print(j)
  ecosf <- mada.ecos %>% slice(j) %>% pull(file) %>% read_sf() 
  area_calc <- ecosf %>% st_area %>% set_units("km^2") %>% sum
  mada.ecos[j,"mapped_area"] <- area_calc
  mada.ecos[j,"npols"] <- nrow(ecosf)
  xys <- ecosf %>% st_transform(crs="+proj=longlat +datum=WGS84") %>% st_bbox 
  mada.ecos[j,"lon"] <- (xys[1]+xys[3])/2
  mada.ecos[j,"lat"] <- (xys[2]+xys[4])/2
}

#require(purrr)
#mada.ecos %>% select(file) %>% map(~ read_sf(.x) %>% st_area %>% set_units("km^2"))


assessments_africa %>% filter(country %in% "MG",asm_id %in% "Carre_RLE_Madagascar_2020") %>% pull(eco_name)

mada.ecos %>% pull(name)
mada.ecos %<>% mutate(efg_code=case_when(
  name %in% "Mangroves" ~ "MFT1.2",
  name %in% "Roches nues" ~ "T3.4",
  name %in% c("forêts littorales","Brousses littorales du sud-ouest") ~ "MT2.1",
  grepl("Forêts sèches",name) ~ "T1.2",
  name %in% "Forêts de Tapia" ~ "T1.2",
  grepl("haute altitude",name) ~ "T1.3",
  grepl("fourrés secs et épineux",name) ~ "T5.2",
  grepl("orêts humide",name) ~ "T1.1",
  grepl("Forêts sub-humides",name) ~ "T1.1",
  name %in% c("Zones humide saumatres","autres zones humides") ~ "TF1",
  name %in% c("Prairies et mosaique arborée de plateau","Prarie arborée et mosaique de brousse") ~ "T4.2",
  name %in% c("Las et rivières de montagne (eau <22.2°)","Rivières et lacs (>10m >22.2°)") ~ "F1/F2",
  name %in% c("Lagunes et estuaires <10 m","lagunes et estuaires <25m") ~ "FM1",
  TRUE ~ as.character(NA)
)) 

mada.ecos %>% filter(is.na(efg_code))

mada.ecos %>% group_by(efg_code) %>% summarise(mapped_area=sum(mapped_area))
