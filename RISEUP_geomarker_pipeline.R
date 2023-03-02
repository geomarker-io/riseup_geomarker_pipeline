#===============
# updates
#===============
# 1-17-2023
# using 2019 acs data from hh_acs and dep index instead of matching admission year, so that dep index is consistent at tract level.
# manually download and add nlcd data
#
# 1-31-2023
# limit admission time to between 1/1/2016 and 12/31/2022 
#
# 2-8-2023
# using parcel package for parcel data


library(tidyverse)
library(lubridate)
library(dht)
library(data.table)
library(CODECtools)
library(parcel)
#devtools::install_github("geomarker-io/CODECtools")
#remotes::install_github("geomarker-io/s3")
#remotes::install_github("degauss-org/dht")
#renv::install("geomarker-io/parcel")

#input = "Admissions_for_Jan_2022_asthma_pul_and_gen_peds.csv"
input = "Hospital Admissions.csv"

#source("add_parcel_id.R")

#---------------------------------------------------------
# organize addresses
#---------------------------------------------------------

data.in <- readr::read_csv(paste0("raw-data/", input), na = c("NA", "-", "NULL")) |>  # n = 135871 records 
  mutate(pat_zip_clean = str_split(PAT_ZIP, "-", simplify=TRUE)[,1]) |>  
  unite("address", c(PAT_ADDR_1, PAT_CITY, PAT_STATE, pat_zip_clean), remove = FALSE, sep=" ") 
dim(data.in)

# data cleaning
# remove a duplicated record (based on PAT_ENC_CSN_ID) from current dataset
d <- data.in |> 
  filter(!(PAT_ENC_CSN_ID == "549864470" & MAPPED_RACE == "Unknown")) # 135870
dim(d)
# limit data to patients admitted between 1/1/2016 and 12/31/2021
summary(data.in$HOSP_ADMSN_TIME)

d <- d |> 
  filter(HOSP_ADMSN_TIME <= ymd(20211231)) # 124244
dim(d)

summary(d$HOSP_ADMSN_TIME)

# cache the following functions locally to disk
fc <- memoise::cache_filesystem(fs::path(fs::path_wd(), "localcache"))
add_parcel_id <- memoise::memoise(add_parcel_id, omit_args = c("quiet"), cache = fc)
degauss_run <- memoise::memoise(degauss_run, omit_args = c("quiet"), cache = fc)

#---------------------------------------------------------
# geocoding
#---------------------------------------------------------
start_time <- Sys.time()

# postal
d <- d |> 
  degauss_run("postal", "0.1.4", quiet = FALSE) 
dim(d)

# geocoder
d <- d |> 
  degauss_run("geocoder", "3.3.0", quiet = FALSE) |>  # duplicated records
  distinct(.keep_all = TRUE)   # keep distinct rows
dim(d)

# 2010 Census Tract Geographies
d <- d |> 
  degauss_run("census_block_group", "0.6.0", argument = "2010", quiet = FALSE)
dim(d)

# 2020 Census Tract Geographies
d <- d |> 
  degauss_run("census_block_group", "0.6.0", argument = "2020", quiet = FALSE)
dim(d)

# dep-index: merging from tract indices
# d <- d |> 
#  degauss_run("dep_index", "0.2.1", quiet = FALSE) 

# roads
d <- d |> 
  degauss_run("roads", "0.2.1", quiet = FALSE)
dim(d)

# aadt
d <- d |> 
  degauss_run("aadt", "0.2.0", quiet = FALSE) |> 
  select(-.row)
dim(d)

# greenspace
d <- d |> 
  degauss_run("greenspace", "0.3.0", quiet = FALSE)
dim(d)

# drivetime
d <- d |> 
  degauss_run("drivetime", "1.2.0", argument = "cchmc", quiet = FALSE)
dim(d)

end_time <- Sys.time()

end_time - start_time

#-----------
# nlcd
#-----------

# make buffers around points
d.point <- d |> 
  select(PAT_ENC_CSN_ID , lat, lon) %>% 
  filter(complete.cases(.)) |>  # keep geocoded ones
  distinct(.keep_all = TRUE)  # remove duplicated records while adding parcel ID

d.point <-
  d.point %>%
  dplyr::select(PAT_ENC_CSN_ID, lat, lon) %>%
  stats::na.omit() %>%
  tidyr::nest(PAT_ENC_CSN_ID = c(PAT_ENC_CSN_ID)) %>%
  sf::st_as_sf(coords = c("lon", "lat"), crs = 4326)

