
library(tidyverse)
library(CODECtools)

d <-
  c("hospital_admission","degauss_geomarker_library", "nlcd", "census_tract_lvl_data") |>
  map(~ readRDS(paste0("data/", ., ".rds"))) |>
  reduce(dplyr::left_join, by = "PAT_ENC_CSN_ID")

d <- d |>
  add_attrs(
    name = "hospital_admission_joined_nonparcel",
    version = "1.0.0",
    title = "Hosptial Admission Joined with DeGAUSS Geomarker and Census Tract Level Data",
    description = "Hosptial admission data joined with geomarkers from DeGAUSS geomarker library and census tract level data from Census Tract-Level Neighborhood Indices data source, American Community Survey (ACS), National Land Cover Database (NLCD), and Applied Geographic Solutions (AGS)",
    homepage = "https://github.com/geomarker-io/riseup_geomarker_pipeline",
  ) |>
  add_type_attrs()

saveRDS(d, "data/hospital_admission_joined_nonparcel.rds")


# summary message
n.total = length(unique(d$PAT_ENC_CSN_ID))
n.geocoded = d |> 
  select(PAT_ENC_CSN_ID, geocode_result) |> 
  distinct() |> 
  filter(geocode_result == "geocoded") |> 
  nrow()

message(
  "Among a total of ",
  scales::number(n.total, big.mark = ","),
  " hospital admissions, ",
  scales::number(n.geocoded, big.mark = ","),
  " (", scales::percent(n.geocoded / n.total), ")",
  " were geocoded."
)
