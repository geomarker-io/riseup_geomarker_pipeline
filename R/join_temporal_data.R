
library(tidyverse)
library(CODECtools)

d <-
  c("hospital_admission","daily_data") |>
  map(~ readRDS(paste0("data/", ., ".rds"))) |>
  reduce(dplyr::left_join, by = c("HOSP_ADMSN_TIME" = "date"))

d <- d |>
  add_attrs(
    name = "hospital_admission_joined_temporal_data",
    version = "1.0.0",
    title = "Hosptial Admission Joined with temporal data",
    description = "Hosptial admission data joined with temporal data related to air quality, weather, and crime",
    homepage = "https://github.com/geomarker-io/riseup_geomarker_pipeline",
  ) |>
  add_type_attrs()

saveRDS(d, "data/hospital_admission_joined_temporal_data.rds")




