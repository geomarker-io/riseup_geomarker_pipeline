## RISEUP Geomarker Pipeline

This group of R scripts is used to create a dataset by compiling geospatial data from multiple data sources at census tract level and parcel level.

```mermaid
%%{init: { "fontFamily": "arial" } }%%

graph LR

classDef id fill:#acd68e,stroke:#000,stroke-width:1px;
classDef input fill:#c490ae,stroke:#000,stroke-width:1px;
classDef tool fill:#e8e8e8,stroke:#000,stroke-width:1px,stroke-dasharray: 5 2;
classDef data fill:#67ccde,stroke:#000,stroke-width:1px;

address(address):::input

address ---> date(date related \nto address):::id
date --date join on all addresses \nin primary catchment area---> shared_exposure_series(weather, AQS,\npollen, mold,\nseasonality,\ninstructional days):::data

address --address \ncleaning, \nparsing, \nnormalization--> clean_address(address \ncomponents):::data

clean_address --street range \ngeocoding--> geocode(geocoded \ncoordinates):::id
clean_address --exact address\nmatching--> parcel(parcel \nidentifier):::id

geocode --geomarker \n assessment \n library---> pd(point-level \ndata resources, e.g.,\n greenspace, traffic,\n air pollution, \nhospital access):::data

geocode --spatial \nintersection--> ct(census tract \nidentifier):::id
ct --census tract id \n & year join --> tract_data(tract-level data resources, e.g.,\nChild Opportunity Index,\n Material Deprivation Index):::data

parcel --parcel id join \n on ---> parcel_data(tax auditor databases,\nhousing code violations,\nhouse hospitalization history):::data

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

