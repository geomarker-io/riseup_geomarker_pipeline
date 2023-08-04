library(dplyr, warn.conflicts = FALSE)
library(readr)

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

# clean and parse out unnecessary address components with parcel
d <- d |>
  mutate(address_tags = purrr::map(raw_address, parcel::tag_address, .progress = "tagging addresses")) |>
  tidyr::unnest(cols = address_tags) |>
  tidyr::unite("address", street_number, street_name, city, state, zip_code, remove = TRUE, na.rm = FALSE, sep = " ")

fs::dir_create("data")
saveRDS(d, "data/cleaned_addresses.rds")
