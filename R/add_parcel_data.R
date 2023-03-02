
.cran_packages <- c("parcel")
.inst <- .cran_packages %in% installed.packages()
if(any(!.inst)) {
  install.packages(.cran_packages[!.inst], repos = "http://cran.us.r-project.org")
}

library(parcel)
library(CODECtools)

d <- readRDS("data/addresses_geocoded.rds")

d <- d |>
  add_parcel_id() |>
  tidyr::unnest(cols = c(parcel_id)) |>  
  dplyr::left_join(cagis_parcels, by = "parcel_id") 

# cleaning
d <- d |> 
  select(PAT_ENC_CSN_ID, parcel_id, property_addr_number, property_addr_street, property_addr_suffix, market_total_value, land_use, acreage, homestead, RED_25_FLAG, annual_taxes, unpaid_taxes, parcel_centroid_lon, parcel_centroid_lat)

d <- d |> 
  add_col_attrs(parcel_id, 
                title = 'parcel id', 
                description = 'parcel ID'
                ) |>
  add_col_attrs(property_addr_number, 
                title = 'property addr number', 
                description = 'property address number'
                ) |>
  add_col_attrs(property_addr_street, 
                title = 'property addr street', 
                description = 'property address street'
                ) |>
  add_col_attrs(property_addr_suffix, 
                title = 'property addr suffix', 
                description = 'property address suffix'
                ) |>
  add_col_attrs(market_total_value, 
                title = 'market total value', 
                description = 'market total value'
                ) |>
  add_col_attrs(land_use, 
                title = 'land use', 
                description = 'land use'
                ) |>
  add_col_attrs(acreage, 
                title = 'acreage', 
                description = 'acreage'
                ) |>
  add_col_attrs(homestead, 
                title = 'homestead', 
                description = 'homestead'
                ) |>
  add_col_attrs(RED_25_FLAG, 
                title = 'RED 25 FLAG', 
                description = 'RED 25 FLAG'
                ) |>
  add_col_attrs(annual_taxes, 
                title = 'annual taxes', 
                description = 'total tax'
                ) |>
  add_col_attrs(unpaid_taxes, 
                title = 'unpaid taxes', 
                description = 'unpaid taxes'
                ) |>
  add_col_attrs(parcel_centroid_lon, 
                title = 'parcel centroid lon', 
                description = 'parcel centroid longitude'
                ) |>
  add_col_attrs(parcel_centroid_lat, 
                title = 'parcel centroid lat', 
                description = 'parcel centroid latatitude')

# save
saveRDS(d, "data/parcel_data.rds")


