## reticulate::use_virtualenv("r-parcel")
library(parcel)
library(dplyr, warn.conflicts = FALSE)
library(fr)

rd <- readRDS("data/cleaned_addresses.rds")
d <- tibble::as_tibble(rd)
message(nrow(d), " observations")

d <- d |>
  filter(hamilton_zip_code) |>
  select(PAT_ENC_CSN_ID, MRN, ADMIT_DATE, address)

message(nrow(d), " observations with hamilton zip code")

d_tract <-
  readRDS("data/census_tract_level_data.rds") |>
  tibble::as_tibble() |>
  select(PAT_ENC_CSN_ID, MRN, ADMIT_DATE, census_tract_id)
d <- left_join(d, d_tract, by = c("PAT_ENC_CSN_ID", "MRN", "ADMIT_DATE"))

d <- d |> filter(!is.na(census_tract_id))

message(nrow(d), " observations with hamilton zip code, census_tract_id")

d <- d |> filter(substr(census_tract_id, 1, 5) == "39061")

message(nrow(d), " observations with hamilton zip code, census_tract_id, geocoded to Hamilton County")

d_out <- d |> bind_cols(get_parcel_data(d$address))

d_out <- d_out |>
  rename(parcel_match_score = score)

message(nrow(filter(d_out, !is.na(parcel_id))), " observations with hamilton zip code, census_tract_id, geocoded to Hamilton County, matched with a parcel identifier")

message("parcel match rate: ", round(nrow(filter(d_out, !is.na(parcel_id))) / nrow(d), digits = 3))

# housing violation data
rd_violation <- fr::read_fr_tdr("https://github.com/geomarker-io/curated_violations/releases/download/0.1.2/tabular-data-resource.yaml")

d_violation <-
  rd_violation |>
  tibble::as_tibble() |>
  filter(date >= as.Date("2014-01-01") & date <= as.Date("2021-12-31")) |> 
  mutate(paint_violation = stringr::str_detect(violation_type, "PAINT")) |>
  group_by(parcel_number) |> 
  summarize(n_violation = n(),
            n_paint_violation = sum(paint_violation))

# merge with admission data
d_out <-
  d_out |>
  left_join(d_violation, by = join_by(parcel_id == parcel_number)) |>
  mutate(
    any_housing_violation = case_when(
      !is.na(n_violation) ~ TRUE,
      is.na(n_violation) & !(parcel_id %in% c(NA, "TIED_MATCHES")) ~ FALSE,
      parcel_id %in% c(NA, "TIED_MATCHES") ~ NA
    ),
    any_paint_violation = case_when(
      n_paint_violation > 0 ~ TRUE,
      n_paint_violation == 0 ~ FALSE,
      !any_housing_violation ~ FALSE,
      parcel_id %in% c(NA, "TIED_MATCHES") ~ NA
    )
  )

out <-
  d_out |>
  select(-address, -census_tract_id, -input_address) |>
  as_fr_tdr(.template = rd) |>
  update_field("n_violation",
                title = "Number of housing violations",
                description = "Number of housing violations issued between 2014 and 2021") |>
  update_field("any_housing_violation",
                title = "Any housing violation issued",
                description = "Any housing violation issued between 2014 and 2021 (True/False)") |>
  update_field("n_paint_violation",
                title = "Number of paint related violations",
                description = "Number of paint related violations issued between 2014 and 2021") |>
  update_field("any_paint_violation",
                title = "Any paint related violation issued",
                description = "Any paint related violation issued between 2014 and 2021 (True/False)") 

out@name <- "parcel"

saveRDS(out, "data/parcel.rds")
