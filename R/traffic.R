install_traffic <- function() {
  out_path <- fs::path(tools::R_user_dir("appc", "data"), "hpms_f123_aadt", ext = "rds")
  if (file.exists(out_path)) {
    return(out_path)
  }
  message("downloading HPMS data")
  dest_path <- tempfile(fileext = ".gdb.zip")
  httr::GET(
    "https://www.arcgis.com/sharing/rest/content/items/c199f2799b724ffbacf4cafe3ee03e55/data",
    httr::write_disk(dest_path, overwrite = TRUE),
    httr::progress()
  )
  hpms_states <-
    sf::st_layers(dsn = dest_path)$name |>
                                 strsplit("_", fixed = TRUE) |>
                                 purrr::map_chr(3)
  hpms_states <- hpms_states[!hpms_states %in% c("HI", "AK", "PR")]
  extract_F123_AADT <- function(state) {
    out <-
      sf::st_read(
        dsn = dest_path,
        query = glue::glue("SELECT F_SYSTEM, AADT, AADT_SINGLE_UNIT, AADT_COMBINATION",
                           "FROM HPMS_FULL_{state}_2020",
                           "WHERE F_SYSTEM IN ('1', '2', '3')",
                           .sep = " "
                           ),
        quiet = TRUE
      ) |>
      sf::st_zm() |>
      dplyr::mutate(s2_geography = s2::as_s2_geography(Shape)) |>
      sf::st_drop_geometry() |>
      tibble::as_tibble()
    out$length <- s2::s2_length(out$s2_geography)
    out$s2_centroid <- purrr::map_vec(out$s2_geography, \(x) s2::as_s2_cell(s2::s2_centroid(x)), .ptype = s2::s2_cell())
    out$s2_geography <- NULL
    out <- out |>
      na.omit() |>
      dplyr::transmute(s2 = s2_centroid,
                total_aadt_m = AADT * length,
                truck_aadt_m = (AADT_SINGLE_UNIT + AADT_COMBINATION) * length)
    return(out)
  }
  hpms_pa_aadt <- purrr::map(hpms_states, extract_F123_AADT, .progress = "extracting state F123 AADT files")
  out <- dplyr::bind_rows(hpms_pa_aadt)
  saveRDS(out, out_path)
  return(out_path)
}

#' get traffic summary data
#' @param x a vector of s2 cell identifers (`s2_cell` object)
#' @param buffer distance from s2 cell (in meters) to summarize data
#' @return a list the same length as `x`, which each element having a list of `total_aadt_m` and `truck_aadt_m` estimates 
#' @details A s2 level 15 approximation (~ 260 m sq) is used to simplify the intersection calculation with traffic summary data
get_traffic_summary <- function(x, buffer = 400) {
  aadt_data <-
    readRDS(install_traffic()) |>
    dplyr::group_by(s2_parent = s2::s2_cell_parent(s2, level = 15)) |>
    dplyr::summarize(total_aadt_m = sum(total_aadt_m),
                     truck_aadt_m = sum(truck_aadt_m))
  ## sqrt(median(s2::s2_cell_area(aadt_data$s2_parent)))
  # s2 level 16 are 130 m sq
  # s2 level 15 are 260 m sq
  # s2 level 14 are 521 m sq
  xx <- unique(x)
  message("intersecting with AADT data using level 15 s2 approximation ( ~ 260 m sq)")
  withins <- s2::s2_dwithin_matrix(s2::s2_cell_to_lnglat(xx), s2::s2_cell_to_lnglat(aadt_data$s2_parent), distance = buffer)
  summarize_traffic <- function(i) {
    aadt_data[withins[[i]], ] |>
    dplyr::summarize(total_aadt_m = sum(total_aadt_m),
                     truck_aadt_m = sum(truck_aadt_m)) |>
      as.list()
  }
  withins_aadt <- purrr::map(1:length(withins), summarize_traffic, .progress = "summarizing AADT")
  names(withins_aadt) <- xx
  return(withins_aadt[as.character(x)])
}


library(dplyr, warn.conflicts = FALSE)
library(fr, warn.conflicts = FALSE)
library(s2)

rd <- readRDS("data/geocodes.rds")

d <-
  tibble::as_tibble(rd) |>
  select(PAT_ENC_CSN_ID, ADMIT_DATE, MRN, lat, lon) |>
  na.omit() |>
  mutate(s2 = as_s2_cell(s2_geog_point(lon, lat))) |>
  select(-lat, -lon)

traf_sum_400 <- get_traffic_summary(d$s2, buffer = 400)
d$total_aadt_m_400 <- purrr::map_dbl(traf_sum_400, "total_aadt_m")
d$truck_aadt_m_400 <- purrr::map_dbl(traf_sum_400, "truck_aadt_m")

d |>
  select(-s2) |>
  as_fr_tdr(.template = rd) |>
  update_field("total_aadt_m_400", title = "Average Annual Daily Total Traffic-Meters") |>
  update_field("total_aadt_m_400", title = "Average Annual Daily Truck and Bus Traffic-Meters") |>
  saveRDS("data/traffic.rds")
