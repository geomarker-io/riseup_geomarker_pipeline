library(dplyr, warn.conflicts = FALSE)
library(dht)
library(codec)

d <-
  readRDS("data/cleaned_addresses.rds") |>
  select(-raw_address)

# geocode
readr::write_csv(d, "data/address_for_geocoding.csv")

system2("docker",
        c("run", "--rm",
          "-v ./data:/tmp",
          "ghcr.io/degauss-org/geocoder:3.3.0-v8",
          "address_for_geocoding.csv"))

d <-
  readr::read_csv("data/address_for_geocoding_geocoder_3.3.0_score_threshold_0.5.csv", col_types = readr::cols(
  PAT_ENC_CSN_ID = readr::col_character(),
  HOSP_ADMSN_TIME = readr::col_date(format = "%Y-%m-%d"),
  PAT_MRN_ID = readr::col_character(),
  address = readr::col_character(),
  matched_street = readr::col_character(),
  matched_zip = readr::col_double(),
  matched_city = readr::col_character(),
  matched_state = readr::col_character(),
  lat = readr::col_double(),
  lon = readr::col_double(),
  score = readr::col_double(),
  precision = readr::col_character(),
  geocode_result = readr::col_character()
  ))

d <- d |>
  dht::degauss_run("geocoder", "3.3.0-v8", quiet = FALSE) |>
  select(-starts_with("matched_")) |>
  select(-score, -precision)

# add column attributes
d <- d |>
  add_col_attrs(lat,
    title = "Latitude",
    description = "geocoded latitude coordinate"
  ) |>
  add_col_attrs(lon,
    title = "Longitude",
    description = "geocoded longitude coordinate"
  ) |>
  add_col_attrs(geocode_result,
    title = "Geocode Result",
    description = "character string summarizing the geocoding result (geocoded: the address was geocoded with a precision of either range or street and a score of 0.5 or greater; imprecise_geocode: the address was geocoded, but results were suppressed because the precision was intersection, zip, or city and/or the score was less than 0.5; po_box: the address was not geocoded because it is a PO Box; cincy_inst_foster_addr: the address was not geocoded because it is a known institutional address, not a residential address; non_address_text: the address was not geocoded because it was blank or listed as “foreign”, “verify”, or “unknown”)"
  )

# 2010 census block group and tract
d <-
  d |>
  degauss_run("census_block_group", "0.6.0", argument = "2010", quiet = FALSE) |>
  add_col_attrs(census_block_group_id_2010,
    title = "2010 Census Block Group identifer"
  ) |>
  add_col_attrs(census_tract_id_2010,
    title = "2010 Census Tract identifer"
  )

# 2020 census block group and tract
d <-
  d |>
  degauss_run("census_block_group", "0.6.0", argument = "2020", quiet = FALSE) |>
  add_col_attrs(census_block_group_id_2020,
    title = "2020 Census Block Group identifer"
  ) |>
  add_col_attrs(census_tract_id_2020,
    title = "2020 Census Tract identifer"
  )

d <- select(d, -address)

saveRDS(d, "data/geocodes.rds")
