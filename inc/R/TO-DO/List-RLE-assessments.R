if (file.exists("~/.database.ini")) {
  tmp <-     system("grep -A4 psqlaws $HOME/.database.ini",intern=TRUE)[-1]
  dbinfo <- gsub("[a-z]+=","",tmp)
  names(dbinfo) <- gsub("([a-z]+)=.*","\\1",tmp)
}
require(sf)
require(dplyr)
require(RPostgreSQL)

Africa <- read_sf("Data/Africa.gpkg") 
# List of country iso codes in Africa
Africa %>% st_drop_geometry %>% pull(ISO_A2) -> country.codes


#Download species associations with habitats:
drv <- dbDriver("PostgreSQL") ## remember to update .pgpass file
con <- dbConnect(drv, dbname = dbinfo[["database"]],
                 host = dbinfo[["host"]],
                 port = dbinfo[["port"]],
                 user = dbinfo[["user"]])

# use the 'overlap' opperator: &&
qry <- sprintf("SELECT asm_id,eco_id,eco_name,DATE(assessment_date),overall_risk_category,unnest(countries) as country,efg_code,level,assigned_by FROM rle.assessment_units LEFT JOIN rle.assessment_overall USING(eco_id) LEFT JOIN rle.assessment_get_xwalk USING(eco_id) WHERE countries && '{%s}'::text[]",paste(country.codes,collapse=","))

assessments_africa <- dbGetQuery(con,qry)
dbDisconnect(con)

dim(assessments_africa)
table(assessments_africa$efg_code)
table(assessments_africa$country)
assessments_africa %>% filter(country %in% "MG")

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

require(stringr)
assessments_africa %>% filter(asm_id %in% "Shapiro_CongoBasin_2020") %>% mutate(Code=str_replace(eco_id,"Shapiro_CongoBasin_2020_","") %>% as.numeric) -> Congo_xwalk

Congo %>% left_join(Congo_xwalk) %>% select(Orig_Class,New_Class,Forest_Typ,eco_name,overall_risk_category,efg_code, Area_ha) %>% unique -> Congo_list


Congo_list %>% 
  mutate(efg_code=case_when(
    is.na(eco_name) ~ "T4.2",
    grepl("Montane Dense",New_Class) ~ "T1.3", 
    grepl("Evergreen",Forest_Typ) ~ "T1.1",
    grepl("Deciduous",Forest_Typ) ~ "T1.2", 
    TRUE~efg_code),
         Area_ha=set_units(Area_ha,'ha')) %>% group_by(efg_code) %>% summarise(n=n(),mapped_area=sum(Area_ha) %>% set_units("km^2"),category=paste(unique(overall_risk_category),collapse=";"))


head(Congo_list)      

require(xml2)

cape_flats <- read_xml(sprintf("%s/respaldo/databases/XML_v1.0/Strategic/Keith_CapeFlatsSandFynbos_2013_1.xml",Sys.getenv("HOME")))
cape_flats %>% xml_find_all(".//Case-Study-Name") %>% xml_text()
cape_flats %>% xml_find_all(".//Spatial-point") 

gonakier <- read_xml(sprintf("%s/respaldo/databases/XML_v1.0/Strategic/Keith_GonakierForest_2013_1.xml",Sys.getenv("HOME")))
gonakier %>% xml_find_all(".//Case-Study-Name") %>% xml_text()
gonakier %>% xml_find_all(".//Spatial-point") 

