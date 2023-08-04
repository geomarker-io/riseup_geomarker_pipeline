library(dplyr, warn.conflicts = FALSE)
library(sf)
library(codec)
library(terra)

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

roi <- cincy::county_hlthv_2010 |> st_union()

impervious_raster <-
  get_impervious(yr = 2019) |>
  rast() |>
  terra::crop(roi)

d_vect$pct_impervious_2019 <-
  terra::extract(impervious_raster, d_vect, fun = "mean", ID = FALSE)[ , "Layer_1"] |>
  round(2)

treecanopy_raster <-
  get_treecanopy(yr = 2019) |>
  rast() |>
  terra::crop(roi)

d_vect$pct_treecanopy_2019 <-
  terra::extract(treecanopy_raster, d_vect, fun = "mean", ID = FALSE)[ , "Layer_1"] |>
  round(2)

d <- d |>
  left_join(as_tibble(d_vect), by = "PAT_ENC_CSN_ID") |>
  add_col_attrs(pct_impervious_2019,
    title = "Imperviousness (%)",
    description = "2019 Average percent impervious of all 30x30m cells within a cirlce defined around each point with a 400 m radius"
  ) |>
  add_col_attrs(pct_treecanopy_2019,
    title = "Tree Canopy (%)",
    description = "2019 Average percent treecanopy of all 30x30m cells within a cirlce defined around each point with a 400 m radius"
  )

saveRDS(d, "data/nlcd.rds")
