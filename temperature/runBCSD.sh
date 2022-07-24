echo "########################################### SETUP ########################################"
echo "# 1. TRAIN (1980-2004) - TEST (2005-2014)                                    #"
echo "# 2. Get monthly mean of VnGP                                                            #" 
echo "# 3. Regrid GCM and VnGP to same resolution                                              #" 
echo "# 4. All variables (tas, tasmax, tasmin, t2m, tx, tm) are renamed to tas for easier use  #"
echo "# 5. obsvervation (obs), historical (his), future simulation (fu)                        #" 
echo "# 6. Number 1, 2, 3 (for example obs1, obs2, obs3) represent tas tasmax tasmin           #"
echo "##########################################################################################"
model=ACCESS-CM2
begintrain=1980
endtrain=2014
begintest=2015
endtest=2099
dir=HIS   #Directory of current process

### DAILY obs data (1961-2018): Link RAW data
ln -s /work/users/quanta/QUAN/DATA/VnGC/T2m.dd.1961.2018.nc obs.tas.nc
ln -s /work/users/quanta/QUAN/DATA/VnGC/Tx.dd.1961.2018.nc obs.tasmax.nc
ln -s /work/users/quanta/QUAN/DATA/VnGC/Tm.dd.1961.2018.nc obs.tasmin.nc

### MONTHLY model data his (2015-2100)
ln -s /work/users/quanta/QUAN/DATA/CMIP6/NEW/${model}/${model}_T2m_his_mm_1980-2014.nc mod.his.tas.nc
ln -s /work/users/quanta/QUAN/DATA/CMIP6/NEW/${model}/${model}_Tx_his_mm_1980-2014.nc mod.his.tasmax.nc
ln -s /work/users/quanta/QUAN/DATA/CMIP6/NEW/${model}/${model}_Tm_his_mm_1980-2014.nc mod.his.tasmin.nc

### MONTHLY model data fu (2015-2100): Link RAW data
ln -s /work/users/quanta/QUAN/DATA/CMIP6/NEW/${model}/${model}_T2m_ssp585_mm_2015-2100.nc mod.fu.tas.nc
ln -s /work/users/quanta/QUAN/DATA/CMIP6/NEW/${model}/${model}_Tx_ssp585_mm_2015-2100.nc mod.fu.tasmax.nc
ln -s /work/users/quanta/QUAN/DATA/CMIP6/NEW/${model}/${model}_Tm_ssp585_mm_2015-2100.nc mod.fu.tasmin.nc

### SUBTRACT obs daily data (1980-2014) for training
cdo -selyear,${begintrain}/${endtrain} obs.tas.nc VnGC.tas.dd.${begintrain}.${endtrain}.nc
cdo -selyear,${begintrain}/${endtrain} obs.tasmax.nc VnGC.tasmax.dd.${begintrain}.${endtrain}.nc
cdo -selyear,${begintrain}/${endtrain} obs.tasmin.nc VnGC.tasmin.dd.${begintrain}.${endtrain}.nc

### OBS TRAIN DATA (1980-2014): get monthy average; regrid to 1.0; change all variable names to tas (easier use later)
cdo -O -remapcon,grid_1.0.dat -monmean -chname,t2m,tas VnGC.tas.dd.${begintrain}.${endtrain}.nc obs1_mm_r10.nc #tas
cdo -O -remapcon,grid_1.0.dat -monmean -chname,tx,tas VnGC.tasmax.dd.${begintrain}.${endtrain}.nc obs2_mm_r10.nc #tasmax
cdo -O -remapcon,grid_1.0.dat -monmean -chname,tm,tas VnGC.tasmin.dd.${begintrain}.${endtrain}.nc obs3_mm_r10.nc #tasmin

### MODEL TRAIN DATA (1980-2014): subtract train
cdo -O -chname,tas,tas mod.his.tas.nc tmp.nc;cdo -O -chlevel,2,0 tmp.nc tmp1.nc;cdo -O -selyear,${begintrain}/${endtrain} tmp1.nc tmp2.nc;cdo -O -remapcon,grid_1.0.dat tmp2.nc his1_mm_r10.nc; rm tmp*
cdo -O -chname,tasmax,tas mod.his.tasmax.nc tmp.nc;cdo -O -chlevel,2,0 tmp.nc tmp1.nc;cdo -O -selyear,${begintrain}/${endtrain} tmp1.nc tmp2.nc;cdo -O -remapcon,grid_1.0.dat tmp2.nc his2_mm_r10.nc; rm tmp*
cdo -O -chname,tasmin,tas mod.his.tasmin.nc tmp.nc;cdo -O -chlevel,2,0 tmp.nc tmp1.nc;cdo -O -selyear,${begintrain}/${endtrain} tmp1.nc tmp2.nc;cdo -O -remapcon,grid_1.0.dat tmp2.nc his3_mm_r10.nc; rm tmp*

