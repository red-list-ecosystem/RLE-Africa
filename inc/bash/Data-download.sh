####
## IUCN Red List of Ecosystems in Africa
## J.R. Ferrer-Paris https://github.com/jrfep
## Script to download and prepare all spatial and non-spatial data for the analysis
####

## We will download files into the Data folder (not tracked by git)
## Some data sources are open access, others are private and need to be requested by the original authors


## Set up Data folder  -------

source env/project-env.sh

mkdir -p $SCRIPTDIR/Data
cd $SCRIPTDIR/Data
## check $SCRIPTDIR/env/rsync.sh for tips on how to synchronize data between repository copies

## IUCN Global Ecosystem Typology  -------
# Indicative distribution maps, #Version 2.1.1
# doi = "10.5281/zenodo.5090419"
# download
wget --continue https://zenodo.org/api/files/4991f687-63f1-4ec8-ab92-75c8fcd5bd6a/all-maps-raster-geotiff.tar.bz2
# extract
tar -xjvf all-maps-raster-geotiff.tar.bz2
#gdalinfo T6_5_Trop_alpine_grassland.tif -hist
#less T6_5_Trop_alpine_grassland.tif.aux.xml
#gdalwarp -cutline INPUT.shp -crop_to_cutline -dstalpha INPUT.tif OUTPUT.tif


## IUCN Red List of Ecosystem assessments  -------

# we use geospatial data (GIS data) that is freely available or has been provided by co-authors for this analysis.

## South African data and scripts in  Suppements:
# Skowno AL, Monyeki MS. South Africa’s Red List of Terrestrial Ecosystems (RLEs). Land. 2021; 10(10):1048. https://doi.org/10.3390/land10101048
## Map is also here:
# http://bgis.sanbi.org/SpatialDataset/Detail/6715

mkdir -p $SCRIPTDIR/Data/ZAF
## unzip -u $SCRIPTDIR/Data/VEGMAP2018_AEA_16082019Final.zip -d $SCRIPTDIR/Data/ZAF

