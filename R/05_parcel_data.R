reticulate::use_virtualenv("~/.virtualenvs/r-parcel/") # make sure to use this one if there is a problem with loading the learned settings file
library(parcel) # must be >= version 0.6.1 
library(dplyr)
library(codec)

d <- readRDS("data/cleaned_addresses.rds")
d_out <- d |> bind_cols(get_parcel_data(d$address))

# housing violation data
d.violation <- readxl::read_excel("dataset/Violations Likley Related to Lead, Asthma, and Mental Health from 2002 to date.xlsx")

# use violation data two years before the earliest admission date (1-1-2016)
d.violation <- 
  d.violation |> 
  filter(ISSUED >= as.Date("2014-01-01") & ISSUED <= as.Date("2021-12-31")) |>  
  mutate(parcel_id11 = substr(PARCEL_NO, 2, 12)) |>  # removing one extra zero
  group_by(parcel_id11) |> 
  summarize(n_housing_violation = n()) 

# merge with admission data
d_out <- 
  d_out |> 
  mutate(parcel_id11 = substr(parcel_id, 1, 11)) |>   # first 11 digit of parcel id
  left_join(d.violation, by = join_by(parcel_id11)) |> 
  mutate(any_housing_violation = (!is.na(n_violation))) |> 
  select(-parcel_id11)

d_out <- d_out |> 
  add_col_attrs(n_violation, 
                title = 'Number of housing violations', 
                description = 'Number of housing violations issued between 2014 and 2021'
  ) |>
  add_col_attrs(any_housing_violation, 
                title = 'Any housing violation issued', 
                description = 'Any housing violation issued between 2014 and 2021 (True/False)'
  )
 
saveRDS(d_out, "data/parcel.rds")
