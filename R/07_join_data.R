library(CODECtools)
library(fs)
library(dplyr)
library(readr)

d <- readRDS("data/geocodes.rds")

n.admission = dim(d)[1]
n.address = d |> filter(!duplicated(d$parsed_address)) |> nrow()
n.geocoded = d |> filter(!duplicated(d$parsed_address)) |> filter(geocode_result == "geocoded") |> nrow()
n.geocoded.hc = d |> filter(!duplicated(d$parsed_address)) |> filter(geocode_result == "geocoded") |> filter(hamilton_zip == 1) |> nrow()

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
  n.parcel = parcel |> filter(!duplicated(parcel$address)) |> filter(!is.na(parcel_id)) |> filter(hamilton_zip == 1) |> nrow()
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

# summary message

message(
  "Among a total of ",
  scales::number(n.admission, big.mark = ","),
  " hospital admissions, there are ",
  scales::number(n.address, big.mark = ","),
  " (", scales::percent(n.address / n.admission), ")",
  " unique addresses; \n",
  scales::number(n.geocoded, big.mark = ","), " of ", 
  scales::number(n.address, big.mark = ","),
  " (", scales::percent(n.geocoded / n.address), ")",
  " unique addresses are geocoded; \n",
  scales::number(n.geocoded.hc, big.mark = ","), " of ", 
  scales::number(n.geocoded, big.mark = ","),
  " (", scales::percent(n.geocoded.hc / n.geocoded), ")",
  " geocoded unique addresses are Hamilton county addresses; and \n",
  scales::number(n.parcel, big.mark = ","), " of ", 
  scales::number(n.geocoded.hc, big.mark = ","),
  " (", scales::percent(n.parcel / n.geocoded.hc),")",
  " geocoded Hamilton addresses are matched to one or more parcel IDs."
)

