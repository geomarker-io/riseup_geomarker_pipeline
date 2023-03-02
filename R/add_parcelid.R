

library(parcel)

d <- readRDS("data/hospital_admission_joined_data.rds")
dim(d.in) # 124,244

d <- d |>
  parcel::add_parcel_id() |>
  tidyr::unnest(cols = c(parcel_id)) |>   # 140,778
  dplyr::left_join(parcel::cagis_parcels, by = "parcel_id")  # 140,778
dim(d)

# save
saveRDS(d, "data/hospital_admission_joined_data_wParcel.rds")


