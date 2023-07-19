reticulate::use_virtualenv("~/.virtualenvs/r-parcel/") # make sure to use this one if there is a problem with loading the learned settings file
library(parcel) # must be >= version 0.6.1 
library(dplyr)

d <- readRDS("data/cleaned_addresses.rds")
d_out <- d |> bind_cols(get_parcel_data(d$address))
saveRDS(d_out, "data/parcel.rds")
