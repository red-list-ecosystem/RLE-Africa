# Script to download data from OSF cloud storage

## Find the root of the repository folder and create a sandbox folder
here::i_am("inc/R/osf-download.R")
target.dir <- "Data"
if (!file.exists(here::here(target.dir)))
  dir.create(here::here(target.dir))

## For this to work we need to define "OSF_PAT" in a .Renviron file
library(osfr)

## OSF project ID:
osfid <- "5ay6q"
osf_project <- osf_retrieve_node(sprintf("https://osf.io/%s",osfid))

## List all files and download them in target.dir:
project_files <- osf_ls_files(osf_project)
osf_download(project_files, path=here::here(target.dir), conflicts="overwrite")


# Done !