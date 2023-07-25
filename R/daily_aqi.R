library(dplyr)
library(codec)

func_download <- function(url, dest) {
  download.file(url, destfile = dest, mode = "wb")
  
  unzip(dest, exdir = "tmp")
  unlink(dest)
}

year <- 2015:2022
dwnld_url <- glue::glue("https://aqs.epa.gov/aqsweb/airdata/daily_aqi_by_county_{year}.zip")
dest <- glue::glue("tmp/{year}.zip")

message("downloading AQI data...")
purrr::walk2(dwnld_url, dest, ~ func_download(.x, .y))

file <- glue::glue("tmp/daily_aqi_by_county_{year}.csv")

aqi <- purrr::map_dfr(file, ~ read_csv(.x)) |>
  filter(`State Name` == "Ohio" & `county Name` == "Hamilton") |>
  select(
    date = Date,
    aqi = AQI
  ) |>
  add_col_attrs(date,
                title = "Date",
                description = "Date"
  ) |>
  add_col_attrs(aqi,
                title = "AQI",
                description = "Air Quality Index"
  )

saveRDS(aqi, "data-raw/daily_aqi.rds")
fs::dir_delete("tmp")