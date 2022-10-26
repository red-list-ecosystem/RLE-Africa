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
  group_by(code) %>% summarise(countries=n_distinct(OBJECTID),major=sum(major)*100,minor=sum(minor)*100,both=sum(both)*100) %>% mutate(biome=gsub("([MFTS0-9]+).[0-9]+","\\1",code)) -> DataEFGs

DataEFGs %>% filter(!biome %in% c("M2","M3")) %>% arrange(desc(major)) 

DataEFGs %>% filter(!biome %in% c("M2","M3"))  %>% group_by(biome) %>% summarise(EFGs=n_distinct(code)) %>% arrange(desc(EFGs)) 

ggplot(Africa, aes(colour=SUBREGION,fill=SUBREGION %in% "Marine area")) + geom_sf() + theme_light() + theme(legend.position="None") + scale_fill_manual(values=c("lightgrey","aliceblue")) + 
  geom_sf_text(  aes(label = ISO_A2)) + geom_sf(data=Africa %>% filter(ISO_A2 %in% c("LY")),fill='darkgrey')

DataEFGs %>% distinct(biome) %>% pull
slc.biomes <- sprintf("T%s",1:6)
slc.biomes <- c(sprintf("F%s",1:2),"TF1","S1","SF1")
slc.biomes <- c(sprintf("MT%s",1:2),"MFT1","M1","FM1","SM1")
p <- ggplot(DataEFGs %>% filter(major>0,biome %in% slc.biomes), aes(x=code, y=major, fill=biome)) + geom_bar(width=1, stat='identity') + theme_light() 
#+ scale_fill_gradient(low='red', high='white', limits=c(5,40)) + theme(axis.title.y=element_text(angle=0))
p + theme(axis.text.x = element_text(angle=45, vjust = 1, hjust=1)) + xlab("Ecosystem Functional Group") + ylab("% of global major distribution") + geom_errorbar(aes(ymin=major,ymax=both))

p + coord_polar() + labs(title="Ecosystems in Africa", x="Ecosystem Functional Group",y="% of global major distribution",fill="Biome") + geom_errorbar(aes(ymin=major,ymax=both))

coord_plot <- function(dat,flt) {
  p <- ggplot(dat %>% filter(major>0,biome %in% flt)) + 
    geom_bar(aes(x=code, y=major, fill=biome), width=1, stat='identity',alpha=.6) + 
    geom_bar(aes(x=code, y=both, fill=biome),width=1, stat='identity',alpha=.6) + 
    theme_light() + 
    geom_errorbar(aes(x=code, ymin=major,ymax=both))
  return(p)
}

coord_plot(DataEFGs,sprintf("T%s",1:6)) + coord_polar() + 
  labs(title="Terrestrial realm", x="Ecosystem Functional Group",y="% of global major distribution",fill="Biome") 
coord_plot(DataEFGs,c(sprintf("F%s",1:2),"TF1","S1","SF1")) + 
  coord_polar() + 
  labs(title="Freshwater and Subterranean (+ transitions)", x="Ecosystem Functional Group",y="% of global major distribution",fill="Biome") 
coord_plot(DataEFGs,c(sprintf("MT%s",1:2),"MFT1","M1","FM1","SM1"))+ 
  coord_polar() + 
  labs(title="Marine (+ transitions)", x="Ecosystem Functional Group",y="% of global major distribution",fill="Biome") 



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

# Strategic assessments



g <- st_sfc(st_point(x=c(30.8729,31.4761)),#lake burullus
            st_point(x=c(46.47416,-20.37449)), # Tapia forest
            st_point(x=c(-16.49901060022063,13.652516407467148)), # Fathala forest
            st_point(x=c(18.52,-34.57)), # Cape Flats Sand Fynbos
            st_point(x=c(12.7,-30)), # Benguela
            st_point(x=c(-14.7,16)), # Gonakier
            st_point(x=c(45.138333,-12.843056)), # Mayotte
)

Strategic <- st_sf(data.frame(place=c("Lake Burullus","Tapia Forest","Fathala Forest", "Cape Flats Sand Fynbos","Benguela current","Gonakier Forest","Mayotte Mangroves")),g,crs="+proj=longlat +datum=WGS84") %>% st_transform(crs=st_crs(Africa))



Africa %<>% 
  mutate(RLE_progress=case_when(
    NAME_EN %in% c("Madagascar","South Africa") ~ "All ecosystems",
    NAME_EN %in% c("Ethiopia","Uganda","Botswana","Ghana","Malawi") ~ "Preliminary/Rapid",
    NAME_EN %in% c("Democratic Republic of the Congo","Republic of the Congo","Central African Republic", "Gabon", "Equatorial Guinea") ~ "Subset of ecosystems",
    NAME_EN %in% c("Tunisia", "Rwanda") ~ "In progress",
    NAME_EN %in% c("Liberia","Sierra Leone","Equatorial Guinea") ~ "All ecosystems", # Santerre's work
    #NAME_EN %in% c(  "Ivory Coast", "Senegal", "Cameroon", "Lesotho","Angola") ~ "To confirm",
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
  tm_shape(Strategic) + tm_text('place',size=.8) + tm_dots(size=.5) + tm_layout(legend.position = c("left","bottom"))


## [x] add /or not/ Senterre
## [x] Check Andrew's Email
## [ ] Add Mayotte
## [ ] Canary islands / EU RLH marine/terrestrial
