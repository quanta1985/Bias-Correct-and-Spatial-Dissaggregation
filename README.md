# Bias Correct and Spatial Disaggregation (BCSD)
This is the Bias-Correct and Spatial Disaggregation (BCSD) program for downscaling daily near surface temperature (tas), maximum daily temeprature (tasmax), and mininum daily temperature (tasmin) and precipitation data. The orginial method by Wood et al (2004) can be found here: https://doi.org/10.1023/B:CLIM.0000013685.99609.9e

Usage note and guidelines:

1. The BCSD downscaling program for temperature and precipitation are different. Precipitation downscaling is separate with temperature downscaling and can be executed individually. Temperature downscaling program requires both tas, tasmax, and tasmin to make sure the diurnal squence of temperature data is maintained.
2. Each program contains 6 files including:
  - runBCSD.sh is the main program that control all sub-program
  - BC.R performs bias correction of data using quantile mapping method
  - SD.sh perform spatial disaggregation
  - split_merge.sh is a sub-program to process the ouput of BC.R
  - final. sh is a sub-program to process the final out of BCSD downscaling
  - grid_1.0.dat is a information file that guide the resolution of intermediate resolution level of 1.0 degree. This file should be modified or changed  to meet users need.
3. The default program is prepared using 1980-2014 as training data and downscale target is 2015-2099, using ACCESS-CM2 model
4. Output of the program is stored in the out folder
5. Using the program
  - In runBCSD.sh 
    + Change the period of training and testing dataset
    + Change the location and name of the required input
    + Since the output file will be done on monthly data, normally the number of output file is large. The mergetime command of CDO is used multiple times on 10 years periods to reduce the stress on system memory and also to meet the limitation of CDO. So users should change the mergetime command according to the downscaling period they select
    + The input files must contain only one variable
    + Standard variable name for the programe are pr, tas, tasmax, tasmin. User should modify the programe if the input variable name is different.
