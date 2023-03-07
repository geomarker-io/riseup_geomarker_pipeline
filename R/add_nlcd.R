
.cran_packages <- c("sf", "s3", "terra")
.inst <- .cran_packages %in% installed.packages()
if(any(!.inst)) {
  install.packages(.cran_packages[!.inst], repos = "http://cran.us.r-project.org")
}

library(tidyverse)
library(dht)
library(sf)
library(CODECtools)

d <- readRDS("data/addresses_geocoded.rds")

# make buffers around points
d.point <- d |> 
  select(PAT_ENC_CSN_ID , lat, lon) |> 
  filter(complete.cases(.)) |>  # keep geocoded ones
  distinct(.keep_all = TRUE)  # remove duplicated records while adding parcel ID

d.point <-
  d.point |>
  dplyr::select(PAT_ENC_CSN_ID, lat, lon) |>
  stats::na.omit() |>
  tidyr::nest(PAT_ENC_CSN_ID = c(PAT_ENC_CSN_ID)) |>
  sf::st_as_sf(coords = c("lon", "lat"), crs = 4326)

# project to 5072 for buffering in meters
d.buffered <- d.point |>
  sf::st_transform(5072) |>
  sf::st_buffer(dist = 400)

d.buffered <- terra::vect(d.buffered)

# nlcd_legend
nlcd_legend <-
  tibble::tribble(
    ~value, ~landcover_class, ~landcover, ~green,
    11, "water", "water", FALSE,
    12, "water", "ice/snow", FALSE,
    21, "developed", "developed open", TRUE,
    22, "developed", "developed low intensity", TRUE,
    23, "developed", "developed medium intensity", FALSE,
    24, "developed", "developed high intensity", FALSE,
    31, "barren", "rock/sand/clay", FALSE,
    41, "forest", "deciduous forest", TRUE,
    42, "forest", "evergreen forest", TRUE,
    43, "forest", "mixed forest", TRUE,
    51, "shrubland", "dwarf scrub", TRUE,
    52, "shrubland", "shrub/scrub", TRUE,
    71, "herbaceous", "grassland", TRUE,
    72, "herbaceous", "sedge", TRUE,
    73, "herbaceous", "lichens", TRUE,
    74, "herbaceous", "moss", TRUE,
    81, "cultivated", "pasture/hay", TRUE,
    82, "cultivated", "cultivated crops", TRUE,
    90, "wetlands", "woody wetlands", TRUE,
    95, "wetlands", "emergent herbaceous wetlands", TRUE
  )

# extract info
# nlcd
if (file.exists("rasters/nlcd_hv_2019.tif")){
  
  nlcd_hv_2019 <- terra::rast("rasters/nlcd_hv_2019.tif")
  
} else {
  
  hv <- cincy::county_hlthv_2010 |> 
    st_union()
  
  nlcd_tif <- s3::s3_get("s3://geomarker/nlcd_cog/nlcd_landcover_2019.tif")
  nlcd <- terra::rast(nlcd_tif)
  nlcd_hv_2019 <- terra::crop(nlcd, hv)
  terra::writeRaster(nlcd_hv_2019, "rasters/nlcd_hv_2019.tif")
  fs::dir_delete("s3_downloads")
}

pct_green <- 
  terra::extract(nlcd_hv_2019, d.buffered) |>
  rename(value = Layer_1) |>
  left_join(nlcd_legend, by = "value") |>
  group_by(ID) |>
  summarize(pct_green_2019 = round(sum(green) / n() * 100)) |>
  select(-ID)

d.pct_green <- bind_cols(d.point, pct_green) |> 
  unnest(PAT_ENC_CSN_ID) |> 
  st_drop_geometry()

# impervious
if (file.exists("rasters/impervious_hv_2019.tif")){
  
  impervious_hv_2019 <- terra::rast("rasters/impervious_hv_2019.tif")
  
} else {
  
  hv <- cincy::county_hlthv_2010 |> 
    st_union()
  
  impervious_tif <- s3::s3_get("s3://geomarker/nlcd_cog/nlcd_impervious_2019.tif")
  impervious <- terra::rast(impervious_tif)
  impervious_hv_2019 <- terra::crop(impervious, hv)
  terra::writeRaster(impervious_hv_2019, "rasters/impervious_hv_2019.tif")
  fs::dir_delete("s3_downloads")
}

pct_impervious <- 
  terra::extract(impervious_hv_2019, 
                 d.buffered, 
                 fun = "mean") |>
  rename(value = Layer_1) |>
  summarize(pct_impervious_2019 = round(value))

d.pct_impervious <- bind_cols(d.point, pct_impervious) |> 
  unnest(PAT_ENC_CSN_ID) |> 
  st_drop_geometry()

# tree canopy
if (file.exists("rasters/treecanopy_hv_2016.tif")){
  
  treecanopy_hv_2016 <- terra::rast("rasters/treecanopy_hv_2016.tif")
  
} else {
  
  hv <- cincy::county_hlthv_2010 |> 
    st_union()
  
  tree_tif <- s3::s3_get("s3://geomarker/nlcd_cog/nlcd_treecanopy_2016.tif")
  treecanopy <- terra::rast(tree_tif)
  treecanopy_hv_2016 <- terra::crop(treecanopy, hv)
  terra::writeRaster(treecanopy_hv_2016, "rasters/treecanopy_hv_2016.tif")
  fs::dir_delete("s3_downloads")
}

pct_treecanopy <- 
  terra::extract(treecanopy_hv_2016, 
                 d.buffered, 
                 fun = "mean") |>
  rename(value = Layer_1) |>
  summarize(pct_treecanopy_2016 = round(value))

d.pct_treecanopy <- bind_cols(d.point, pct_treecanopy) |> 
  unnest(PAT_ENC_CSN_ID) |> 
  st_drop_geometry()

# merge
d.nlcd <- d.pct_green |> 
  left_join(d.pct_impervious, by = "PAT_ENC_CSN_ID") |> 
  left_join(d.pct_treecanopy, by = "PAT_ENC_CSN_ID")

# add column attributes
d <- d |>
  add_col_attrs(pct_green_2019, 
                title = 'percentage green', 
                description = 'percent of green = TRUE nlcd cells overlapping buffer (green = TRUE if landcover classification in any category except water, ice/snow, developed medium intensity, developed high intensity, rock/sand/clay)'
  ) |>
  add_col_attrs(pct_impervious_2019, 
                title = 'percentage impervious', 
                description = 'average percent impervious of all nlcd cells overlapping the buffer'
  ) |>
  add_col_attrs(pct_treecanopy_2016, 
                title = 'percentage treecanopy', 
                description = 'average percent tree canopy cover of all nlcd cells overlapping the buffer'
  ) 

saveRDS(d.nlcd, "data/nlcd.rds")

