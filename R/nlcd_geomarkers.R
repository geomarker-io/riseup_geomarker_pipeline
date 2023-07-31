library(dplyr)
## library(dht)
library(sf)
library(codec)
library(terra)

# options for downloaded rasters
options(timeout = 3000)

d <- readRDS("data/geocodes.rds")

d_vect <-
  d |>
  select(PAT_ENC_CSN_ID, lat, lon) |>
  na.omit() |>
  distinct(.keep_all = TRUE) |>
  st_as_sf(coords = c("lon", "lat"), crs = 4326) |>
  st_transform(5072) |>
  st_buffer(dist = 400) |>
  vect()

# functions to download and create NLCD tif files per year
source("data-raw/nlcd.R")
# will save to:
tools::R_user_dir("s3", "data")

impervious_raster <- download_impervious(yr = 2019) |> rast()
hv <- cincy::county_hlthv_2010 |> st_union()
impervious_hv_2019 <- terra::crop(impervious_raster, hv)

xx <- terra::extract(impervious_hv_2019, d_vect, fun = "mean", ID = FALSE)
d_vect$pct_impervious_2019 <- round(xx[, "Layer_1"])

treecanopy_raster <- download_treecanopy(yr = 2019) |> rast()
hv <- cincy::county_hlthv_2010 |> st_union()
treecanopy_hv_2019 <- terra::crop(treecanopy_raster, hv)

xx <- terra::extract(treecanopy_hv_2019, d_vect, fun = "mean", ID = FALSE)
d_vect$pct_treecanopy_2019 <- round(xx[, "Layer_1"])

d <- d |>
  left_join(as_tibble(d_vect), by = "PAT_ENC_CSN_ID") |>
  add_col_attrs(pct_impervious_2019,
    title = "Imperviousness (%)",
    description = "Average percent impervious of all 30x30m cells within a cirlce defined around each point with a 400 m radius"
  ) |>
  add_col_attrs(pct_treecanopy_2019,
    title = "Tree Canopy (%)",
    description = "Average percent treecanopy of all 30x30m cells within a cirlce defined around each point with a 400 m radius"
  )

saveRDS(d, "data/nlcd.rds")
