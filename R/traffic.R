library(dplyr, warn.conflicts = FALSE)
library(fr, warn.conflicts = FALSE)
library(s2)

rd <- readRDS("data/geocodes.rds")

d <-
  tibble::as_tibble(rd) |>
  select(PAT_ENC_CSN_ID, ADMIT_DATE, MRN, lat, lon) |>
  na.omit() |>
  mutate(s2 = as_s2_cell(s2_geog_point(lon, lat))) |>
  distinct(s2) |>
  mutate(s2_geography = as_s2_geography(s2_cell_to_lnglat(s2)))

# highway performance monitoring system data
# https://www.fhwa.dot.gov/policyinformation/hpms.cfm
# downloads to R_user_dir
## fs::dir_info(tools::R_user_dir("s3", "data"), recurse = TRUE)
get_traffic <- function() {
  hpms_file_path <- fs::path(tools::R_user_dir("s3", "data"), "hpms_2017.gpkg")
  if (file.exists(hpms_file_path)) {
    return(hpms_file_path)
  }
  message("downloading HPMS data")
  tf <- tempfile(fileext = ".zip")
  httr::GET(
    "https://www.fhwa.dot.gov/policyinformation/hpms/shapefiles/nationalarterial2017.zip",
    httr::write_disk(tf, overwrite = TRUE),
    httr::progress()
  )
  the_files <- unzip(tf, exdir = tempdir())
  message("converting HPMS data")
  system2(
    "ogr2ogr",
    c(
      "-f GPKG",
      "-skipfailures",
      "-makevalid",
      "-progress",
      "-select Route_ID,AADT,AADT_SINGL,AADT_COMBI",
      shQuote(hpms_file_path),
      grep(".shp$", the_files, value = TRUE),
      "-nlt MULTILINESTRING",
      "National_Arterial2017"
    )
  )
  return(hpms_file_path)
}

d_aadt <-
  get_traffic() |>
  sf::st_read() |>
  transmute(
    route_id = Route_ID,
    s2_geography = as_s2_geography(geom),
    aadt_total = AADT,
    aadt_truck = AADT_SINGL + AADT_COMBI
  ) |>
  tibble::as_tibble() |>
  select(-geom)

# subset source data to extent of input data
# TODO will this cutoff roads 400m outside of extent??
d_aadt <-
  d_aadt |>
  filter(s2_intersects_box(s2_geography,
    lng1 = min(s2_x(d$s2_geography)),
    lat1 = min(s2_y(d$s2_geography)),
    lng2 = max(s2_x(d$s2_geography)),
    lat2 = max(s2_y(d$s2_geography))
  ))

d <- d |> mutate(withins = s2_dwithin_matrix(s2_geography, d_aadt$s2_geography, distance = 400))

summarize_traffic <- function(x_withins) {
  d_aadt[x_withins, ] |>
    summarize(
      aadt_m_truck = sum(s2_length(s2_geography) * aadt_truck),
      aadt_m_nontruck = sum(s2_length(s2_geography) * (aadt_total - aadt_truck))
    )
}

d$aadt <- purrr::map(d$withins, summarize_traffic, .progress = "summarizing traffic")

d <- d |>
  select(s2, aadt) |>
  tidyr::unnest(cols = c(aadt))

out <-
  as_tibble(d)

out <-
  tibble::as_tibble(rd) |>
  select(PAT_ENC_CSN_ID, ADMIT_DATE, MRN, lat, lon) |>
  mutate(s2 = as_s2_cell(s2_geog_point(lon, lat))) |>
  select(-lat, -lon) |>
  left_join(d, by = "s2") |>
  select(-s2) |>
  as_fr_tdr(.template = rd)

out <- out |>
  update_field("aadt_m_truck", title = "Average Annual Daily Traffic-Meters (Trucks) within 400m") |>
  update_field("aadt_m_nontruck", title = "Average Annual Daily Traffic-Meters (Non-Trucks) within 400m")

saveRDS(out, "data/traffic.rds")
