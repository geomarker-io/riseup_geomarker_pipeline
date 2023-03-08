library(dplyr)

# read in raw admission data
d <- readRDS("data/hospital_admission.rds")
d_daily <- readRDS("data/daily_data.rds")

d <- d |>
  left_join(d_daily, by = c("HOSP_ADMSN_TIME" = "date"))

saveRDS(d, "data/hospital_admission_time_data.rds")
