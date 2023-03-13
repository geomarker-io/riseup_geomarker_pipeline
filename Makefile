all: data/hospital_admission_joined_nonparcel.rds data/hospital_admission_joined_data.rds
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

data/parcel_data.rds: data/addresses_geocoded.rds R/add_parcel_data.R
	Rscript R/add_parcel_data.R

data/daily_data.rds: R/get_time_data.R
	Rscript R/get_time_data.R

data/hospital_admission_joined_nonparcel.rds: data/hospital_admission.rds data/degauss_geomarker_library.rds data/nlcd.rds data/census_tract_lvl_data.rds R/join_nonparcel_data.R
	Rscript R/join_nonparcel_data.R

data/hospital_admission_joined_parcel.rds: data/hospital_admission.rds data/parcel_data.rds R/join_parcel_data.R
	Rscript R/join_parcel_data.R

data/hospital_admission_joined_temporal_data.rds: data/hospital_admission.rds data/daily_data.rds R/join_temporal_data.R
	Rscript R/join_temporal_data.R

data/hospital_admission_joined_parcel_nonparcel.rds: data/hospital_admission_joined_nonparcel.rds data/parcel_data.rds R/join_parcel_nonparcel.R
	Rscript R/join_parcel_nonparcel.R

data/hospital_admission_joined_parcel_nonparcel_temporal.rds: data/hospital_admission_joined_parcel_nonparcel.rds data/daily_data.rds R/join_parcel_nonparcel_temporal.R
	Rscript R/join_parcel_nonparcel_temporal.R