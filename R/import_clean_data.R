library(dplyr, warn.conflicts = FALSE)
library(readr)
library(fr)

# read in raw admission data
# warning messages are related to ADMIT_DATE_TIME values that are missing a time component
# these are still parsed correctly as dates, despite the warnings
d <- read_csv("data/DR1767_r2.csv",
  na = c("NA", "-", "NULL", "null"),
  col_types = cols_only(
    MRN = col_character(),
    PAT_ENC_CSN_ID = col_character(),
    ADMIT_DATE_TIME = col_datetime(format = "%m/%d/%Y %I:%M:%S %p"),
    ADDRESS = col_character(),
    CITY = col_character(),
    STATE = col_character(),
    ZIP = col_character()
  )
  ) |>
  mutate(ADMIT_DATE = as.Date(ADMIT_DATE_TIME)) |>
  select(-ADMIT_DATE_TIME)

# remove duplicated PAT_ENC_CSN_ID
d <- d |> filter(!duplicated(d$PAT_ENC_CSN_ID))

# limit data to patients encountered between 1/1/2016 and 12/31/2021
d <- d |> filter(ADMIT_DATE >= as.Date("2016-01-01") & ADMIT_DATE <= as.Date("2021-12-31"))

# create address from address components
d <- d |>
  tidyr::unite(
    "raw_address",
    c(ADDRESS, CITY, STATE, ZIP),
    sep = " ", na.rm = TRUE
  )

# tag address components
d <- d |>
  mutate(address_tags = purrr::map(raw_address, parcel::tag_address, .progress = "tagging addresses")) |>
  tidyr::unnest(cols = address_tags)

# add hamilton_zip_code flag
d <- mutate(d, hamilton_zip_code = zip_code %in% cincy::zcta_tigris_2020$zcta_2020)

# add address created from components
d <- tidyr::unite(d, "address", street_number, street_name, city, state, zip_code, remove = FALSE, na.rm = TRUE, sep = " ")

out <-
  as_fr_tdr(d, name = "cleaned_addresses") |>
  update_field("raw_address", description = "Concatenation of `ADDRESS`, `CITY`, `STATE`, `ZIP`") |>
  update_field("address", description = "Concatenation of tagged address components") |>
  update_field("street_number", description = "Tagged street number") |>
  update_field("street_name", description = "Tagged street name") |>
  update_field("city", description = "Tagged city") |>
  update_field("state", description = "Tagged state") |>
  update_field("zip_code", description = "First five digits of the tagged ZIP code") |>
  update_field("hamilton_zip_code", description = "TRUE if tagged ZIP code is in `cincy::zcta_tigris_2020`")

fs::dir_create("data")
saveRDS(out, "data/cleaned_addresses.rds")
