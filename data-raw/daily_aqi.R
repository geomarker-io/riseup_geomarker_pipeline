library(dplyr, warn.conflicts = FALSE)

get_daily_county_aqi <- function(year) {
  dest_file <- glue::glue("daily_county_aqi_{year}.zip")
  download.file(glue::glue("https://aqs.epa.gov/aqsweb/airdata/daily_aqi_by_county_{year}.zip"),
    destfile = dest_file,
    quiet = TRUE
  )
  d <-
    readr::read_csv(dest_file, show_col_types = FALSE) |>
    filter(`State Name` == "Ohio" & `county Name` == "Hamilton") |>
    transmute(
      date = as.Date(Date),
      aqi_hamilton = AQI
    )
  on.exit(unlink(dest_file))
  return(d)
}

out <- purrr::map_dfr(2015:2022, get_daily_county_aqi, .progress = "getting daily county aqi")

saveRDS(out, "data-raw/daily_aqi.rds")
