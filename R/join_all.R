library(dplyr)
## library(codec)
## library(fs)
## library(readr)

guid <- c("PAT_ENC_CSN_ID", "HOSP_ADMSN_TIME", "PAT_MRN_ID")

data_names <- c("cleaned_addresses", "geocodes", "daily", "census_tract_level_data",
                "nlcd", "exact_location_geomarkers", "parcel")

d <-
  fs::path("data", data_names, ext = "rds") |>
  purrr::map(readRDS, .progress = "reading intermediate targets") |>
  setNames(data_names) |>
  purrr::reduce(left_join, by = guid) |>
  select(-ends_with(c(".x", ".y")))

d <- d |>
  add_attrs(
    name = "riseup_geomarker_pipeline_output",
    version = "1.0.0",
    title = "RISEUP Geomarkers",
    description = "Hosptial admission data joined with geomarkers",
    homepage = "https://github.com/geomarker-io/riseup_geomarker_pipeline",
  )

codec::glimpse_tdr(d)

saveRDS(d, "data/riseup_geomarker_pipeline_output.rds")

codec::write_tdr_csv(d, "data")

# summary message

message(
  "Among a total of ",
  scales::number(n.admission, big.mark = ","),
  " hospital admissions, there are ",
  scales::number(n.address, big.mark = ","),
  " (", scales::percent(n.address / n.admission), ")",
  " unique addresses; \n",
  scales::number(n.geocoded, big.mark = ","), " of ",
  scales::number(n.address, big.mark = ","),
  " (", scales::percent(n.geocoded / n.address), ")",
  " unique addresses are geocoded; \n",
  scales::number(n.geocoded.hc, big.mark = ","), " of ",
  scales::number(n.geocoded, big.mark = ","),
  " (", scales::percent(n.geocoded.hc / n.geocoded), ")",
  " geocoded unique addresses are Hamilton county addresses; and \n",
  scales::number(n.parcel, big.mark = ","), " of ",
  scales::number(n.geocoded.hc, big.mark = ","),
  " (", scales::percent(n.parcel / n.geocoded.hc), ")",
  " geocoded Hamilton addresses are matched to one or more parcel IDs."
)

d |>
  mutate(zip = stringr::str_sub(parsed_address, -5)) |>
  filter(zip %in% cincy::zcta_tigris_2010$zcta_2010) #  63,247

d |>
  mutate(zip = stringr::str_sub(parsed_address, -5)) |>
  filter(zip %in% cincy::zcta_tigris_2010$zcta_2010) |>
  filter(geocode_result != "cincy_inst_foster_addr") # 61,117

d |>
  filter(!is.na(parcel_id)) # 40,980

40980 / 63247
# 65% addresses with hc ZIP are matched to a parcel
