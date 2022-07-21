echo "########################################### SETUP ########################################"
echo "# 1. TRAIN 35 ys (1980-2014) - TEST 85yrs (2015-2099)                                    #"
echo "# 2. Get monthly mean of VnGP                                                            #" 
echo "# 3. Regrid GCM and VnGP to same resolution                                              #" 
echo "# 4. obsvervation (obs), historical (his), future simulation (fu)                        #" 
echo "##########################################################################################"
model=ACCESS-CM2
begintrain=1980
endtrain=2014
begintest=2015
endtest=2099
dir=HIS   #Directory of current process

### DAILY obs data (1961-2018): Link RAW data
ln -s /work/users/quanta/QUAN/DATA/VnGC/VnGP_0.1_1980_2018.dd_rev.nc obs.nc

### MONTHLY model historical data (1980-2014): Link RAW data
ln -s /work/users/quanta/QUAN/DATA/CMIP6/NEW/${model}/${model}_pr_his_mm_1980-2014.nc mod.his.nc

### MONTHLY model future data (1980-2014): Link RAW data
ln -s /work/users/quanta/QUAN/DATA/CMIP6/NEW/${model}/${model}_pr_ssp585_mm_2015-2100.nc mod.fu.nc

### SUBTRACT obs daily data (1980-2014) for training
cdo -selyear,${begintrain}/${endtrain} obs.nc obs.train.nc

### OBS TRAIN DATA (1980-2014): get monthy average; regrid to 1.0; change all variable names to pr (easier use later)
cdo -O -remapcon,grid_1.0.dat -monmean -chname,rain,pr obs.train.nc obs_mm_r10.nc

### MODEL TRAIN DATA (1980-2014): subtract train
cdo -O chlevel,2,0 mod.his.nc tmp.nc; cdo -O -selyear,${begintrain}/${endtrain} tmp.nc tmp1.nc; cdo -O -remapcon,grid_1.0.dat tmp1.nc his_mm_r10.nc; rm tmp*

### MODEL TEST/FUTURE DATA (2015-2100)
cdo -O chlevel,2,0 mod.fu.nc tmp.nc; cdo -O -selyear,${begintest}/${endtest} tmp.nc tmp1.nc; cdo -O -remapcon,grid_1.0.dat tmp1.nc fu_mm_r10.nc; rm tmp*

echo "######### BEGIN BIAS CORRECT BY QUANTILE MAPPING ####################"
echo "# - Apply QM for montly basis                                       #"
echo "# - Split each dataset to 12 months                                 #"
echo "# - Use BC.R to bias correct each month                             #"
echo "# - Calculate changefactor by subtract train period climatolgoy     #"
echo "#####################################################################"
echo "Begin split data to 12 months and detrend"
# Split data to 12 months and detrend for each month

cdo -O -splitmon obs_mm_r10.nc tmp.obs_  #split to 12 months for obs, his, fu
cdo -O -splitmon his_mm_r10.nc tmp.his_
cdo -O -splitmon fu_mm_r10.nc tmp.fu_

echo "Begin Quantile Mapping"

sed -e 's/iybgn/'${begintest}'/g' \
    -e 's/iyend/'${endtest}'/g' \
    split_merge.sh > tmp.split_merge.sh

wd=$(pwd)
Rscript BC.R ${begintest} ${endtest} ${wd}


#OBS climatology at 1 deg
cdo -O -ymonmean obs_mm_r10.nc obs.climatology.nc

# Calculate cf
cdo -O -splityear bc.pr.nc tmp.pr.fu_
for iyear in $(seq ${begintest} ${endtest});do # for each year in fu length
  cdo -div tmp.pr.fu_${iyear}.nc obs.climatology.nc tmp.cf.${iyear}.nc
done
cdo -O -mergetime tmp.cf.201* tmp.cf.merge.21.nc
cdo -O -mergetime tmp.cf.202* tmp.cf.merge.22.nc
cdo -O -mergetime tmp.cf.203* tmp.cf.merge.23.nc
cdo -O -mergetime tmp.cf.204* tmp.cf.merge.24.nc
cdo -O -mergetime tmp.cf.205* tmp.cf.merge.25.nc
cdo -O -mergetime tmp.cf.206* tmp.cf.merge.26.nc
cdo -O -mergetime tmp.cf.207* tmp.cf.merge.27.nc
cdo -O -mergetime tmp.cf.208* tmp.cf.merge.28.nc
cdo -O -mergetime tmp.cf.209* tmp.cf.merge.29.nc
cdo -O -mergetime tmp.cf.merge* tmp.cf.nc


# cf at 0.1 deg
#cdo -O -setmisstoc,0 tmp.cf.nc tmp1.cf.nc
#cdo -O -remapbil,grid_0.1.dat tmp1.cf.nc tmp2.cf.nc
#cdo -O -sub tmp2.cf.nc zero.nc cf.pr.nc

cdo -O remapdis,grid_0.1.dat tmp.cf.nc tmp2.cf.nc
cdo -O -sub tmp2.cf.nc zero.nc cf.pr.nc
rm tmp*

echo "################# BEGIN SPATIAL DISAGGREGATION ##########################"
echo "# - Random select a month in the train period and add the change factor #"
echo "# for all days in this month                                            #"
echo "# - Add trend bias                                                      #"
echo "# - 2 output: with or without trend bias                                #"
echo "#########################################################################"

echo "Begin spatial disaggregation"
sed -e 's/iytrainbgn/'${begintrain}'/g' \
    -e 's/iytrainend/'${endtrain}'/g' \
    -e 's/iytestbgn/'${begintest}'/g' \
    -e 's/iytestend/'${endtest}'/g' \
    SD.sh > tmp.SD.sh

sh tmp.SD.sh # Main script SD

echo "Begin to finalize files!"
sed -e 's/iybgn/'${begintest}'/g' \
    -e 's/iyend/'${endtest}'/g' \
    -e 's/imodel/'${model}'/g' \
    final.sh > tmp.final.sh

sh tmp.final.sh
rm tmp.* pr.* 

echo "PROGRAM FINISHED!!!"
