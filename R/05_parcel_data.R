library(parcel)
library(dplyr)

d <- readRDS("data/geocodes.rds") # n = 124,173

d_parcel <- get_parcel_data(d$parsed_address) 

d_parcel_unique <- d_parcel |>
  filter(!is.na(parcel_id), # remove unmatched addresses n = 56,755
         land_use != "residential vacant land") |> # remove residential vacant land n = 54,978
  group_by(input_address) |>
  slice(1) # filter to one parcel id per address n = 22,084

d <- dplyr::left_join(d, d_parcel_unique, by = c("parsed_address" = "input_address"))

# save
saveRDS(d, "data/parcel_data.rds")


