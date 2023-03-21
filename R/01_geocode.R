# geocoder
d <- d |> 
  degauss_run("geocoder", "3.3.0", quiet = FALSE) |>  # duplicated records
  distinct(.keep_all = TRUE)   # keep distinct rows

# 2010 Census Tract Geographies
d <- d |> 
  degauss_run("census_block_group", "0.6.0", argument = "2010", quiet = FALSE)

# 2020 Census Tract Geographies
d <- d |> 
  degauss_run("census_block_group", "0.6.0", argument = "2020", quiet = FALSE)
