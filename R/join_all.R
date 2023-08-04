library(dplyr, warn.conflicts = FALSE)
library(codec)

guid <- c("PAT_ENC_CSN_ID", "HOSP_ADMSN_TIME", "PAT_MRN_ID")

data_names <- c("cleaned_addresses", "geocodes", "daily", "census_tract_level_data",
                "nlcd", "exact_location_geomarkers", "parcel")

d <-
  fs::path("data", data_names, ext = "rds") |>
  purrr::map(readRDS, .progress = "reading intermediate targets") |>
  setNames(data_names) |>
  purrr::reduce(left_join, by = guid) |>
  select(-ends_with(c(".x", ".y")))

d <- d |>
  add_attrs(
    name = "riseup_geomarker_pipeline_output",
    version = "1.0.0",
    title = "RISEUP Geomarkers",
    description = "Hosptial admission data joined with geomarkers",
    homepage = "https://github.com/geomarker-io/riseup_geomarker_pipeline",
  )

saveRDS(d, "data/riseup_geomarker_pipeline_output.rds")
