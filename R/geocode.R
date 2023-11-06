library(dplyr, warn.conflicts = FALSE)
library(dht)
library(fr)

rd <- readRDS("data/cleaned_addresses.rds")

d <-
  rd |>
  tibble::as_tibble() |>
  select(PAT_ENC_CSN_ID, HOSP_ADMSN_TIME, PAT_MRN_ID, address)

# geocode
readr::write_csv(d, "data/address_for_geocoding.csv")
system2(
  "docker",
  c(
    "run", "--rm",
    "-v ${PWD}/data:/tmp",
    ifelse(grepl("darwin", version$os), # use alt tag for m1/m2 macs
      "ghcr.io/degauss-org/geocoder:3.3.0-v8",
      "ghcr.io/degauss-org/geocoder:3.3.0"
    ),
    "address_for_geocoding.csv"
  )
)
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

out <-
  d |>
  select(-address) |>
  as_fr_tdr(.template = rd)

out@name <- "geocodes"

out <-
  out |>
  update_field("lat", description = "geocoded latitude coordinate") |>
  update_field("lon", description = "geocoded longitude coordinate") |>
  update_field("geocode_result", description = "character string summarizing the geocoding result (geocoded: the address was geocoded with a precision of either range or street and a score of 0.5 or greater; imprecise_geocode: the address was geocoded, but results were suppressed because the precision was intersection, zip, or city and/or the score was less than 0.5; po_box: the address was not geocoded because it is a PO Box; cincy_inst_foster_addr: the address was not geocoded because it is a known institutional address, not a residential address; non_address_text: the address was not geocoded because it was blank or listed as 'foreign', 'verify', or 'unknown')") |>
  update_field("precision", description = "The method/precision of the geocode; one of `range`: interpolated based on address ranges from street segments, `street`: center of the matched street, `intersection`: intersection of two streets, `zip`: centroid of the matched zip code, `city`: centroid of the matched city") |>
  update_field("score", description = "The percentage of text match between the given address and the geocoded result, expressed as a number between 0 and 1. A higher score indicates a closer match. Note that each score is relative within a precision method (i.e. a score of 0.8 with a precision of range is not the same as a score of 0.8 with a precision of street)")

saveRDS(out, "data/geocodes.rds")
