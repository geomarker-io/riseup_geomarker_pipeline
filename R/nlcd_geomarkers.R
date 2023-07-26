## library(tidyverse)
library(dplyr)
library(dht)
library(sf)
library(codec)
library(terra)

# options for downloaded rasters
options(timeout = 3000)
download_dir <- fs::path_wd("nlcd_downloads")
dir.create(download_dir, showWarnings = FALSE)

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

# impervious
download_impervious <- function(yr = 2019) {
  nlcd_file_path <- fs::path(download_dir, glue::glue("nlcd_impervious_{yr}.tif"))
  if (file.exists(nlcd_file_path)) {
    return(nlcd_file_path)
  }
  withr::with_tempdir({
    download.file(glue::glue("https://s3-us-west-2.amazonaws.com/mrlc/nlcd_{yr}_impervious_l48_20210604.zip"),
      destfile = glue::glue("nlcd_impervious_{yr}.zip")
    )
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

impervious_raster <- download_impervious(yr = 2019) |> rast()
hv <- cincy::county_hlthv_2010 |> st_union()
impervious_hv_2019 <- terra::crop(impervious_raster, hv)

xx <- terra::extract(impervious_hv_2019, d_vect, fun = "mean", ID = FALSE)
d_vect$pct_impervious_2019 <- round(xx[, "Layer_1"])

# tree canopy
download_treecanopy <- function(yr = 2019) {
  nlcd_file_path <- fs::path(download_dir, glue::glue("nlcd_treecanopy_{yr}.tif"))
  if (file.exists(nlcd_file_path)) {
    return(nlcd_file_path)
  }
  withr::with_tempdir({
    download.file(glue::glue("https://s3-us-west-2.amazonaws.com/mrlc/nlcd_tcc_CONUS_{yr}_v2021-4.zip"),
      destfile = glue::glue("nlcd_treecanopy_{yr}.zip")
    )
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

treecanopy_raster <- download_treecanopy(yr = 2019) |> rast()
hv <- cincy::county_hlthv_2010 |> st_union()
treecanopy_hv_2019 <- terra::crop(treecanopy_raster, hv)

xx <- terra::extract(treecanopy_hv_2019, d_vect, fun = "mean", ID = FALSE)
d_vect$pct_treecanopy_2019 <- round(xx[, "Layer_1"])

d <- d |>
  left_join(as_tibble(d_vect), by = "PAT_ENC_CSN_ID") |>
  add_col_attrs(pct_impervious_2019,
    title = "Percentage Impervious",
    description = "Average percent impervious of all 30x30m cells within a cirlce defined around each point with a 400 m radius"
  ) |>
  add_col_attrs(pct_treecanopy_2019,
    title = "percentage treecanopy",
    description = "Average percent treecanopy of all 30x30m cells within a cirlce defined around each point with a 400 m radius"
  )

saveRDS(d, "data/nlcd.rds")
