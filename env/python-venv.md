## GDAL

```sh
which gdal-config # we had some obscure version in the Postgres.app (why???)
brew install gdal 
which gdal-config
```


## Create and activate python environment

### with venv

Use an specific version of python3...

```sh
conda deactivate
mkdir -p $HOME/venv
/usr/local/bin/python3 -m venv $HOME/venv/gis
source $HOME/venv/gis/bin/activate
```

Check python version
```sh
python --version
```

Update and install modules
```sh
pip install --upgrade pip
python3 -m pip install --upgrade setuptools
#/usr/local/opt/python@3.9/bin/python3.9 -m pip install --upgrade pip

```

This fails:
```sh
pip3 install osgeo
pip3 install gdal
```

But this works:
```sh
gdal-config --version # 3.6.4
pip3 install gdal==3.6.4
```
