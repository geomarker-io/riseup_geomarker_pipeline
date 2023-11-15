library(dplyr, warn.conflicts = FALSE)
library(readr)
library(fr)

# read in raw admission data
d <- read_csv("data/HospitalAdmissions.csv",
  na = c("NA", "-", "NULL"),
  col_types = cols_only(
    PAT_MRN_ID = col_character(),
    PAT_ENC_CSN_ID = col_character(),
    HOSP_ADMSN_TIME = col_date(),
    PAT_ADDR_1 = col_character(),
    PAT_ADDR_2 = col_character(),
    PAT_CITY = col_character(),
    PAT_STATE = col_character(),
    PAT_ZIP = col_character()
  )
)

# remove duplicated PAT_ENC_CSN_ID
d <- filter(d, !duplicated(d$PAT_ENC_CSN_ID))

# limit data to patients admitted between 1/1/2016 and 12/31/2021
d <- d |> filter(HOSP_ADMSN_TIME >= as.Date("2016-01-01") & HOSP_ADMSN_TIME <= as.Date("2021-12-31"))

# create address from address components
d <- d |>
  tidyr::unite(
    "raw_address",
    c(PAT_ADDR_1, PAT_ADDR_2, PAT_CITY, PAT_STATE, PAT_ZIP),
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
  update_field("raw_address", description = "Concatenation of `PAT_ADDR_1`, `PAT_ADDR_2`, `PAT_CITY`, `PAT_STATE`, `PAT_ZIP`") |>
  update_field("address", description = "Concatenation of tagged address components") |>
  update_field("street_number", description = "Tagged street number") |>
  update_field("street_name", description = "Tagged street name") |>
  update_field("city", description = "Tagged city") |>
  update_field("state", description = "Tagged state") |>
  update_field("zip_code", description = "First five digits of the tagged ZIP code") |>
  update_field("street_number", description = "Tagged street number") |>
  update_field("hamilton_zip_code", description = "TRUE if tagged ZIP code is in `cincy::zcta_tigris_2020`")

fs::dir_create("data")
saveRDS(out, "data/cleaned_addresses.rds")
