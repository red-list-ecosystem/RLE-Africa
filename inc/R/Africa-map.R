require(sf)
require(dplyr)
library(lwgeom)
require(vroom)
require(ggplot2)

#  Chamberlin trimetric conversion method
chb_proj <- "+proj=chamb +lat_1=22 +lon_1=0 +lat_2=22 +lon_2=45 +lat_3=-22 +lon_3=22.5 +datum=WGS84 +type=crs"
# Africa Lambert Conformal Conic
lcc_proj <- "+proj=lcc +lat_1=20 +lat_2=-23 +lat_0=0 +lon_0=25 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m no_defs"

Africa <- read_sf("Data/Africa.gpkg") %>% st_transform(crs=lcc_proj)


Africa %>% select(featurecla) %>% st_drop_geometry() %>% pull %>% table

Africa %>% select(SUBREGION) %>% plot 

myMergedData <- vroom(dir("Data/areas-per-country/",full.names=T))

myMergedData %>% 
  mutate(code=gsub("([MFTS0-9\\.]+)-[a-z_.]+","\\1",code)) %>%
  group_by(code) %>% summarise(countries=n_distinct(OBJECTID),major=sum(major)*100,minor=sum(minor)*100) %>% mutate(biome=gsub("([MFTS0-9]+).[0-9]+","\\1",code)) -> DataEFGs

DataEFGs %>% arrange(desc(major)) 

ggplot(Africa, aes(colour=SUBREGION,fill=SUBREGION %in% "Marine area")) + geom_sf() + theme_light() + theme(legend.position="None") + scale_fill_manual(values=c("lightgrey","aliceblue")) + 
  geom_sf_text(  aes(label = ISO_A2)) + geom_sf(data=Africa %>% filter(ISO_A2 %in% c("LY")),fill='darkgrey')

slc.biomes <- c(sprintf("T%s",1:6),"TF1")
p <- ggplot(DataEFGs %>% filter(major>0,biome %in% slc.biomes), aes(x=code, y=major, fill=biome)) + geom_bar(width=1, stat='identity') + theme_light() 
#+ scale_fill_gradient(low='red', high='white', limits=c(5,40)) + theme(axis.title.y=element_text(angle=0))
p + theme(axis.text.x = element_text(angle=45, vjust = 1, hjust=1)) + xlab("Ecosystem Functional Group") + ylab("% of global major distribution")

p + coord_polar() + labs(title="Ecosystems in Africa", x="Ecosystem Functional Group",y="% of global major distribution",fill="Biome")
#Hillary suggest that Mozambique Malawi and Zimbawe and Zambia should be southern africa
#this does not work very well
#st_snap_to_grid(size = 0.001) %>% st_make_valid() %>% 
  #group_by(SUBREGION) %>% summarise(geometry=st_combine(geometry)) %>% st_make_valid() %>% 
  
list(`Southern Africa` = list("NA","ZA","BW","SZ","LS"),
     `Western Africa` = list("SL", "GN", "LR", "CI", "ML", "SN", "NG", "BJ", "NE", "BF", "TG", "GH", "GW", "MR", "GM", "SH", "CV"),
     `Eastern Africa` = list("ET", "SS", "SO", "KE", "MW", "TZ", "ZM", "DJ", "ER", "ZW", "MZ","BI", "RW", "UG", "MG", "SC", "MU", "KM"),
     `Northern Africa` = list("MA", "LY",  "TN",  "SD",  "DZ",  "EG" ),
     `Marine areas` = list("LME31", "LME46", "LME47", "LME51", "LME54"))

             
require(magrittr)
require(tmap)

Africa %<>% 
  mutate(RLE_progress=case_when(
    NAME_EN %in% c("Tunisia","Ethiopia", "Ghana", "Ivory Coast", "Senegal", "Cameroon") ~ "To confirm",
    
    NAME_EN %in% c("Madagascar","South Africa", "Lesotho") ~ "All ecosystems",
    NAME_EN %in% c("Democratic Republic of the Congo","Republic of the Congo","Central African Republic", "Gabon", "Equatorial Guinea") ~ "Subset of ecosystems",
    NAME_EN %in% c("Uganda", "Rwanda", "Angola", "Namibia", "Mozambique", "Botswana", "Malawi") ~ "In progress",
    TRUE ~ "None",
  )) %>% mutate(RLE_progress=factor(RLE_progress,levels=c("To confirm","In progress","Subset of ecosystems","All ecosystems")))
tmap_mode("view")
tm_shape(Africa  %>% filter(RLE_progress != "None") %>% select(NAME_EN,RLE_progress)) +
  tm_polygons(col="RLE_progress")

tmap_mode("plot")
tm_shape(Africa) +
  tm_borders() +
  tm_shape(Africa  %>% filter(RLE_progress != "None") %>% select(NAME_EN,RLE_progress)) +
  tm_polygons(col="RLE_progress", palette = "Oranges") + #+ tm_text('NAME_EN',size="AREA")
  tm_shape(LakeBurullus) + tm_dots(size=.8)



#lake burullus
g <- st_sfc(st_point(x=c(30.8729,31.4761 )))

LakeBurullus <- st_sf(data.frame(place="Lake Burullus"),g,crs="+proj=longlat +datum=WGS84") %>% st_transform(crs=st_crs(Africa))
     
                