# project to 5072 for buffering in meters
d.buffered <- d.point %>%
  sf::st_transform(5072) %>%
  sf::st_buffer(dist = 400)

d.buffered <- terra::vect(d.buffered)

# nlcd_legend
nlcd_legend <-
  tibble::tribble(
    ~value, ~landcover_class, ~landcover, ~green,
    11, "water", "water", FALSE,
    12, "water", "ice/snow", FALSE,
    21, "developed", "developed open", TRUE,
    22, "developed", "developed low intensity", TRUE,
    23, "developed", "developed medium intensity", FALSE,
    24, "developed", "developed high intensity", FALSE,
    31, "barren", "rock/sand/clay", FALSE,
    41, "forest", "deciduous forest", TRUE,
    42, "forest", "evergreen forest", TRUE,
    43, "forest", "mixed forest", TRUE,
    51, "shrubland", "dwarf scrub", TRUE,
    52, "shrubland", "shrub/scrub", TRUE,
    71, "herbaceous", "grassland", TRUE,
    72, "herbaceous", "sedge", TRUE,
    73, "herbaceous", "lichens", TRUE,
    74, "herbaceous", "moss", TRUE,
    81, "cultivated", "pasture/hay", TRUE,
    82, "cultivated", "cultivated crops", TRUE,
    90, "wetlands", "woody wetlands", TRUE,
    95, "wetlands", "emergent herbaceous wetlands", TRUE
  )

# extract info
# nlcd
if (file.exists("rasters/nlcd_hv_2019.tif")){
  
  nlcd_hv_2019 <- terra::rast("rasters/nlcd_hv_2019.tif")
  
} else {
  
  hv <- cincy::county_hlthv_2010 |> 
    st_union()

  nlcd_tif <- s3::s3_get("s3://geomarker/nlcd_cog/nlcd_landcover_2019.tif")
  nlcd <- terra::rast(nlcd_tif)
  nlcd_hv_2019 <- terra::crop(nlcd, hv)
  terra::writeRaster(nlcd_hv_2019, "rasters/nlcd_hv_2019.tif")
  fs::dir_delete("s3_downloads")
}
  
pct_green <- 
  terra::extract(nlcd_hv_2019, d.buffered) |>
  rename(value = Layer_1) |>
  left_join(nlcd_legend, by = "value") |>
  group_by(ID) |>
  summarize(pct_green_2019 = round(sum(green) / n() * 100)) |>
  select(-ID)

d.pct_green <- bind_cols(d.point, pct_green) |> 
  unnest(PAT_ENC_CSN_ID) |> 
  st_drop_geometry()

# impervious
if (file.exists("rasters/impervious_hv_2019.tif")){
  
  impervious_hv_2019 <- terra::rast("rasters/impervious_hv_2019.tif")
  
} else {
  
  hv <- cincy::county_hlthv_2010 |> 
    st_union()
  
  impervious_tif <- s3::s3_get("s3://geomarker/nlcd_cog/nlcd_impervious_2019.tif")
  impervious <- terra::rast(impervious_tif)
  impervious_hv_2019 <- terra::crop(impervious, hv)
  terra::writeRaster(impervious_hv_2019, "rasters/impervious_hv_2019.tif")
  fs::dir_delete("s3_downloads")
}

pct_impervious <- 
  terra::extract(impervious_hv_2019, 
                 d.buffered, 
                 fun = "mean") |>
  rename(value = Layer_1) |>
  summarize(pct_impervious_2019 = round(value))

d.pct_impervious <- bind_cols(d.point, pct_impervious) |> 
  unnest(PAT_ENC_CSN_ID) |> 
  st_drop_geometry()

# tree canopy
if (file.exists("rasters/treecanopy_hv_2016.tif")){
  
  treecanopy_hv_2016 <- terra::rast("rasters/treecanopy_hv_2016.tif")
  
} else {
  
  hv <- cincy::county_hlthv_2010 |> 
    st_union()
  
  tree_tif <- s3::s3_get("s3://geomarker/nlcd_cog/nlcd_treecanopy_2016.tif")
  treecanopy <- terra::rast(tree_tif)
  treecanopy_hv_2016 <- terra::crop(treecanopy, hv)
  terra::writeRaster(treecanopy_hv_2016, "rasters/treecanopy_hv_2016.tif")
  fs::dir_delete("s3_downloads")
}

