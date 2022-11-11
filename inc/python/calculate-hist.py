####
## IUCN Red List of Ecosystems in Africa
## J.R. Ferrer-Paris https://github.com/jrfep
## this python script uses functions from gdal to summarise histogram information from the GeoTiff files
####

# Usage:
# conda deactivate
# cd Data
# python3.9 ../inc/python/calculate-hist.py

from osgeo import gdal
from osgeo import ogr, osr
import os
import re
import csv
#import json

#  ogrinfo WB_Boundaries_GeoJSON_lowres/WB_countries_Admin0_lowres.geojson -sql "SELECT FID,FORMAL_EN FROM WB_countries_Admin0_lowres WHERE REGION_UN='Africa'" -geom=no
inCountries = "Africa.gpkg"
inDriver = ogr.GetDriverByName("GPKG")
inDataSource = inDriver.Open(inCountries, 0)
#inLayer = inDataSource.GetLayer()
#extent = inLayer.GetExtent()
sql = "SELECT OBJECTID,featurecla,FORMAL_EN FROM all_territories"

results = inDataSource.ExecuteSQL(sql)
records=list()
for result in results:
  records.append(dict(result))


# os.mkdir('tmpdir')
# Allow for verbose exception reporting
gdal.UseExceptions()

# Build the OGR SQL
sql = "SELECT OBJECTID,featurecla,FORMAL_EN,geom FROM all_territories WHERE OBJECTID={fid}"

# Clip the input Raster
for arch in os.listdir():
  if arch.endswith(".tif") and \
  arch not in ("F1_7_Large_rivers.tif","Terrestrial_reclass.tif","Terrestrial_reclass_proj.tif") and \
  not arch.endswith('_biome.tif') and \
  not arch.endswith('_biomes.tif') and \
  not arch.endswith('_biome_noice.tif'):
    print(arch)
    code=re.sub('([MSTF]+[0-9]+)_([0-9]+)_[A-Za-z_.]+','\\1.\\2',arch)
    gtif = gdal.Open(arch)
    srcband = gtif.GetRasterBand(1)
    rhist = srcband.GetDefaultHistogram( )
    totalmajor=rhist[3][1]
    totalminor=rhist[3][2]
    totalboth=totalmajor+totalminor
    gtif.ClearStatistics()
    gtif=None
    #
    output='areas-per-country/{}.csv'.format(code)
    newrecords=list()
    if not os.path.exists(output):
      for record in records:
        result = gdal.Warp('tmpdir/'+arch,
                         arch,
                         cutlineDSName=inCountries,
                         cutlineSQL=sql.format(fid=record['OBJECTID']),
                         cropToCutline=True)
        # Initiate writing operations
        result = None
        gtif = gdal.Open( 'tmpdir/'+arch )
        srcband = gtif.GetRasterBand(1)
        rhist = srcband.GetDefaultHistogram( )
        major=rhist[3][1]
        minor=rhist[3][2]
        gtif.ClearStatistics()
        gtif=None
        if major>0 or minor>0:
          both=(major+minor)/totalboth
          if totalmajor>0:
            major=major/totalmajor
          if totalminor>0:
            minor=minor/totalminor
          print(record['FORMAL_EN'],major,minor)
          newrecord={'OBJECTID':record['OBJECTID'],
            'FORMAL_EN':record['FORMAL_EN'],
            'code':code,
            'major':major,
            'minor':minor,
            'both':both}
          newrecords.append(newrecord)
      with open(output, 'w') as fout:
        columns = ['OBJECTID', 'FORMAL_EN', 'code','major','minor','both']
        writer = csv.DictWriter(fout, fieldnames=columns)
        writer.writeheader()
        for key in newrecords:
            writer.writerow(key)
        #json.dump(newrecords, fout)
