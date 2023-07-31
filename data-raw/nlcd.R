## dir.create(tools::R_user_dir("s3", "data"), showWarnings = FALSE)


#' get path to NLCD impervious raster file (download and convert if necessary)
get_impervious <- function(yr = 2019) {
  nlcd_file_path <- fs::path(tools::R_user_dir("s3", "data"), glue::glue("nlcd_impervious_{yr}.tif"))
  if (file.exists(nlcd_file_path)) {
    return(nlcd_file_path)
  }
  message(glue::glue("downloading {yr} NLCD impervious raster"))
  nlcd_zip_path <- fs::path(tempdir(), glue::glue("nlcd_impervious_{yr}.zip"))
  glue::glue("https://s3-us-west-2.amazonaws.com/mrlc/nlcd_{yr}_impervious_l48_20210604.zip") |>
    httr::GET(httr::write_disk(nlcd_zip_path), httr::progress(), overwrite = TRUE)
  nlcd_raw_paths <- unzip(nlcd_zip_path, exdir = tempdir())
  message(glue::glue("converting {yr} NLCD impervious raster"))
  system2(
    "gdal_translate",
    c("-of COG",
      grep(".img", nlcd_raw_paths, fixed = TRUE, value = TRUE),
      shQuote(nlcd_file_path))
  )
  return(nlcd_file_path)
}

#' get path to NLCD treecanopy raster file (download and convert if necessary)
get_treecanopy <- function(yr = 2019) {
  nlcd_file_path <- fs::path(tools::R_user_dir("s3", "data"), glue::glue("nlcd_treecanopy_{yr}.tif"))
  if (file.exists(nlcd_file_path)) {
    return(nlcd_file_path)
  }
  message(glue::glue("downloading {yr} NLCD treecanopy raster"))
  nlcd_zip_path <- fs::path(tempdir(), glue::glue("nlcd_treecanopy_{yr}.zip"))
  glue::glue("https://s3-us-west-2.amazonaws.com/mrlc/nlcd_tcc_CONUS_{yr}_v2021-4.zip") |>
    httr::GET(httr::write_disk(nlcd_zip_path), httr::progress(), overwrite = TRUE)
  nlcd_raw_paths <- unzip(nlcd_zip_path, exdir = tempdir())
  message(glue::glue("converting {yr} NLCD treecanopy raster"))
  system2(
    "gdal_translate",
    c("-of COG",
      "-co BIGTIFF=YES",
      grep(".tif$", nlcd_raw_paths, value = TRUE),
      shQuote(nlcd_file_path))
  )
  return(nlcd_file_path)
}
