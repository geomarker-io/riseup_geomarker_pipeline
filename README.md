The purpose of the shell scripts is to build a pipeline for geocoding addresses and adding DeGAUSS images based on geocoded addresses.

Images used: geocoder, roads, aadt, greenspace, dep_index, drivetime.

### Usage

./scripts/getData.sh \<*input file name without extension*\> \<*output file name without extension*\>

e.g., 
./scripts/getData.sh *Admissions_for_Jan_2020_asthma_pul_and_gen_peds* *Admission2020*

### Note

- Input file should include the following address variables 
  - pat_addr_1
  - pat_city
  - pat_state
  - pat_zip
  
- Include the input file(s) in a folder called *raw-data*
- Output files are included in a folder called *data*


