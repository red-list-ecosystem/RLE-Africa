
## Create Africa map

### upload to OSF repo

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

### upload to OSF repo

### Create plots for Manuscript

```sh
Rscript --vanilla $SCRIPTDIR/inc/R/EFG-plot.R
```