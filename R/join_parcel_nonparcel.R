
library(tidyverse)
library(CODECtools)

d <-
  c("hospital_admission_joined_nonparcel","parcel_data") |>
  map(~ readRDS(paste0("data/", ., ".rds"))) |>
  reduce(dplyr::left_join, by = "PAT_ENC_CSN_ID")

d <- d |>
  add_attrs(
    name = "hospital_admission_joined_parcel_nonparcel",
    version = "1.0.0",
    title = "Hosptial Admission Joined with DeGAUSS Geomarker, Census Tract Level Data, and Parcel Data",
    description = "Hosptial admission data joined with geomarkers from DeGAUSS geomarker library and census tract level data from Census Tract-Level Neighborhood Indices data source, American Community Survey (ACS), National Land Cover Database (NLCD), and Applied Geographic Solutions (AGS) as well as Cincinnati Area Geographic Information System (CAGIS) parcel data",
    homepage = "https://github.com/geomarker-io/riseup_geomarker_pipeline",
  ) |>
  add_type_attrs()

saveRDS(d, "data/hospital_admission_joined_parcel_nonparcel.rds")


# summary message
n.total = length(unique(d$PAT_ENC_CSN_ID))
n.geocoded = d |> 
  select(PAT_ENC_CSN_ID, geocode_result) |> 
  distinct() |> 
  filter(geocode_result == "geocoded") |> 
  nrow()
n.parcel = d |> 
  select(PAT_ENC_CSN_ID, parcel_id) |> 
  filter(!is.na(parcel_id)) |> 
  group_by(PAT_ENC_CSN_ID) |> 
  summarise(n = n()) |> 
  nrow()

message(
  "Among a total of ",
  scales::number(n.total, big.mark = ","),
  " hospital admissions, ",
  scales::number(n.geocoded, big.mark = ","),
  " (", scales::percent(n.geocoded / n.total), ")",
  " were geocoded, and ",
  scales::number(n.parcel, big.mark = ","),
  " (", scales::percent(n.parcel / n.total),")",
  " were matched to one or more parcel IDs."
)

