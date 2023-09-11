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
          ifelse(grepl("darwin", version$os), # use alt tag for m1/m2 macs
                 "ghcr.io/degauss-org/geocoder:3.3.0-v8",
                 "ghcr.io/degauss-org/geocoder:3.3.0"),
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

d <- select(d, -address)

saveRDS(d, "data/geocodes.rds")
