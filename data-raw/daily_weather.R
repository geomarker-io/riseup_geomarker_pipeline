library(dplyr, warn.conflicts = FALSE)
library(readr)

download_weather <- function(var, year) {
  download.file(glue::glue("https://aqs.epa.gov/aqsweb/airdata/daily_{var}_{year}.zip"),
    destfile = glue::glue("tmp/{var}_{year}.zip")
  )
  read_csv(glue::glue("tmp/{var}_{year}.zip")) |>
    filter(
      `State Code` == "39",
      `County Code` == "061",
      `Site Num` == "0040"
    ) |>
    select(
      date = `Date Local`,
      name = `Parameter Name`,
      value = `Arithmetic Mean`
    )
}

var <- c("WIND", "TEMP", "RH_DP")
year <- 2015:2022
plan <- tidyr::expand_grid(var, year)

message("downloading weather data...")
dir.create("tmp", showWarnings = FALSE)
weather <- purrr::map2_dfr(plan$var, plan$year, download_weather)

weather <- weather |>
  tidyr::pivot_wider(
    names_from = name,
    values_from = value
  ) |>
  rename(
    wind_speed = `Wind Speed - Resultant`,
    wind_direction = `Wind Direction - Resultant`,
    outdoor_temp = `Outdoor Temperature`,
    relative_humidity = `Relative Humidity`
  )

saveRDS(weather, "data-raw/daily_weather.rds")
fs::dir_delete("tmp")
