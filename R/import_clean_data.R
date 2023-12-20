library(dplyr, warn.conflicts = FALSE)
library(readr)

# read in raw admission data
d <- read_csv("data/DR1767_r2.csv",
  na = c("NA", "-", "NULL", "null"),
  col_types = cols_only(
    MRN = col_character(),
    PAT_ENC_CSN_ID = col_character(),
    ADMIT_DATE_TIME = col_character(),
    ADDRESS = col_character(),
    CITY = col_character(),
    STATE = col_character(),
    ZIP = col_character()
  )
) 

# remove duplicated PAT_ENC_CSN_ID
d <- d |> 
  filter(!duplicated(d$PAT_ENC_CSN_ID)) |> 
  tidyr::separate(ADMIT_DATE_TIME, into = c("ADMIT_DATE", "ADMIT_TIME", "AMPM"), sep = " ") |> 
  mutate(ADMIT_DATE = lubridate::mdy(ADMIT_DATE)) |> 
  select(-ADMIT_TIME, -AMPM)

# limit data to patients admitted between 1/1/2016 and 12/31/2021
d <- d |> filter(ADMIT_DATE >= as.Date("2016-01-01") & ADMIT_DATE <= as.Date("2021-12-31"))

# create address from address components
d <- d |>
  tidyr::unite(
    "raw_address",
    c(ADDRESS, CITY, STATE, ZIP),
    sep = " ", na.rm = TRUE
  )

# clean and parse out unnecessary address components with parcel
d <- d |>
  mutate(address_tags = purrr::map(raw_address, parcel::tag_address, .progress = "tagging addresses")) |>
  tidyr::unnest(cols = address_tags) |>
  tidyr::unite("address", street_number, street_name, city, state, zip_code, remove = TRUE, na.rm = FALSE, sep = " ")

fs::dir_create("data")
saveRDS(d, "data/cleaned_addresses.rds")
