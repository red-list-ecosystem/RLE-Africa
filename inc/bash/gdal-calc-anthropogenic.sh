####
## IUCN Red List of Ecosystems in Africa
## J.R. Ferrer-Paris https://github.com/jrfep
## this scripts uses gdal calculator to estimate the distribution of anthropogenic biomes and ecosystem functional groups.
####


cd Data
gdal_calc.py \
-A T7_1_Croplands.tif \
--calc="numpy.where(A<1, 0, A)" --outfile T7_biome.tif --type=Int16 --co="COMPRESS=LZW" --overwrite --hideNoData --NoDataValue=-9999

gdal_calc.py \
-A T7_1_Croplands.tif -B T7_2_Sown_pastures_and_fields.tif -C T7_3_Plantations.tif  \
-D T7_4_Urban_and_industrial.tif -E T7_5_Semi-natural_old_fields.tif \
--calc="numpy.where(A<1, 0, 1) + numpy.where(B<1, 0, 1) + numpy.where(C<1, 0, 1) + numpy.where(D<1, 0, 1) + numpy.where(E<1, 0, 1)" --outfile T7_biome.tif --type=Int16 --co="COMPRESS=LZW" --overwrite --hideNoData --NoDataValue=-9999

gdal_calc.py \
-A T1_1_Trop_lowland_rainforests.tif -C T1_3_Trop_montane_rainforests.tif \
-B T1_2_Trop_dry_forests.tif -D T1_4_Trop_heath_forests.tif \
--calc="numpy.where(A<1, 0, 1) + numpy.where(B<1, 0, 1) + numpy.where(C<1, 0, 1) + numpy.where(D<1, 0, 1)" --outfile T1_biome.tif --type=Int16 --co="COMPRESS=LZW" --overwrite --hideNoData --NoDataValue=-9999

gdal_calc.py \
-A T2_1_Boreal_montane_forests.tif       -D  T2_4_Warm_temp_rainforests.tif \
-B T2_2_Deciduous_temperate_forests.tif   -E T2_5_Temp_pyric_humid_forests.tif \
-C T2_3_Oceanic_temp_rainforests.tif      -F T2_6_Temp_sclerophyll_forests.tif \
--calc="numpy.where(A<1, 0, 1) + numpy.where(B<1, 0, 1) + numpy.where(C<1, 0, 1) + numpy.where(D<1, 0, 1) + numpy.where(E<1, 0, 1) + numpy.where(F<1, 0, 1)" --outfile T2_biome.tif --type=Int16 --co="COMPRESS=LZW" --overwrite --hideNoData --NoDataValue=-9999


gdal_calc.py \
-A T3_1_Seas_dry_trop_shrublands.tif      -C T3_3_Cool_temp_heathlands.tif \
-B T3_2_Seas_dry_temp_shrublands.tif      -D T3_4_Rocky_pavements.tif \
--calc="numpy.where(A<1, 0, 1) + numpy.where(B<1, 0, 1) + numpy.where(C<1, 0, 1) + numpy.where(D<1, 0, 1) " --outfile T3_biome.tif --type=Int16 --co="COMPRESS=LZW" --overwrite --hideNoData --NoDataValue=-9999

gdal_calc.py \
-A T4_1_Trophic_savannas.tif       -D T4_4_Temp_woodlands.tif \
-B T4_2_Pyric_tussock_savannas.tif -E T4_5_Temperate_grasslands.tif \
-C T4_3_Hummock_savannas.tif \
--calc="numpy.where(A<1, 0, 1) + numpy.where(B<1, 0, 1) + numpy.where(C<1, 0, 1) + numpy.where(D<1, 0, 1) + numpy.where(E<1, 0, 1)" --outfile T4_biome.tif --type=Int16 --co="COMPRESS=LZW" --overwrite --hideNoData --NoDataValue=-9999

gdal_calc.py \
-A T5_1_Semi-desert_steppe.tif             -D T5_4_Cool_temperate_deserts.tif \
-B T5_2_Succulent_Thorny_deserts.tif       -E T5_5_Hyper-arid_deserts.tif \
-C T5_3_Sclerophyll_hot_deserts.tif \
--calc="numpy.where(A<1, 0, 1) + numpy.where(B<1, 0, 1) + numpy.where(C<1, 0, 1) + numpy.where(D<1, 0, 1) + numpy.where(E<1, 0, 1)" --outfile T5_biome.tif --type=Int16 --co="COMPRESS=LZW" --overwrite --hideNoData --NoDataValue=-9999

gdal_calc.py \
-A T6_1_Permanent_snow.tif         -D T6_4_Temp_alpine_grasslands.tif \
-B T6_2_Polar_alpine_rock.tif      -E T6_5_Trop_alpine_grassland.tif \
-C T6_3_Polar_tundra.tif \
--calc="numpy.where(A<1, 0, 1) + numpy.where(B<1, 0, 1) + numpy.where(C<1, 0, 1) + numpy.where(D<1, 0, 1) + numpy.where(E<1, 0, 1)" --outfile T6_biome.tif --type=Int16 --co="COMPRESS=LZW" --overwrite --hideNoData --NoDataValue=-9999


gdal_calc.py \
-D T6_4_Temp_alpine_grasslands.tif \
-E T6_5_Trop_alpine_grassland.tif \
-C T6_3_Polar_tundra.tif \
--calc="numpy.where(C<1, 0, 1) + numpy.where(D<1, 0, 1) + numpy.where(E<1, 0, 1)" --outfile T6_biome_noice.tif --type=Int16 --co="COMPRESS=LZW" --overwrite --hideNoData --NoDataValue=-9999


gdal_calc.py \
-A T1_biome.tif -B T2_biome.tif -C T3_biome.tif -D T4_biome.tif \
-E T5_biome.tif -F T6_biome.tif \
--calc="A+B+C+D+E+F" --outfile T_natural_biomes.tif --type=Int16 --co="COMPRESS=LZW" --overwrite --hideNoData


gdal_calc.py \
-A T1_biome.tif -B T2_biome.tif -C T3_biome.tif -D T4_biome.tif \
-E T5_biome.tif -F T6_biome_noice.tif -G T7_biome.tif \
--calc="A+B+C+D+E+F+G" --outfile T_all_biomes.tif --type=Int16 --co="COMPRESS=LZW" --overwrite --hideNoData

## gdal_calc.py -A T_all_biomes.tif -G T7_biome.tif --calc="numpy.where(A>0, 1, 0)+numpy.where(G>0,1,0)" --outfile Terrestrial_reclass.tif --type=Int16 --co="COMPRESS=LZW" --overwrite --NoDataValue=0

gdal_calc.py \
-A T_all_biomes.tif -G T7_biome.tif \
--calc="numpy.where(A>0, 1, 0)+numpy.where(G>0,1,0)-1" --outfile Terrestrial_reclass.tif --type=Int16 --co="COMPRESS=LZW" --overwrite --NoDataValue=-1

[ -e Terrestrial_reclass_proj.tif ] && rm Terrestrial_reclass_proj.tif

gdalwarp -t_srs "+proj=eck4 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m no_defs" -r near -co "COMPRESS=LZW" Terrestrial_reclass.tif Terrestrial_reclass_proj.tif

gdalinfo Terrestrial_reclass_proj.tif -hist
