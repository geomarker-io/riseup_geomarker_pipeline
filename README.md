## RISEUP Pipeline

This group of R scripts is used to create a dataset by compiling geospatial data from multiple data sources at census tract level and parcel level.

```mermaid
%%{init: { "fontFamily": "arial" } }%%
graph TB

classDef id fill:#acd68e,stroke:#000,stroke-width:1px; %% green
classDef input fill:#c490ae,stroke:#000,stroke-width:1px; %% purple
classDef tool fill:#e8e8e8,stroke:#000,stroke-width:1px,stroke-dasharray: 5 2; %% grey
classDef data fill:#67ccde,stroke:#000,stroke-width:1px; %% blue

address(address):::input

address --- date(date related to address):::id
date ------> shared_exposure_series(weather, AQS,\npollen, mold,\nseasonality,\ninstructional days):::data

address --- ac(address\n cleaning, parsing,\n and normalization):::tool --- clean_address(cleaned and parsed address):::data

clean_address --- geocoding(geocoding):::tool --- geocode(geocoded coordinates):::id
clean_address --- am(exact address\nmatching):::tool --- parcel(parcel identifier):::id

parcel --- p_join(parcel id join):::tool --- parcel_data(tax auditor databases,\nhousing code violations,\nhistory of hospitalization):::data

geocode --- degauss(geomarker\nlibrary):::tool
degauss --- pd(point-level data resources, e.g.,\n greenspace, traffic,\n air pollution, hospital access):::data

geocode --- gi(spatial\nintersection):::tool --- ct(census tract identifier):::id
ct --- st_join(census tract id \n+ year join):::tool --- tract_data(tract-level data resources, e.g.,\nChild Opportunity Index,\n Material Deprivation Index):::data
```

### Data sources
  
- [DeGAUSS Geomarker Library](https://degauss.org/)
- [Census Tract-Level Neighborhood Indices](https://github.com/geomarker-io/tract_indices/#census-tract-level-neighborhood-indices)
- [American Community Survey (ACS) Data](https://www.census.gov/programs-surveys/acs/data.html)
- [Applied Geographic Solutions (AGS) Crime Risk](https://appliedgeographic.com/crimerisk/)
- [National Land Cover Database (NLCD)](https://www.usgs.gov/centers/eros/science/national-land-cover-database)
- [Cincinnati Area Geographic Information System (CAGIS) Parcel Data](https://data-cagisportal.opendata.arcgis.com/)

### Note
- Addresses used for geocoding were created based on variables, "pat_addr_1", "pat_city", "pat_state", "pat_zip", in the current dataset.

- 2019 5-Year ACS Data (2014-19) was used.

- AGS Crime Risk and CAGIS parcel data included in the dataset are available for Hamilton county only.

### Creating Month-Race-Tract Data

`scripts/aggregate_admissions_data.R` takes in the geocoded data and produces a summary of admissions by month, race (Black or African American vs. Other), and census tract.

