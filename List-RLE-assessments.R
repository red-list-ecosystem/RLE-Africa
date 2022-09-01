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