pct_treecanopy <- 
  terra::extract(treecanopy_hv_2016, 
                 d.buffered, 
                 fun = "mean") |>
  rename(value = Layer_1) |>
  summarize(pct_treecanopy_2016 = round(value))

d.pct_treecanopy <- bind_cols(d.point, pct_treecanopy) |> 
  unnest(PAT_ENC_CSN_ID) |> 
  st_drop_geometry()

# merge
d.nlcd <- d.pct_green |> 
  left_join(d.pct_impervious, by = "PAT_ENC_CSN_ID") |> 
  left_join(d.pct_treecanopy, by = "PAT_ENC_CSN_ID")

d <- left_join(d, d.nlcd, by = "PAT_ENC_CSN_ID")
dim(d)

# save 
saveRDS(d, file = sprintf("data/HospitalAdmissions_degauss_%s.rds", Sys.Date()))
write_csv(d, file = sprintf("data/HospitalAdmissions_degauss_%s.csv", Sys.Date()))



#---------------------------------------------------------
# tract_indices (2010 census tract id)
#---------------------------------------------------------
tract_indices <- readr::read_csv("https://github.com/geomarker-io/tract_indices/releases/download/v0.3.0/tract_indices.csv")

d <- d |> 
  left_join(tract_indices, by=c("census_tract_id_2010" = "census_tract_id")) |> 
  rename(dep_index_2018 = dep_index)
dim(d)

#---------------------------------------------------------
# historical acs data (2010 or 2020 census tract id)
#---------------------------------------------------------
hh_acs_2019 <- readr::read_csv("https://codec-data.s3.amazonaws.com/hh_acs_measures/hh_acs_measures.csv") |> 
  filter(year == 2019) |> 
  select(-year, -census_tract_vintage) |> 
  rename_all(paste0, "_2019") |> 
  rename(census_tract_id = census_tract_id_2019)

d <- d |> 
  left_join(hh_acs_2019, by=c("census_tract_id_2010"="census_tract_id")) 
dim(d)

#-------------------------------------------------------------
# 2019 dep index
# Note the 2019 dep index was calculated using 2012-2020 data
#-------------------------------------------------------------
di <- readRDS("U:/Investigator Folders/DBE/Cole Brokamp/GRAPPH/harmonized_historical_ACS_data/harmonized_historical_ACS_data/data/dep_index_2012-2020.rds") |> 
  filter(year == 2019) |> 
  select(dep_index_2019 = dep_index,
         census_tract_id_2010)

d <- d |> 
  left_join(di, by = "census_tract_id_2010")
dim(d)

#---------------------------------------------------------
# AGS crime risk
# Hamilton county tracts only
# 2010 census tract vintage
#---------------------------------------------------------
ags_crime <- read_csv("raw-data/AGS_crime_risk/ags_crime_risk.csv") |> 
  rename_all(~ paste0("ags_", .x)) |> 
  rename(census_tract_id = ags_census_tract_id) |> 
  mutate(census_tract_id = as.character(census_tract_id))

d <- d |> 
  left_join(ags_crime, by=c("census_tract_id_2010"="census_tract_id"))
dim(d)

# save
saveRDS(d, file = sprintf("data/HospitalAdmissions_degauss_ti_acs_ags_%s.rds", Sys.Date()))
write_csv(d, file = sprintf("data/HospitalAdmissions_degauss_ti_acs_ags_%s.csv", Sys.Date()))


#--------------------------------------------------------
# Add parcel ID
# will cause duplicated records with unique parcel IDs
#--------------------------------------------------------
renv::install("geomarker-io/parcel")
library(parcel)

d.in <- readRDS("data/HospitalAdmissions_degauss_ti_acs_ags_2023-01-31.rds")
dim(d.in) # 124,244

d <- d.in |>
  parcel::add_parcel_id(quiet = FALSE) |>
  tidyr::unnest(cols = c(parcel_id)) |>   # 140,778
  dplyr::left_join( parcel::cagis_parcels, by = "parcel_id")  # 140,778
dim(d)

# save
saveRDS(d, file = sprintf("data/HospitalAdmissions_degauss_ti_acs_ags_parcel_%s.rds", Sys.Date()))




