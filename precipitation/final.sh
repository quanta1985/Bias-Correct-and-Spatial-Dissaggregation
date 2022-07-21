#SD applied for each month, so all BCSD month are merged back to time series
model=imodel
yearbgn=iybgn
yearend=iyend

var='pr'
for ivar in $var;do #for each variable
  cdo -O -mergetime tmp.bcsd.${ivar}.201* tmp.merge.21.nc
  cdo -O -mergetime tmp.bcsd.${ivar}.202* tmp.merge.22.nc
  cdo -O -mergetime tmp.bcsd.${ivar}.203* tmp.merge.23.nc
  cdo -O -mergetime tmp.bcsd.${ivar}.204* tmp.merge.24.nc
  cdo -O -mergetime tmp.bcsd.${ivar}.205* tmp.merge.25.nc
  cdo -O -mergetime tmp.bcsd.${ivar}.206* tmp.merge.26.nc
  cdo -O -mergetime tmp.bcsd.${ivar}.207* tmp.merge.27.nc
  cdo -O -mergetime tmp.bcsd.${ivar}.208* tmp.merge.28.nc
  cdo -O -mergetime tmp.bcsd.${ivar}.209* tmp.merge.29.nc
  cdo -O -mergetime tmp.merge* bcsd_${ivar}_${model}_ssp585_${yearbgn}-${yearend}_daily.nc # Revised version with trend bias removal
done 

mkdir out
mv *${yearbgn}-${yearend}_daily.nc out
#rm tmp* pr.* his* fu* obs* bc.* cf.*
echo "BCSD finished !!!"
