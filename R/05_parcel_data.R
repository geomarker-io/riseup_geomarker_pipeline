library(parcel)
library(dplyr)

d <- readRDS("data/geocodes.rds")

parcel_links <-
  d$parsed_address |>
  unique() |>
  link_parcel() |>
  filter(
    !is.na(parcel_id),
    land_use != "residential vacant land"
  )
  left_join(codec::read_tdr_csv(fs::path_package("parcel", "cagis_parcels")),
            join_by(parcel_id)) |>
  nest_by(input_address, .key = "parcel_data")

d_parcel <-
  left_join(d,
            parcel_links,
            by = join_by(parsed_address == input_address),
            relationship = "many-to-many")

# TODO filter to one parcel per address
# for now, randomly sample one if more than one
# future code should consider logic for selecting *which* is best one to choose
d_out <-
  tidyr::unnest(d_parcel, parcel_data, keep_empty = TRUE) |>
  slice_sample(n = 1, by = PAT_ENC_CSN_ID)

# save
saveRDS(d_out, "data/parcel.rds")
