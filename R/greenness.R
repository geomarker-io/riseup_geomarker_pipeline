library(dplyr, warn.conflicts = FALSE)
library(sf)
library(fr, warn.conflicts = FALSE)
library(terra)
library(s3)

rd <- readRDS("data/geocodes.rds")

d_vect <-
  tibble::as_tibble(rd) |>
  select(PAT_ENC_CSN_ID, ADMIT_DATE, MRN, lat, lon) |>
  na.omit() |>
  distinct(.keep_all = TRUE) |>
  st_as_sf(coords = c("lon", "lat"), crs = 4326) |>
  st_transform(5072) |>
  st_buffer(dist = 750) |>
  vect()

roi <- cincy::county_hlthv_2010 |> st_union()

impervious_raster <-
  s3_get("s3://geomarker/modis_evi_ndvi/evi_June_2018_5072.tif") |>
  rast() |>
  crop(roi)

d_vect$evi_750 <- round(terra::extract(impervious_raster, d_vect, fun = "mean", ID = FALSE)[, "evi_June_2018_5072"] * 0.0001, 4)

out <-
  tibble::as_tibble(rd) |>
  select(PAT_ENC_CSN_ID, ADMIT_DATE, MRN) |>
  left_join(as_tibble(d_vect), by = c("PAT_ENC_CSN_ID", "ADMIT_DATE", "MRN")) |>
  as_fr_tdr(.template = rd)
out@name <- "greenness"

out <- update_field(out, "evi_750",
                    title = "Enhanced Vegetation Index (750m)",
                    description = "average enhanced vegetation index from June 2018 within a 750 meter buffer radius")

saveRDS(out, "data/greenness.rds")

