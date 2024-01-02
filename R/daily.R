library(dplyr, warn.conflicts = FALSE)

d <-
  readRDS("data/cleaned_addresses.rds") |>
  tibble::as_tibble() |>
  select(PAT_ENC_CSN_ID, ADMIT_DATE, MRN)

d_daily <-
  fs::path("data-raw", c("daily_aqi", "daily_pollen_mold", "daily_weather"), ext = "rds") |>
  purrr::map(readRDS) |>
  purrr::reduce(left_join, by = join_by(date))

out <- left_join(d, d_daily, by = join_by(ADMIT_DATE == date))

saveRDS(out, "data/daily.rds")
