# RISEUP Geomarker Pipeline

This is a pipeline for appending place- and date- based geomarker data from multiple data sources at multiple geographic and temporal resolutions, with a specific focus on Hamilton County, Ohio:

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

## Data

See the [metadata](data/riseup_geomarker_pipeline/tabular-data-resource.yaml) for information about specific data elements and sources.

*Notes:*

- Patient addresses are constructed by pasting together `pat_addr_1`, `pat_city`, `pat_state`, `pat_zip` fields
- `hh_acs_measures` has annual measures, but measures from 2019 are used here

#### Time Data Availability Notes

| Data                                                                      | Min Date   | Max Date   | Frequency                                         | Data Availability Lag |
|--------------------------|------------|------------|-----------|-------------|
| AQI                                                                       | 2015-01-01 | 2022-10-01 | daily                                             | 6 months              |
| weather                 | 2015-01-01 | 2022-09-30 | daily                                             | 6 months              |
| pollen and mold | 2021-02-17 | 2022-12-09 | random (skips weekends, some random days missing) | unknown |
| shotspotter (only for Avondale, E. Price Hill, and W. Price Hill) | 2017-08-16 | 2023-01-03 | daily                                             | daily                 |

## Running & Developing

1. Clone github repository to destination; manually move input health data into place (`data/HospitalAdmissions.csv`)
2. Install all packages from DESCRIPTION file by running `pak::pak()` *or* `remotes::install_deps()` in the project root from R. (If you are on a linux machine, speed up installation to use binaries hosted by Posit, by setting `options("repos" = c("CRAN" = "https://packagemanager.rstudio.com/all/__linux__/jammy/latest"))`, substituting `focal` for your specific linux version.)
3. Install required python libraries. (Use `reticulate::py_config()` to check on available python environments):
```R
reticulate::py_install("usaddress", pip = TRUE)
reticulate::py_install("dedupe", pip = TRUE)
reticulate::py_install("dedupe-variable-address", pip = TRUE)
```
4. Use `make` to create targets defined in `Makefile` or `make tdr` to create the final output as a tabular data resource. *`docker` is required to run the `geocode` and `geomark` targets.*

*Notes:*

- `/data` is for any output data associated with a participant *and/or* the raw hospital admissions file; any `*.rds` or `*.csv` files in this directory will always be git ignored
- `/data-raw` is for raw (e.g., violations spreadsheet) or intermediate data products (e.g., daily AQI) that are tracked using git
- `Makefile` defines the pipeline, see other high level targets there
