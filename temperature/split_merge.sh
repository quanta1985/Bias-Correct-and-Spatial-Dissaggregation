mon='1 2 3 4 5 6 7 8 9 10 11 12'

yearbgn=iybgn
yearend=iyend

for imon in $mon; do #Split QM bias corrected 12 months back to each year
	cdo -O splityear tas.$imon\.nc tmp.tas.$imon\.
done

for iyear in $(seq ${yearbgn} ${yearend});do  #future length # split year to month
	for imon in $mon;do
		cdo -O -L -settaxis,$iyear-$imon-15,00:00:00,1mon -setreftime,1900-01-15,00:00:00 tmp.tas.$imon\.$iyear\.nc tmp.tas.$iyear\.$imon
	done
done

for iyear in $(seq ${yearbgn} ${yearend});do  #future length  #merge month back to time series (reoder all months)
  cdo -O mergetime tmp.tas.$iyear\.* tmp.tas.bc.$iyear\.nc #break to reduce memory
done
cdo -O mergetime tmp.tas.bc.201* tmp.tas.bc.merge.21.nc
cdo -O mergetime tmp.tas.bc.202* tmp.tas.bc.merge.22.nc
cdo -O mergetime tmp.tas.bc.203* tmp.tas.bc.merge.23.nc
cdo -O mergetime tmp.tas.bc.204* tmp.tas.bc.merge.24.nc
cdo -O mergetime tmp.tas.bc.205* tmp.tas.bc.merge.25.nc
cdo -O mergetime tmp.tas.bc.206* tmp.tas.bc.merge.26.nc
cdo -O mergetime tmp.tas.bc.207* tmp.tas.bc.merge.27.nc
cdo -O mergetime tmp.tas.bc.208* tmp.tas.bc.merge.28.nc
cdo -O mergetime tmp.tas.bc.209* tmp.tas.bc.merge.29.nc
cdo -O mergetime tmp.tas.bc.merge* bc.tas.nc
