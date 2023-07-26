library(dplyr)
library(codec)

message("downloading pollen and mold data...")
dir.create("tmp", showWarnings = FALSE)
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
  d <- tibble::as_tibble(d, .name_repair = "unique")
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

saveRDS(d_pollen_mold, "data-raw/daily_pollen_mold.rds")
fs::dir_delete("tmp")