### MODEL TEST/FUTURE DATA (2015-2100): use 85 yrs independent
cdo -O -chname,tas,tas mod.fu.tas.nc tmp.nc;cdo -O -chlevel,2,0 tmp.nc tmp1.nc;cdo -O -selyear,${begintest}/${endtest} tmp1.nc tmp2.nc;cdo -O -remapcon,grid_1.0.dat tmp2.nc fu1_mm_r10.nc; rm tmp*
cdo -O -chname,tasmax,tas mod.fu.tasmax.nc tmp.nc;cdo -O -chlevel,2,0 tmp.nc tmp1.nc;cdo -O -selyear,${begintest}/${endtest} tmp1.nc tmp2.nc;cdo -O -remapcon,grid_1.0.dat tmp2.nc fu2_mm_r10.nc; rm tmp*
cdo -O -chname,tasmin,tas mod.fu.tasmin.nc tmp.nc;cdo -O -chlevel,2,0 tmp.nc tmp1.nc;cdo -O -selyear,${begintest}/${endtest} tmp1.nc tmp2.nc;cdo -O -remapcon,grid_1.0.dat tmp2.nc fu3_mm_r10.nc; rm tmp*

echo "######### BEGIN BIAS CORRECT BY QUANTILE MAPPING ####################"
echo "# - Apply QM for montly basis                                       #"
echo "# - Split each dataset to 12 months                                 #"
echo "# - Use BC.R to bias correct each month                             #"
echo "# - Tas, Tasmax, Tasmin are treated the same way and independently  #"
echo "# - Calculate changefactor by subtract train period climatolgoy     #"
echo "#####################################################################"

echo "Begin split data to 12 months and detrend"
# Split data to 12 months and detrend for each month

for e in $(seq 1 3);do #for each tas, tasmax, tasmin
  cdo -O -splitmon obs${e}_mm_r10.nc tmp.obs${e}_mm_  #split to 12 months for obs, his, fu
  cdo -O -splitmon his${e}_mm_r10.nc tmp.his${e}_mm_
  cdo -O -splitmon fu${e}_mm_r10.nc tmp.fu${e}_mm_
  for imon in $(seq 1 12);do # split each month to years
    if [ $imon -le 9 ]; then emon=`expr 0$imon`; else emon=$imon; fi
    cdo -O -detrend tmp.obs${e}_mm_${emon}.nc tmp.obs${e}_${emon}.anomaly.nc #calculate trend and anomaly for each month
    cdo -sub tmp.obs${e}_mm_${emon}.nc tmp.obs${e}_${emon}.anomaly.nc tmp.obs${e}_${emon}.trend.nc
    cdo -O -detrend tmp.his${e}_mm_${emon}.nc tmp.his${e}_${emon}.anomaly.nc
    cdo -sub tmp.his${e}_mm_${emon}.nc tmp.his${e}_${emon}.anomaly.nc tmp.his${e}_${emon}.trend.nc
    cdo -O -detrend tmp.fu${e}_mm_${emon}.nc tmp.fu${e}_${emon}.anomaly.nc
    cdo -sub tmp.fu${e}_mm_${emon}.nc tmp.fu${e}_${emon}.anomaly.nc tmp.fu${e}_${emon}.trend.nc
  done
done

echo "Begin Quantile Mapping"
# Perform quantile mapping on temperature anomaly

sed -e 's/iybgn/'${begintest}'/g' \
    -e 's/iyend/'${endtest}'/g' \
    split_merge.sh > tmp.split_merge.sh

wd=$(pwd)
Rscript BC.R ${begintest} ${endtest} ${wd}

#fix level
#cdo chlevel bc.


echo "Split & merge back trend"
# Split & merge back the trend to calculate trend bias (trend his - trend obs)
# trend biases are caculated for each and every single month after detrend so we need to add them back
# to orginial time series
for e in $(seq 1 3);do
  for imon in $(seq 1 12); do
    if [ $imon -le 9 ]; then emon=`expr 0$imon`; else emon=$imon; fi
    cdo -O -splityear tmp.obs${e}_${emon}.trend.nc tmp.obs${e}.trend_
    cdo -O -splityear tmp.his${e}_${emon}.trend.nc tmp.his${e}.trend_
    cdo -O -splityear tmp.fu${e}_${emon}.trend.nc tmp.fu${e}.trend_
    for iyear in $(seq ${begintrain} ${endtrain});do #train length (obs and his always having the same length for training)
      cdo -O -splitmon tmp.obs${e}.trend_${iyear}.nc tmp.obs${e}.montrend_${iyear}_
      cdo -O -splitmon tmp.his${e}.trend_${iyear}.nc tmp.his${e}.montrend_${iyear}_
    done
    for iyear in $(seq ${begintest} ${endtest});do #fu length (length of future simulation)
      cdo -O -splitmon tmp.fu${e}.trend_${iyear}.nc tmp.fu${e}.montrend_${iyear}_
    done
  done
  # Merge months to time series can be done in a single line code but it consummes system memory so 
  # we merge it to years and from years to time series
  for iyear in $(seq ${begintrain} ${endtrain});do #train length (merge back year by year)
    cdo -O -mergetime tmp.obs${e}.montrend_${iyear}* tmp.obs${e}.montrend.merge_${iyear}.nc
    cdo -O -mergetime tmp.his${e}.montrend_${iyear}* tmp.his${e}.montrend.merge_${iyear}.nc
  done
  
  for iyear in $(seq ${begintest} ${endtest});do #fu length 
    cdo -O -mergetime tmp.fu${e}.montrend_${iyear}* tmp.fu${e}.montrend.merge_${iyear}.nc
  done

