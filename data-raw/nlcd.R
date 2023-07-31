# impervious
download_impervious <- function(yr = 2019) {
  nlcd_file_path <- fs::path(tools::R_user_dir("s3", "data"), glue::glue("nlcd_impervious_{yr}.tif"))
  if (file.exists(nlcd_file_path)) {
    return(nlcd_file_path)
  }
  withr::with_tempdir({
    download.file(glue::glue("https://s3-us-west-2.amazonaws.com/mrlc/nlcd_{yr}_impervious_l48_20210604.zip"),
      destfile = glue::glue("nlcd_impervious_{yr}.zip")
    )
    unzip(glue::glue("nlcd_impervious_{yr}.zip"))
    system2(
      "gdal_translate",
      c(
        "-of COG",
        glue::glue("nlcd_{yr}_impervious_l48_20210604.img"),
        shQuote(fs::path(download_dir, glue::glue("nlcd_impervious_{yr}.tif")))
      )
    )
  })
  return(nlcd_file_path)
}

# tree canopy
download_treecanopy <- function(yr = 2019) {
  nlcd_file_path <- fs::path(tools::R_user_dir("s3", "data"), glue::glue("nlcd_treecanopy_{yr}.tif"))
  if (file.exists(nlcd_file_path)) {
    return(nlcd_file_path)
  }
  withr::with_tempdir({
    download.file(glue::glue("https://s3-us-west-2.amazonaws.com/mrlc/nlcd_tcc_CONUS_{yr}_v2021-4.zip"),
      destfile = glue::glue("nlcd_treecanopy_{yr}.zip")
    )
    unzip(glue::glue("nlcd_treecanopy_{yr}.zip"))
    system2(
      "gdal_translate",
      c(
        "-of COG",
        "-co BIGTIFF=YES",
        glue::glue("nlcd_tcc_conus_{yr}_v2021-4.tif"),
        shQuote(fs::path(download_dir, glue::glue("nlcd_treecanopy_{yr}.tif")))
      )
    )
  })
  return(nlcd_file_path)
}
