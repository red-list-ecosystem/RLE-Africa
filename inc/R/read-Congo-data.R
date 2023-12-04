# Set up ----

## libraries
require(foreign)
require(dplyr)
library(readr)
library(sf)
library(stringr)
library(units)
require(RPostgreSQL)

## working directory
here::i_am("inc/R/read-Congo-data.R")

## Database credentials

if (file.exists("~/.database.ini")) {
  tmp <-     system("grep -A4 psqlaws $HOME/.database.ini",intern=TRUE)[-1]
  dbinfo <- gsub("[a-z]+=","",tmp)
  names(dbinfo) <- gsub("([a-z]+)=.*","\\1",tmp)
}

# List of country iso codes in Africa ----
Africa <- read_sf(here::here("Data","Africa.gpkg")) 
Africa %>% st_drop_geometry %>% pull(ISO_A2) -> country.codes

# List of assessment units in those countries ----

drv <- dbDriver("PostgreSQL") ## remember to update .pgpass file
con <- dbConnect(drv, dbname = dbinfo[["database"]],
                 host = dbinfo[["host"]],
                 port = dbinfo[["port"]],
                 user = dbinfo[["user"]])

# use the 'overlap' opperator: &&

qrystr <- "SELECT asm_id, eco_id, eco_name,
    DATE(assessment_date), overall_risk_category,
    unnest(countries) as country, efg_code, level, assigned_by 
  FROM rle.assessment_units 
  LEFT JOIN rle.assessment_overall USING(eco_id) 
  LEFT JOIN rle.assessment_get_xwalk USING(eco_id) 
  WHERE countries && '{%s}'::text[]"

qry <- sprintf(qrystr,paste(country.codes,collapse=","))

assessments_africa <- dbGetQuery(con,qry)
dbDisconnect(con)



Congo <- read.dbf(here::here("Data","Congo","Congo_Basin_Forest_Ecosystems.tif.vat.dbf"))
head(Congo)

Congo_xwalk <- 
  assessments_africa %>% 
  filter(asm_id %in% "Shapiro_CongoBasin_2020") %>% 
  mutate(Code=str_replace(eco_id,"Shapiro_CongoBasin_2020_","") %>% as.numeric)

Congo %>% 
  left_join(Congo_xwalk) %>% 
  select(Orig_Class, New_Class, Forest_Typ, eco_name, 
         overall_risk_category, efg_code, Area_ha) %>% 
  unique -> Congo_list

Congo_list %>% 
  mutate(efg_code=case_when(
    is.na(eco_name) ~ "T4.2",
    grepl("Montane Dense",New_Class) ~ "T1.3", 
    grepl("Evergreen",Forest_Typ) ~ "T1.1",
    grepl("Deciduous",Forest_Typ) ~ "T1.2", 
    TRUE~efg_code),
    Area_ha=set_units(Area_ha,'ha')) %>% 
  group_by(efg_code) %>% 
  summarise(n=n(),
            mapped_area=sum(Area_ha) %>% 
              set_units("km^2"),
            category = paste((overall_risk_category),collapse=";"))


head(Congo_list)  

Congo_table <- Congo_list %>% 
  filter(!is.na(efg_code)) %>%
  mutate(assessment_area=set_units(Area_ha,'ha') %>% set_units('km2')) %>%
  select(-Area_ha)

if (!dir.exists(here::here("Data", "systematic-assessment-summaries"))) 
  dir.create(here::here("Data", "systematic-assessment-summaries"))

write_csv(Congo_table, 
          file = 
            here::here("Data", "systematic-assessment-summaries",
                                 "congo-summary-RLE.csv"))
