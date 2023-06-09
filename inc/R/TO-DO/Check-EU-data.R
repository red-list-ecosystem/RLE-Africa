require(sf)
NEA <- read_sf("Data/EURLH/Geodatabases/North East Atlantic Sea geodatabase v03/NEA geodatabase.shp")
Terr_eco <- read_sf("Data/EURLH/Geodatabases/Terrestrial geodatabase/RDB_Final_Maps_Terrestrial.shp")
WB <- read_sf("Data/WB_Boundaries_GeoJSON_lowres/WB_countries_Admin0_lowres.geojson")

WB %>% 
  filter(grepl("Guern",FORMAL_EN)) %>% 
  st_transform(st_crs(Terr_eco)) %>% 
  st_geometry %>% 
  plot

plot(st_geometry(Terr_eco), add=T)

WB %>% 
  filter(grepl("Portu",FORMAL_EN)) %>% 
  st_transform(st_crs(Terr_eco)) %>% 
  st_geometry %>% 
  plot
plot(st_geometry(Terr_eco), add=T)
