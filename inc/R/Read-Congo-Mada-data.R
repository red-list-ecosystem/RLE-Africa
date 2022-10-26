# Congo
require(foreign)
Congo <- read.dbf(sprintf("Data/Congo/Congo_Basin_Forest_Ecosystems.tif.vat.dbf"))
head(Congo)


#Mozambique
require(sf)
require(units)
moz <- read_sf("Data/Moz/Moz_ecosystem_map_w_RLE_results_01Mar2021.shp")
moz %>% slice(1)

moz %>% mutate(mapped_area=st_area(geometry) %>% set_units("km^2")) %>% st_drop_geometry %>% group_by(IUCN_Funct) %>% summarise(n=n_distinct(Name),category=paste(unique(Overall__1),collapse=";"), mapped_area=sum(mapped_area)) -> moz_list

moz_list

#South Africa
require(sf)
za <- read_sf("Data/VEGMAP2018_Final.gdb")
za %>% slice(1)

za %>% mutate(mapped_area=st_area(Shape) %>% set_units("km^2")) %>% st_drop_geometry %>% group_by(BIOME_18,Name_18) %>% summarise(category=paste(unique(NBA2018_RLE_Status),collapse=";"), mapped_area=sum(mapped_area)) -> za_list

## xwalk
require(readxl)
xwalk <- read_excel(sprintf("%s/proyectos/UNSW/ecosphere-db/input/xwalks/GETcrosswalk_SouthAfricaTerrestrial_V2_17012020_DK.xlsx", Sys.getenv("HOME")), sheet=4)
xwalk %<>% rename("eco_name"=`SA Vegetation Class (vNVM2018). Note classes in blue font are described in`) %>% filter(!is.na(eco_name))

newcolnames <- colnames(xwalk) %>% str_replace( "^TM ","MT") %>% str_replace("^FM ","FM") %>% str_replace("^MFT ","MFT")

colnames(xwalk) <- newcolnames

require(tidyr)
xwalk %>% pivot_longer(`T1.1Tropical/Subtropical lowland rainforests`:`MFT1.3 Coastal saltmarshes`,names_to = "efg", values_to="membership") %>% filter(!is.na(membership)) %>% transmute(eco_name, efg_code=str_extract(efg,"[A-Z0-9\\.]+"), membership) -> za_xwalk

za_list %>% left_join(za_xwalk,by=c("Name_18"="eco_name")) %>% group_by(efg_code) %>% summarise(n=n_distinct(Name_18),estimated_area=sum(mapped_area*membership),category=paste(unique(category),collapse=";"))

#Madagascar
require(sf)
require(units)
shp <- read_sf("Data/Mada/layers/100001.shp")
shp %>% st_drop_geometry() # not very informative
shp %>% st_area %>% set_units("km^2")

# we could read Mada/Moat\ _\ Murray\ Madagascar\ ecosystem\ types.qgs as an xml file
require(xml2)
require(stringr)
shpinfo <- read_xml("Data/Mada/Moat\ _\ Murray\ Madagascar\ ecosystem\ types.qgs")
shpinfo %>% xml_find_all(".//legendlayer") %>% xml_attr("name") %>% str_split_fixed(" ",n=2) %>% data.frame()  -> mada.ecos 
colnames(mada.ecos) <- c("code","name")
require(magrittr)
require(dplyr)
mada.ecos %<>% tibble()
#shpinfo %>% xml_find_first(".//legendlayer") %>% xml_attr("name")
#shpinfo %>% xml_find_all(".//legendlayer[starts-with(@name,100001)]") %>% xml_attr("name")

mada.ecos %<>% mutate(file=sprintf("Data/Mada/layers/%s.shp",code)) %>% mutate(efile=file.exists(file),mapped_area=set_units(0,"km^2"),npols=0,lon=as.numeric(NA),lat=as.numeric(NA))


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
