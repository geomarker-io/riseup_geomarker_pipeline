library(CODECtools)
library(fs)
library(dplyr)
library(readr)

d <- readRDS("data/geocodes.rds")

if (fs::file_exists("data/exact_location_geomarkers.rds")) {
  exact <- readRDS("data/exact_location_geomarkers.rds")
  d <- left_join(d, exact)
}

if (fs::file_exists("data/census_tract_level_data.rds")) {
  tract <- readRDS("data/census_tract_level_data.rds")
  d <- left_join(d, tract)
}

if (fs::file_exists("data/parcel_data.rds")) {
  parcel <- readRDS("data/parcel_data.rds")
  d <- left_join(d, parcel)
}

if (fs::file_exists("data/daily_data.rds")) {
  time <- readRDS("data/daily_data.rds")
  d <- left_join(d, time, by = c("HOSP_ADMSN_TIME" = "date"))
}

d <- d |>
  add_attrs(
    name = "riseup_geomarker_pipeline_output",
    version = "1.0.0",
    title = "RISEUP Geomarkers",
    description = "Hosptial admission data joined with geomarkers",
    homepage = "https://github.com/geomarker-io/riseup_geomarker_pipeline",
  )

saveRDS(d, "data/riseup_geomarker_pipeline_output.rds")

CODECtools::write_tdr_csv(d, "data/")

