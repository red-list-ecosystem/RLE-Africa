library("googledrive")
library(glue)
library(purrr)

here::i_am("workflow/workflow.md")

# Upload geospatial data ----

local_files <- dir(here::here("Data"), 
                   full.names = TRUE,
                   pattern=".gpkg")
local_files <- set_names(local_files, basename(local_files))

target <- drive_get("RLE-Africa")
with_drive_quiet(
  files <- map(local_files, ~ drive_upload(.x, path = target))
)

# Upload area calculations per country ----

## create list of local files to upload:
local_files <- dir(
  here::here("Data","area-calc","areas-per-country"),
  full.names=TRUE
)
local_files <- set_names(local_files, basename(local_files))

## Create a folder on the Drive folder
target <- drive_mkdir("RLE-Africa/areas-per-country")

## upload all files into this folder by iterating over the local_files using purrr::map().
with_drive_quiet(
  files <- map(local_files, ~ drive_upload(.x, path = target))
)


# List of files and removing duplicates ----

all_files <- drive_ls("RLE-Africa", recursive = TRUE)
ss <- duplicated(all_files$name)
if (any(ss)) {
  drive_rm(all_files[ss,])
}