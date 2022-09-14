archs <- dir("Data",pattern="^[MSFT0-9]+_",full.names = TRUE) %>% grep("tif$",.,value=TRUE)

require(raster)
x <- raster("Data/T7_biome.tif")
#x <- stack(grep("Data/T7",archs,value=T))
plot(x) 
plot(x>0)

y <- raster("Data/T1_biome.tif")
plot(y) 
ss <- values(y)>0
tt <- table(values(x)[ss])

z <- raster("Data/T_all_biomes.tif")
plot(z) 
ss <- values(z)>0
tt <- table(values(x)[ss])

cumsum(tt)/sum(tt)

za <- area(z)

ss <- values(z)>0 & values(x)>0
tt <- sum(values(za)[ss])


z <- raster("Data/Terrestrial_reclass_proj.tif")
plot(z) 
table(values(z))

#require(stars)
#x = read_stars(archs)
#plot(x[1], axes = TRUE)
#plot(x[12], axes = TRUE)

#idx <- grep("T7",names(x))
## does not work
## st_apply(x, idx , mean) 