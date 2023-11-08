library(dplyr, warn.conflicts = FALSE)

d <-
  readRDS("data/cleaned_addresses.rds") |>
  tibble::as_tibble() |>
  select(PAT_ENC_CSN_ID, HOSP_ADMSN_TIME, PAT_MRN_ID)

d_daily <-
  fs::path("data-raw", c("daily_aqi", "daily_pollen_mold", "daily_weather"), ext = "rds") |>
  purrr::map(readRDS) |>
  purrr::reduce(left_join, by = join_by(date))

d <- left_join(d, d_daily, by = join_by(HOSP_ADMSN_TIME == date))

saveRDS(d, "data/daily.rds")
