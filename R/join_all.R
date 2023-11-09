library(dplyr, warn.conflicts = FALSE)
library(fr)

guid <- c("PAT_ENC_CSN_ID", "HOSP_ADMSN_TIME", "PAT_MRN_ID")

data_names <- c("cleaned_addresses",
                "geocodes",
                "daily",
                "census_tract_level_data",
                "nlcd",
                "exact_location_geomarkers",
                "parcel")

d <-
  fs::path("data", data_names, ext = "rds") |>
  purrr::map(readRDS, .progress = "reading intermediate targets") |>
  setNames(data_names) |>

  # TODO how to merge metadata across all?

  ## purrr::reduce(left_join, by = guid)

# rename score from geocoder and score from parcel to unique names
d <- d |>
  rename(score_geocoder = score.x,
         score_parcel = score.y)

d <- d |>
  as_fr_tdr(
    name = desc::desc_get("Package"),
    version = desc::desc_get("Version"),
    title = desc::desc_get("Title"),
    description = desc::desc_get("Description"),
    homepage = desc::desc_get("URL"),
  )

saveRDS(d, "data/riseup_geomarker_pipeline_output.rds")
