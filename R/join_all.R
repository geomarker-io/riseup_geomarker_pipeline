library(dplyr, warn.conflicts = FALSE)
library(fr)

guid <- c("PAT_ENC_CSN_ID", "HOSP_ADMSN_TIME", "PAT_MRN_ID")

data_names <- c("cleaned_addresses",
                "geocodes",
                "daily",
                "greenness",
                "drivetime",
                "traffic",
                "nlcd",
                "census_tract_level_data",
                "parcel")

d <-
  fs::path("data", data_names, ext = "rds") |>
  purrr::map(readRDS, .progress = "reading intermediate targets") |>
  setNames(data_names)

out <- d |>
  purrr::reduce(left_join, by = guid) |>
  as_fr_tdr(
    name = desc::desc_get("Package"),
    version = desc::desc_get("Version"),
    title = desc::desc_get("Title"),
    description = desc::desc_get("Description"),
    homepage = desc::desc_get("URL"),
  )

# convert fields to a list and then use to update_field
d_fields <-
  d |>
  purrr::modify(as.list) |>
  purrr::modify(\(.) purrr::pluck(., "schema", "fields")) |>
  purrr::compact() |>
  purrr::list_flatten(name_spec = "{inner}")

the_fields <- unique(names(d_fields))

out <-
  purrr::reduce2(
    the_fields,
    d_fields[the_fields],
    \(accum, xx, yy) fr::update_field(x = accum, field = xx, !!!yy),
    .init = out)

saveRDS(out, "data/riseup_geomarker_pipeline_output.rds")
