#SD applied for each month, so all BCSD month are merged back to time series
model=imodel
yearbgn=iybgn
yearend=iyend

var='tas tasmax tasmin'
for ivar in $var;do #for each variable
  cdo -O -mergetime tmp.bcsd.${ivar}fix.201* tmp.merge.21.nc
  cdo -O -mergetime tmp.bcsd.${ivar}fix.202* tmp.merge.22.nc
  cdo -O -mergetime tmp.bcsd.${ivar}fix.203* tmp.merge.23.nc
  cdo -O -mergetime tmp.bcsd.${ivar}fix.204* tmp.merge.24.nc
  cdo -O -mergetime tmp.bcsd.${ivar}fix.205* tmp.merge.25.nc
  cdo -O -mergetime tmp.bcsd.${ivar}fix.206* tmp.merge.26.nc
  cdo -O -mergetime tmp.bcsd.${ivar}fix.207* tmp.merge.27.nc
  cdo -O -mergetime tmp.bcsd.${ivar}fix.208* tmp.merge.28.nc
  cdo -O -mergetime tmp.bcsd.${ivar}fix.209* tmp.merge.29.nc
  cdo -O -mergetime tmp.merge* bcsd_${ivar}_${model}_ssp585_${yearbgn}-${yearend}_daily.nc # Revised version with trend bias removal
done 

mkdir out
mv *${yearbgn}-${yearend}_daily.nc out
rm tmp* tas.* his* fu* obs* bc.* cf.*
echo "BCSD finished !!!"
