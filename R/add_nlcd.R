
library(tidyverse)
library(dht)
library(sf)
library(CODECtools)
library(terra)

d <- readRDS("data/geocodes.rds")

# make buffers around points
d.point <- d |>
  select(PAT_ENC_CSN_ID, lat, lon) %>%
  filter(complete.cases(.)) |> # keep geocoded ones
  distinct(.keep_all = TRUE) # remove duplicated records while adding parcel ID

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

## Download raster file
options(timeout = 3000)
download_dir <- fs::path_wd("nlcd_downloads")
dir.create(download_dir, showWarnings = FALSE)

# impervious
download_impervious <- function(yr = 2019) {
  nlcd_file_path <- fs::path(download_dir, glue::glue("nlcd_impervious_{yr}.tif"))
  if (file.exists(nlcd_file_path)) return(nlcd_file_path)
  withr::with_tempdir({
    download.file(glue::glue("https://s3-us-west-2.amazonaws.com/mrlc/nlcd_{yr}_impervious_l48_20210604.zip"),
                  destfile = glue::glue("nlcd_impervious_{yr}.zip"))
    unzip(glue::glue("nlcd_impervious_{yr}.zip"))
    system2(
      "gdal_translate",
      c(
        "-of COG",
        glue::glue("nlcd_{yr}_impervious_l48_20210604.img"),
        shQuote(fs::path(download_dir, glue::glue("nlcd_impervious_{yr}.tif")))
      )
    )
  })
  return(nlcd_file_path)
}

impervious_raster <- download_impervious(yr=2019) |> rast()

hv <- cincy::county_hlthv_2010 |> st_union()
impervious_hv_2019 <- terra::crop(impervious_raster, hv)

pct_impervious <-
  terra::extract(impervious_hv_2019,
    d.buffered,
    fun = "mean"
  ) |>
  rename(value = Layer_1) |>
  summarize(pct_impervious_2019 = round(value))

d.pct_impervious <- bind_cols(d.point, pct_impervious) |>
  unnest(PAT_ENC_CSN_ID) |>
  st_drop_geometry()

# tree canopy
download_treecanopy <- function(yr = 2019) {
  nlcd_file_path <- fs::path(download_dir, glue::glue("nlcd_treecanopy_{yr}.tif"))
  if (file.exists(nlcd_file_path)) return(nlcd_file_path)
  withr::with_tempdir({
    download.file(glue::glue("https://s3-us-west-2.amazonaws.com/mrlc/nlcd_tcc_CONUS_{yr}_v2021-4.zip"),
                  destfile = glue::glue("nlcd_treecanopy_{yr}.zip"))
    unzip(glue::glue("nlcd_treecanopy_{yr}.zip"))
    system2(
      "gdal_translate",
      c(
        "-of COG",
        "-co BIGTIFF=YES",
        glue::glue("nlcd_tcc_conus_{yr}_v2021-4.tif"),
        shQuote(fs::path(download_dir, glue::glue("nlcd_treecanopy_{yr}.tif")))
      )
    )
  })
  return(nlcd_file_path)
}

treecanopy_raster <- download_treecanopy(yr=2019) |> rast()

hv <- cincy::county_hlthv_2010 |> st_union()
treecanopy_hv_2019 <- terra::crop(treecanopy_raster, hv)

pct_treecanopy <-
  terra::extract(treecanopy_hv_2019,
    d.buffered,
    fun = "mean"
  ) |>
  rename(value = Layer_1) |>
  summarize(pct_treecanopy_2019 = round(value))

d.pct_treecanopy <- bind_cols(d.point, pct_treecanopy) |>
  unnest(PAT_ENC_CSN_ID) |>
  st_drop_geometry()

# merge
d <- d.pct_impervious |>
  left_join(d.pct_treecanopy, by = "PAT_ENC_CSN_ID")

# add column attributes
d <- d |>
  add_col_attrs(pct_impervious_2019,
    title = "percentage impervious",
    description = "average percent impervious of all nlcd cells overlapping the buffer"
  ) |>
  add_col_attrs(pct_treecanopy_2019,
    title = "percentage treecanopy",
    description = "average percent tree canopy cover of all nlcd cells overlapping the buffer"
  )

saveRDS(d, "data/nlcd.rds")



