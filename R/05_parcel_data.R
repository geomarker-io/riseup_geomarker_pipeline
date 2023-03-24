library(parcel)
library(CODECtools)

d <- readRDS("data/geocodes.rds")

d <- d |>
  rename(address = parsed_address) |>
  add_parcel_id() |>
  tidyr::unnest(cols = c(parcel_id))

fs::dir_create("data-raw/hamilton_parcels")
write_csv(cagis_parcels, "data-raw/hamilton_parcels/hamilton_parcels.csv")

download.file("https://raw.githubusercontent.com/geomarker-io/parcel/main/data-raw/tabular-data-resource.yaml",
              destfile = "data-raw/hamilton_parcels/tabular-data-resource.yaml")

cagis_parcels <- read_tdr_csv("data-raw/hamilton_parcels")

d <- d |>
  dplyr::left_join(cagis_parcels, by = "parcel_id")

# save
saveRDS(d, "data/parcel_data.rds")


