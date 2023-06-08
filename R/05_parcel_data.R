library(parcel)
library(CODECtools)

d <- readRDS("data/geocodes.rds")

addresses <- unique(d$parsed_address)  # n = 67688

parcels <- get_parcel_data(addresses)

d <- d |>
  dplyr::left_join(parcels, by = c("parsed_address" = "input_address"))

# save
saveRDS(d, "data/parcel_data.rds")


