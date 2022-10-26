source env/project-env.sh 
mkdir -p $SCRIPTDIR/Data
cd $SCRIPTDIR/Data

rsync -gloptrunv $SCRIPTDIR/Data/ $USER@terra.ad.unsw.edu.au:~/proyectos/IUCN-RLE/$PROJECTNAME/Data
# Indicative distribution maps, #Version 2.1.1 
# doi = "10.5281/zenodo.5090419"
wget --continue https://zenodo.org/api/files/4991f687-63f1-4ec8-ab92-75c8fcd5bd6a/all-maps-raster-geotiff.tar.bz2

tar -xjvf all-maps-raster-geotiff.tar.bz2

#WorldBank Countries
#...
unzip -u ~/gisdata/admin/global/World-Bank/wb_boundaries_geojson_lowres.zip


#Large marine ecosystems
#...
unzip -u ~/gisdata/ecoregions/global/LME/lmes_64.zip

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
#gdalinfo T6_5_Trop_alpine_grassland.tif -hist
#less T6_5_Trop_alpine_grassland.tif.aux.xml 
#gdalwarp -cutline INPUT.shp -crop_to_cutline -dstalpha INPUT.tif OUTPUT.tif

## South African data and scripts in  Suppements:
# Skowno AL, Monyeki MS. 
# South Africa’s Red List of Terrestrial Ecosystems (RLEs). 
# Land. 2021; 10(10):1048. https://doi.org/10.3390/land10101048
## Map is also here: 
# http://bgis.sanbi.org/SpatialDataset/Detail/6715

#We received data from Congo and Madagascar from Hedley
unzip -u $SCRIPTDIR/Data/Congo/Congo.zip -d $SCRIPTDIR/Data/Congo
unzip -u $SCRIPTDIR/Data/Mada/Madagascar.zip -d $SCRIPTDIR/Data/Mada

unzip -u $SCRIPTDIR/Data/VEGMAP2018_AEA_16082019Final.zip -d $SCRIPTDIR/Data/

## this was created/used once for the typology website, we are using it here only for illustration
#Data/EEZ_land_union_v3_202003/
mkdir -p $SCRIPTDIR/Data/MEOW
unzip -u /opt/gisdata/ecoregions/global/MEOW/MEOW_FINAL.zip -d $SCRIPTDIR/Data/MEOW