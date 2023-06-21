
library(tidyverse)
library(CODECtools)

d <- readRDS("data/geocodes.rds") 

d <- d |> 
  select(-raw_address, -hamilton_zip, -geocode_result) |> 
  arrange(PAT_MRN_ID, HOSP_ADMSN_TIME) 

# impute address start and end date by encounter
d <- d |>
  group_by(PAT_MRN_ID) |> 
  mutate(addr_start = HOSP_ADMSN_TIME - floor((HOSP_ADMSN_TIME - lag(HOSP_ADMSN_TIME)) / 2),    # address start time is mid point of this and last admission dates
         addr_end = HOSP_ADMSN_TIME + floor((lead(HOSP_ADMSN_TIME) - HOSP_ADMSN_TIME) / 2)) |>  # address end time is mid point of this and next admission dates
  mutate(addr_start_r1 = ifelse(is.na(addr_start),                                              # r1 add 30 days before start and after end dates
                                HOSP_ADMSN_TIME - duration(30, unit = "days"),
                                addr_start),
         addr_end_r1 = ifelse(is.na(addr_end), 
                              HOSP_ADMSN_TIME + duration(30, unit = "days"),
                              addr_end)) |> 
  mutate(addr_start_r1 = as_date(addr_start_r1),
         addr_end_r1 = as_date(addr_end_r1))

# Handle issue of same end and start dates
# r2: adjust end date so that it is not overlapping with the next start date
d <- d |> 
  group_by(PAT_MRN_ID) |> 
  mutate(addr_end_r2 = ifelse(addr_end_r1 == lead(addr_start_r1),   
                              addr_end_r1 - 1,
                              addr_end_r1),
         addr_end_r2 = ifelse(is.na(addr_end_r2),
                              addr_end_r1,
                              addr_end_r2),
         addr_end_r2 = as_date(addr_end_r2)) 

# add start and end date to each of the encounter addresses
d <- d |> 
  mutate(addr_start_date = addr_start_r1,
         addr_end_date = addr_end_r2) |> 
  select(-addr_start, -addr_start_r1, -addr_end, -addr_end_r1, -addr_end_r2)


# group by combination of patient and address
# handle the issue that family moved from one location to another and then moved back
n.addr <- d |> 
  group_by(PAT_MRN_ID, parsed_address) |> 
  summarize(n = n()) |> 
  group_by(PAT_MRN_ID) |> 
  summarize(n = n()) 

pat_id.addreq1 <- n.addr |> filter(n == 1) |> pull(PAT_MRN_ID)  # with one address; n = 63074
pat_id.addrgt1 <- n.addr |> filter(n > 1) |> pull(PAT_MRN_ID)  # with two or more addresses; n = 6768

# function to assign address index
address_history <- function(pat_id){
  
  address_index = 1
  d.sub <- filter(d, PAT_MRN_ID %in% pat_id)
  d.sub[1, "address_index"] <- address_index
  
  for(row in 2:nrow(d.sub)){ 
    
    address1 <- d.sub[row-1, "parsed_address"]
    address2 <- d.sub[row, "parsed_address"]
    
    if(address1 == address2){
      d.sub[row, "address_index"] = address_index
    } else{
      address_index = address_index + 1
      d.sub[row, "address_index"] = address_index
    }
  }
  return(d.sub)
}  

# address index for patients with two or more moves
d2 <- pat_id.addrgt1 |> 
  map(~address_history(.x)) |> 
  bind_rows()

# combine
d3 <- d |> 
  filter(PAT_MRN_ID %in% pat_id.addreq1) |> 
  mutate(address_index = 1) |> 
  bind_rows(d2)

d.grp <- d3 |> 
  group_by(PAT_MRN_ID, parsed_address, address_index) |> 
  summarise(addr_start_date = first(addr_start_date),
            addr_end_date = last(addr_end_date),
            lat = unique(lat),
            lon = unique(lon))|> 
  arrange(PAT_MRN_ID, addr_start_date) |> 
  ungroup()
# n = 78598

# add column attributes
d.grp <- d.grp |>
  add_col_attrs(parsed_address,
                title = 'Parsed Address',
                description = 'parsed address'
  ) |>
  add_col_attrs(lat,
                title = 'Latitude',
                description = 'geocoded latitude coordinate'
  ) |>
  add_col_attrs(lon,
                title = 'Longitude',
                description = 'geocoded longitude coordinate'
  ) |> 
  add_col_attrs(address_index,
                title = 'address index',
                description = 'track address change along the timeline'
  ) |> 
  add_col_attrs(addr_start_date,
                title = 'address start date',
                description = 'imputed start date of the current address'
  ) |> 
  add_col_attrs(addr_end_date,
                title = 'address end date',
                description = 'imputed end date of the current address'
  ) |>
  add_type_attrs()
  

saveRDS(d.grp, "data/longitudinal_residential_history.rds")


