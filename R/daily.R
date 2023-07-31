library(dplyr, warn.conflicts = FALSE)

d <- readRDS("data/cleaned_addresses.rds")

d_daily <-
  fs::path("data-raw", c("daily_aqi", "daily_pollen_mold", "daily_weather"), ext = "rds") |>
  purrr::map(readRDS) |>
  purrr::reduce(left_join, by = join_by(date))

d <- left_join(d, d_daily, by = join_by(HOSP_ADMSN_TIME == date))

saveRDS(d, "data/daily.rds")
