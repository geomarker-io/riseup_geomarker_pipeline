library(tidyverse)
library(CODECtools)

# AQI

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

# weather

download_weather <- function(var, year) {
  download.file(glue::glue("https://aqs.epa.gov/aqsweb/airdata/daily_{var}_{year}.zip"),
    destfile = glue::glue("tmp/{var}_{year}.zip")
  )
  unzip(glue::glue("tmp/{var}_{year}.zip"), exdir = "tmp")
  unlink(glue::glue("tmp/{var}_{year}.zip"))
  read_csv(glue::glue("tmp/daily_{var}_{year}.csv")) |>
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
plan <- expand_grid(var, year)

message("downloading weather data...")
weather <- purrr::map2_dfr(plan$var, plan$year, download_weather)

weather <- weather |>
  pivot_wider(
    names_from = name,
    values_from = value
  ) |>
  rename(
    wind_speed = `Wind Speed - Resultant`,
    wind_direction = `Wind Direction - Resultant`,
    outdoor_temp = `Outdoor Temperature`,
    relative_humidity = `Relative Humidity`
  ) |>
  add_col_attrs(date,
    title = "Date",
    description = "Date"
  ) |>
  add_col_attrs(wind_speed,
    title = "Wind Speed",
    description = "Wind Speed"
  ) |>
  add_col_attrs(wind_direction,
    title = "Wind Direction",
    description = "Wind Direction"
  ) |>
  add_col_attrs(outdoor_temp,
    title = "Outdoor Temperature",
    description = "Outdoor Temperature"
  ) |>
  add_col_attrs(relative_humidity,
    title = "Relative Humidity",
    description = "Relative Humidity"
  )

# pollen / mold

message("downloading pollen and mold data...")
download.file("https://southwestohioair.org/DocumentCenter/View/447",
  destfile = "tmp/pollen_mold_2021.xlsx"
)

download.file("https://www.southwestohioair.org/DocumentCenter/View/564/2022-Raw-Daily-Counts",
  destfile = "tmp/pollen_mold_2022.xlsx"
)

clean_pollen_mold <- function(path) {
  d <- readxl::read_excel(path,
    sheet = 1,
    col_names = FALSE
  )
  d <- t(d)
  d <- as_tibble(d, .name_repair = "unique")
  d[1, 1] <- "date"
  colnames(d) <- d[1, ]
  d <- d[-1, ]
  return(d)
}

d_2021 <- clean_pollen_mold("tmp/pollen_mold_2021.xlsx")
d_2022 <- clean_pollen_mold("tmp/pollen_mold_2022.xlsx")

d_pollen_calculations <- select(d_2021, 1, 56:83) |>
  bind_rows(select(d_2022, 1, 56:83)) |>
  mutate(
    date = as.numeric(date),
    date = as.character(as.Date(date, origin = "1899-12-30")),
    across(.cols = 2:29, .fns = as.numeric)
  ) |>
  select(date, pollen_total = Total) |>
  filter(!is.na(date))


d_mold_calculations <- select(d_2021, 1, 85:108) |>
  bind_rows(select(d_2022, 1, 85:108)) |>
  mutate(
    date = as.numeric(date),
    date = as.character(as.Date(date, origin = "1899-12-30")),
    across(.cols = 2:25, .fns = as.numeric)
  ) |>
  select(date, outdoor_mold_total = Total) |>
  filter(!is.na(date))

d_pollen_mold <- left_join(d_pollen_calculations,
  d_mold_calculations,
  by = "date"
) |>
  mutate(date = as.Date(date)) |>
  add_col_attrs(date,
    title = "Date",
    description = "Date"
  ) |>
  add_col_attrs(pollen_total,
    title = "Pollen Score",
    description = "Pollen count (grains/cubic meter) * pollen factor"
  ) |>
  add_col_attrs(outdoor_mold_total,
    title = "Outdoor Mold Score",
    description = "Outdoor mold count (spores/cubic meter) * mold factor"
  )


# shotspotter
library(sf)

message("downloading shotspotter data...")
download.file("https://github.com/geomarker-io/shotspotter/raw/main/shotspotter_street_ranges.rds",
  destfile = "tmp/shotspotter_street_ranges.rds"
)

d <- readRDS("tmp/shotspotter_street_ranges.rds")

d <- d |>
  filter(!is.na(street_ranges)) |>
  rowwise() |>
  mutate(geometry = st_sfc(st_union(street_ranges))) |>
  st_as_sf() |>
  select(-street_ranges)

neigh <-
  cincy::neigh_cchmc_2020 |>
  filter(neighborhood_2020 %in% c("Avondale", "E. Price Hill", "W. Price Hill"))

d <-
  d |>
  st_transform(st_crs(neigh)) |>
  st_join(neigh, largest = TRUE)

d_daily_shots <-
  d |>
  st_drop_geometry() |>
  filter(!is.na(neighborhood_2020)) |>
  mutate(date = lubridate::date(date_time)) |>
  group_by(neighborhood_2020, date) |>
  summarize(n = n())

all_days <- tibble::tibble(
  date = rep(seq.Date(from = min(d_daily_shots$date), to = max(d_daily_shots$date), by = "day"), 3),
  neighborhood_2020 = c(rep("Avondale", 1967), rep("E. Price Hill", 1967), rep("W. Price Hill", 1967))
)

d_daily_shots <- left_join(all_days, d_daily_shots, by = c("neighborhood_2020", "date")) |>
  mutate(n = ifelse(is.na(n), 0, n)) |>
  pivot_wider(
    names_from = neighborhood_2020,
    values_from = n
  ) |>
  rename(
    n_shots_avondale = Avondale,
    n_shots_e_price_hill = `E. Price Hill`,
    n_shots_w_price_hill = `W. Price Hill`
  ) |>
  mutate(n_shots_total = n_shots_avondale + n_shots_e_price_hill + n_shots_w_price_hill) |>
  add_col_attrs(date,
    title = "Date",
    description = "Date"
  ) |>
  add_col_attrs(n_shots_avondale,
    title = "Number of Shots - Avondale",
    description = "Number of shots recorded in Avondale"
  ) |>
  add_col_attrs(n_shots_e_price_hill,
    title = "Number of Shots - E. Price Hill",
    description = "Number of shots recorded in East Price Hill"
  ) |>
  add_col_attrs(n_shots_w_price_hill,
    title = "Number of Shots - W. Price Hill",
    description = "Number of shots recorded in West Price Hill"
  ) |>
  add_col_attrs(n_shots_total,
    title = "Number of Shots - Avondale, E. Price Hill, and W. Price Hill",
    description = "Number of shots recorded in Avondale, E. Price Hill, and W. Price Hill"
  )

daily <-
  full_join(aqi, weather, by = "date") |>
  full_join(d_pollen_mold, by = "date") |>
  full_join(d_daily_shots, by = "date")

daily <- add_type_attrs(daily)
saveRDS(daily, "data/daily_data.rds")

fs::dir_delete("tmp")
