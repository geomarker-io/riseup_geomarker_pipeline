library(parcel)
library(dplyr, warn.conflicts = FALSE)
library(codec)

d <- readRDS("data/cleaned_addresses.rds")
d_out <- d |> bind_cols(get_parcel_data(d$address))

# housing violation data
d_violation <-
  codec::read_tdr_csv("https://github.com/geomarker-io/curated_violations/releases/download/0.1.2/tabular-data-resource.yaml") |>
  filter(date >= as.Date("2014-01-01") & date <= as.Date("2021-12-31")) |> 
  mutate(paint_violation = str_detect(violation_type, "PAINT"))   # paint violation indicator

d_violation <- d_violation |> 
  group_by(parcel_number) |> 
  summarize(n_violation = n(),
            n_paint_violation = sum(paint_violation))  # summarize

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

d_out <- d_out |>
  add_col_attrs(n_violation,
    title = "Number of housing violations",
    description = "Number of housing violations issued between 2014 and 2021"
  ) |>
  add_col_attrs(any_housing_violation,
    title = "Any housing violation issued",
    description = "Any housing violation issued between 2014 and 2021 (True/False)"
  ) |>
  add_col_attrs(n_paint_violation,
                title = "Number of paint related violations",
                description = "Number of paint related violations issued between 2014 and 2021"
  ) |>
  add_col_attrs(any_paint_violation,
                title = "Any paint related violation issued",
                description = "Any paint related violation issued between 2014 and 2021 (True/False)"
  )

saveRDS(d_out, "data/parcel.rds")