for ARCH in $(ls $GISDATA/ecosystems-status/regional/South-Africa/*zip)
do 
  unzip -u '$ARCH' -d $SCRIPTDIR/Data/ZAF
done

cp ~/proyectos/IUCN-RLE/IUCN-RLE-GET-xwalk/input/xwalks/GETcrosswalk_SouthAfricaTerrestrial_V2_17012020_DK.xlsx $SCRIPTDIR/Data/ZAF



#We received data from Congo, Madagascar and Mozambique from Hedley
mkdir -p $SCRIPTDIR/Data/Moz
mkdir -p $SCRIPTDIR/Data/Mada
mkdir -p $SCRIPTDIR/Data/Congo

unzip -u $SCRIPTDIR/Data/Congo/Congo.zip -d $SCRIPTDIR/Data/Congo
unzip -u $SCRIPTDIR/Data/Mada/Madagascar.zip -d $SCRIPTDIR/Data/Mada
mv ~/Downloads/wetransfer_moz_ecosystem_map_w_rle_results_01mar2021-cpg_2022-09-15_0957.zip $SCRIPTDIR/Data/Moz
unzip -u $SCRIPTDIR/Data/Moz/wetransfer_moz_ecosystem_map_w_rle_results_01mar2021-cpg_2022-09-15_0957.zip -d $SCRIPTDIR/Data/Moz

## EU RLH database, for part of the Macaronesia islands under European jurisdiction (Canary Islands and Madeira Island)
mkdir -p $SCRIPTDIR/Data/EURLH
unzip -u /opt/gisdata/ecosystems/EUplus-RLH/EURLHDB.zip -d $SCRIPTDIR/Data/EURLH
cd $SCRIPTDIR/Data/EURLH
chmod 744 Library/ -R
ogrinfo Library/Project\ data\ deliverables/Geodatabases/North\ East\ Atlantic\ Sea\ geodatabase\ v03/ 'NEA geodatabase' | less
ofrinfo Library/Project\ data\ deliverables/Geodatabases/Terrestrial\ geodatabase/RDB_Final_Maps_Terrestrial.shp

# or 
mkdir -p $SCRIPTDIR/Data/EURLH
cd $SCRIPTDIR/Data/EURLH
wget --continue https://forum.eionet.europa.eu/european-red-list-habitats/library/project-deliverables-data/database/raw-database-13_1_17/download/en/1/Raw%20Database%20-%2013_1_17.accdb
wget --continue https://forum.eionet.europa.eu/european-red-list-habitats/library/project-deliverables-data/geodatabases/zip_export/do_export --output-document=geodatabases.zip

#brew install mdbtools

mdb-export Raw\ Database\ -\ 13_1_17.accdb "European Red List of Habitats Table" > EURLH.csv


## Auxilliary data  -------

# I keep copies of these datasets in my $GISDATA folder, original source in comments

## Marine Ecoregions of the World (MEOW)
# Spalding MD, Fox HE, Allen GR, Davidson N, Ferdaña ZA, Finlayson M, Halpern BS, Jorge MA, Lombana A, Lourie SA, Martin KD, McManus E, Molnar J, Recchia CA, Robertson J (2007). Marine Ecoregions of the World: a bioregionalization of coast and shelf areas. BioScience 57: 573-583. doi: 10.1641/B570707. Data URL: http://data.unep-wcmc.org/datasets/38
# available at:
# <https://www.worldwildlife.org/publications/marine-ecoregions-of-the-world-a-bioregionalization-of-coastal-and-shelf-areas>
# <https://data.unep-wcmc.org/datasets/38>
mkdir -p $SCRIPTDIR/Data/MEOW
unzip -u $GISDATA/ecoregions/global/MEOW/MEOW_FINAL.zip -d $SCRIPTDIR/Data/MEOW

#WorldBank Countries
# available at: https://datacatalog.worldbank.org/dataset/world-bank-official-boundaries
unzip -u $GISDATA//admin/global/World-Bank/wb_boundaries_geojson_lowres.zip

# EEZ boundaries
## https://www.marineregions.org/eez.php
## Flanders Marine Institute (2019). Maritime Boundaries Geodatabase: Maritime Boundaries and Exclusive Economic Zones (200NM), version 11. Available online at https://www.marineregions.org/. https://doi.org/10.14284/386
## this was created/used once for the typology website, we are using it here for South Africa and Madagascar marine areas
#Data/EEZ_land_union_v3_202003/


#Large marine ecosystems
#Pope, Addy. (2017). Large Marine Ecosystems of the World, [Dataset]. University of Edinburgh. https://doi.org/10.7488/ds/1902.
##https://datashare.ed.ac.uk/handle/10283/2552
unzip -u $GISDATA//ecoregions/global/LME/lmes_64.zip

# Create a single file with World Bank country boundaries and large marine ecosystems

ogr2ogr -f GPKG -preserve_fid Africa.gpkg WB_Boundaries_GeoJSON_lowres/WB_countries_Admin0_lowres.geojson -where "REGION_UN='Africa'" -nln all_territories
ogr2ogr -f GPKG -preserve_fid -update -append -addfields Africa.gpkg WB_Boundaries_GeoJSON_lowres/WB_disputed_areas_Admin0_10m_lowres.geojson -where "REGION_UN='Africa'" -nln all_territories
ogr2ogr -f GPKG -unsetFid -update -append -addfields Africa.gpkg lmes_64.shp -where "OBJECTID IN (31,46,51,54,47)" -nln all_territories
#ogrinfo Africa.gpkg -sql "UPDATE all_territories set featurecla='Marine area', FORMAL_EN=LME_NAME WHERE featurecla is NULL"
ogrinfo Africa.gpkg -sql "UPDATE all_territories set featurecla='Marine area', ISO_A2='LME'||OBJECTID, OBJECTID=300+OBJECTID, FORMAL_EN=LME_NAME, SUBREGION='Marine area' WHERE featurecla is NULL"
#ogrinfo Africa.gpkg -sql "UPDATE all_territories set OBJECTID=300+OBJECTID WHERE featurecla is NULL"
ogrinfo Africa.gpkg -sql "UPDATE all_territories set OBJECTID=1 WHERE FORMAL_EN='Sahrawi Arab Democratic Republic'"
ogrinfo Africa.gpkg -sql "UPDATE all_territories set OBJECTID=2,FORMAL_EN=WB_NAME WHERE OBJECTID is NULL"
ogrinfo Africa.gpkg -sql "UPDATE all_territories set FORMAL_EN=WB_NAME WHERE FORMAL_EN=' ' AND WB_NAME is not NULL"

ogrinfo Africa.gpkg -sql "SELECT featurecla, count(*) FROM all_territories group by featurecla" -geom=no
