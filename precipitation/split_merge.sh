mon='1 2 3 4 5 6 7 8 9 10 11 12'

yearbgn=iybgn
yearend=iyend

for imon in $mon; do #Split QM bias corrected 12 months back to each year
	cdo -O splityear pr.$imon\.nc tmp.pr.$imon\.
done

for iyear in $(seq ${yearbgn} ${yearend});do  #future length # split year to month
	for imon in $mon;do
    cdo -O -L -settaxis,$iyear-$imon-15,00:00:00,1mon -setreftime,1900-01-15,00:00:00 tmp.pr.$imon\.$iyear\.nc tmp.pr.$iyear\.$imon
	done
done

for iyear in $(seq ${yearbgn} ${yearend});do  #future length  #merge month back to time series (reoder all months)
  cdo -O mergetime tmp.pr.$iyear\.* tmp.pr.bc.$iyear\.nc #break to reduce memory
done
cdo -O mergetime tmp.pr.bc.201* tmp.pr.bc.merge.21.nc
cdo -O mergetime tmp.pr.bc.202* tmp.pr.bc.merge.22.nc
cdo -O mergetime tmp.pr.bc.203* tmp.pr.bc.merge.23.nc
cdo -O mergetime tmp.pr.bc.204* tmp.pr.bc.merge.24.nc
cdo -O mergetime tmp.pr.bc.205* tmp.pr.bc.merge.25.nc
cdo -O mergetime tmp.pr.bc.206* tmp.pr.bc.merge.26.nc
cdo -O mergetime tmp.pr.bc.207* tmp.pr.bc.merge.27.nc
cdo -O mergetime tmp.pr.bc.208* tmp.pr.bc.merge.28.nc
cdo -O mergetime tmp.pr.bc.209* tmp.pr.bc.merge.29.nc
cdo -O mergetime tmp.pr.bc.merge* bc.pr.nc
