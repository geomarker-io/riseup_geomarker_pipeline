library(dplyr)
library(readr)

# read in raw admission data
d <- read_csv("data-raw/HospitalAdmissions.csv",
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

# TODO remove this temporary smaller dataset
set.seed(11)
d <- d |>
  slice_sample(n = 1, by = PAT_MRN_ID) |>
  slice_sample(n = 2000)

# create address from address components
d <- d |>
  tidyr::unite(
    "raw_address",
    c(PAT_ADDR_1, PAT_ADDR_2, PAT_CITY, PAT_STATE, PAT_ZIP),
    sep = " ", na.rm = TRUE
  )

# clean and parse addresses with postal
d <-
  d |>
  rename(address = raw_address) |>
  dht::degauss_run("postal", "0.1.4", quiet = FALSE) |>
  rename(raw_address = address)

# Hamilton county flag
d <- mutate(d, hamilton_zip = parsed.postcode_five %in% cincy::zcta_tigris_2020)

fs::dir_create("data")
d |>
  select(-starts_with("parsed."), -cleaned_address) |>
  saveRDS("data/cleaned_addresses.rds")
