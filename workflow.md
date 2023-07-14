
## Create Africa map

Instruction for downloading spatial data and creating our customised Africa map (with regions and marine areas) are found in `$SCRIPTDIR/inc/bash/Data-download.sh`

Then we run this script to summarise the locations of strategic assessments and areas of systematic assessments.

```sh
Rscript --vanilla $SCRIPTDIR/inc/R/prepare-spatial-data.R
```

### upload to cloud repository

We will upload these spatial files to google drive:

```sh
Rscript --vanilla $SCRIPTDIR/inc/R/google-drive-upload.R
```

### Create map figure for Manuscript

```sh
Rscript --vanilla $SCRIPTDIR/inc/R/Africa-map.R
```

## Calculate EFG areas

```sh
source env/project-env.sh
mkdir -p $SCRIPTDIR/Data/area-calc
Rscript --vanilla $SCRIPTDIR/inc/R/zenodo-download.R

source $HOME/venv/gis/bin/activate
cd $SCRIPTDIR/Data/area-calc
tar -xjvf all-maps-raster-geotiff.tar.bz2
cp $SCRIPTDIR/Data/Africa.gpkg $SCRIPTDIR/Data/area-calc
mkdir -p $SCRIPTDIR/Data/area-calc/tmpdir
mkdir -p $SCRIPTDIR/Data/area-calc/areas-per-country
python $SCRIPTDIR/inc/python/calculate-hist.py
rm *tif.aux.xml
rm *tif
rm -r tmpdir 
```

### upload to cloud repository

We will test upload to google drive:

```sh
Rscript --vanilla $SCRIPTDIR/inc/R/google-drive-upload.R
```

### Create plots for Manuscript

```sh
Rscript --vanilla $SCRIPTDIR/inc/R/EFG-plot.R
```


## Summarise data for table

This code needs some fixes:

```sh
Rscript --vanilla $SCRIPTDIR/inc/R/List-RLE-assessments.R
```
