all: hospital_admission_joined_data.rds hospital_admission_joined_data_wParcel.rds csv
	echo "you did it!"

data/hospital_admission.rds: R/clean_admission_data.R
	Rscript R/clean_admission_data.R

data/addresses.rds: data/hospital_admission.rds R/make_addresses.R
	Rscript R/make_addresses.R

data/addresses_geocoded.rds: data/addresses.rds R/geocode_addresses.R
	Rscript R/geocode_addresses.R

data/degauss_geomarker_library.rds: data/addresses_geocoded.rds R/add_DeGAUSS_geomarker_library.R
	Rscript R/add_DeGAUSS_geomarker_library.R

data/nlcd.rds: data/addresses_geocoded.rds R/add_nlcd.R
	Rscript R/add_nlcd.R

data/census_tract_identifier.rds: data/addresses_geocoded.rds R/add_census_tract_identifier.R
	Rscript R/add_census_tract_identifier.R

data/census_tract_lvl_data.rds: data/census_tract_identifier.rds R/add_census_tract_lvl_data.R
	Rscript R/add_census_tract_lvl_data.R

data/hospital_admission_joined_data.rds: data/hospital_admission.rds data/degauss_geomarker_library.rds data/nlcd.rds data/census_tract_lvl_data.rds R/join_saved_data.R
	Rscript R/join_saved_data.R

data/hospital_admission_joined_data_wParcel.rds: data/hospital_admission_joined_data.rds R/add_parcelid.R
	Rscript R/add_parcelid.R

csv: hospital_admission_joined_data.rds hospital_admission_joined_data_wParcel.rds
	R -e "write.csv(readRDS('data/hospital_admission_joined_data.rds'), 'data/hospital_admission_joined_data.csv', row.names = F)"
	R -e "write.csv(readRDS('data/hospital_admission_joined_data_wParcel.rds'), 'data/hospital_admission_joined_data_wParcel.csv', row.names = F)"
