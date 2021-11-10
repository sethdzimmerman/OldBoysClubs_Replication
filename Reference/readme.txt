Census File Structure
	This details the specific Census files required to run the code with $ACCESS == 1.

Paper Output Locations
	This details where in the project each table and figure from the paper is produced.

Codebook
	This details each variable, label, number of nonmissing observations,
	min, and max of each of the following cleaned data sets:
		redbooks_clean
			Cleaned version of all relevant main variables from the 
			Red Books in the years 1919-1935.
		lr_redbooks_clean
			Cleaned version of all relevant variables from the 
			Red Books in the years 1919-2015, with focus on long-run outcomes.
		lr_series_redbooks_update (requires CENSUS access to generate fully)
			Updated version of lr_redbooks_clean that incorporates various
			census outcomes. Used in analyzing cross-sectional trends.
		census_rb_merged (requires CENSUS access to generate fully)
			Merged redbooks_clean with the relevent Census variables used
			in analysis.
		better_processed_redbooks_res_sample (requires CENSUS access to generate fully)
			Takes census_rb_merged and includes only the students that lived
			on Yale's campus.

		