cdo -O -mergetime tmp.obs${e}.montrend.merge* obs${e}.trend.nc # merge years to time series
cdo -O -mergetime tmp.his${e}.montrend.merge* his${e}.trend.nc
cdo -O -mergetime tmp.fu${e}.montrend.merge* fu${e}.trend.nc
done

#rm tmp.obs* tmp.his* tmp.fu* tas.*


# Make mask file out of observation file
cdo -O -timmean -sub obs.nc obs.nc zero.nc

echo "Add trend back to bc anomaly - Calculate trend bias - Caculate change factor"
for e in $(seq 1 3);do # loop tas tasmax tasmin
  cdo -O -add fu${e}.trend.nc bc.tas.${e}.nc bc.fu.${e}.nc                               # bc.fu with trend added back # bc.fu = bc.anomaly.fu + trend.fu
  cdo -O -ymonmean -sub his${e}.trend.nc obs${e}.trend.nc trend.bias.climatology.${e}.nc # mean.bias climatology
  cdo -O -ymonmean obs${e}_mm_r10.nc obs.climatology.${e}.nc                             # obs monthly climatology 
  cdo -O -splityear bc.fu.${e}.nc tmp.bc.fu.${e}.year_                                   # split bc.fu into separate years
  for iyear in $(seq ${begintest} ${endtest});do # for each year in fu length
    ### cf = bc.fu - mean.bias - obs.climatology
    cdo -O -add obs.climatology.${e}.nc trend.bias.climatology.${e}.nc tmp1.nc; cdo -O sub tmp.bc.fu.${e}.year_${iyear}.nc tmp1.nc tmp.cf.${e}.year_${iyear}.nc; rm tmp1.nc
  done
  cdo -O -mergetime tmp.cf.${e}.year_201* tmp.cf.${e}.year.merge.21.nc
  cdo -O -mergetime tmp.cf.${e}.year_202* tmp.cf.${e}.year.merge.22.nc
  cdo -O -mergetime tmp.cf.${e}.year_203* tmp.cf.${e}.year.merge.23.nc
  cdo -O -mergetime tmp.cf.${e}.year_204* tmp.cf.${e}.year.merge.24.nc
  cdo -O -mergetime tmp.cf.${e}.year_205* tmp.cf.${e}.year.merge.25.nc
  cdo -O -mergetime tmp.cf.${e}.year_206* tmp.cf.${e}.year.merge.26.nc
  cdo -O -mergetime tmp.cf.${e}.year_207* tmp.cf.${e}.year.merge.27.nc
  cdo -O -mergetime tmp.cf.${e}.year_208* tmp.cf.${e}.year.merge.28.nc
  cdo -O -mergetime tmp.cf.${e}.year_209* tmp.cf.${e}.year.merge.29.nc
  cdo -O -mergetime tmp.cf.${e}.year.merge* tmp.cf.${e}.nc 
  cdo -O -remapdis,zero.nc tmp.cf.${e}.nc tmp.cf.r01.${e}.nc                 #interpolate to 0.1
done

# Mask outside VN and return name tas tasmax tasmin 
cdo -O -sub tmp.cf.r01.1.nc zero.nc cf.tas.nc
cdo -O -sub tmp.cf.r01.2.nc zero.nc cf.tasmax.nc
cdo -O -sub tmp.cf.r01.3.nc zero.nc cf.tasmin.nc

echo "################# BEGIN SPATIAL DISAGGREGATION ##########################"
echo "# - Random select a month in the train period and add the change factor #"
echo "# for all days in this month                                            #"
echo "# - Add trend bias                                                      #"
echo "# - 2 output: with or without trend bias                                #"
echo "#########################################################################"

#echo "Begin spatial disaggregation"
sed -e 's/iytrainbgn/'${begintrain}'/g' \
    -e 's/iytrainend/'${endtrain}'/g' \
    -e 's/iytestbgn/'${begintest}'/g' \
    -e 's/iytestend/'${endtest}'/g' \
    SD.sh > tmp.SD.sh

sh tmp.SD.sh # Main script SD

#echo "Begin to finalize files!"
sed -e 's/iybgn/'${begintest}'/g' \
    -e 's/iyend/'${endtest}'/g' \
    -e 's/imodel/'${model}'/g' \
    final.sh > tmp.final.sh

sh tmp.final.sh
rm tmp.cf* tmp.vngp* tmp.bc.* tmp.tas*

echo "PROGRAM FINISHED!!!"
