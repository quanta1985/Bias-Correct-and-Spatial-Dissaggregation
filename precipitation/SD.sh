# SD METHOD: SD made in monthly basis, so first all the months during training period as splitted up
# Then with each of future month, select random same month in the train and scale all daily value
# of this month with the change factor (add change factor to each month)

ytrainbgn=iytrainbgn
ytrainend=iytrainend
ytestbgn=iytestbgn
ytestend=iytestend

var='pr'
#split daily obs train to each month
for ivar in $var;do
  cdo splityear obs.train.nc tmp.vngp.${ivar}. #obs train
  for iyear in $(seq ${ytrainbgn} ${ytrainend});do # train length
    cdo -O splitmon tmp.vngp.${ivar}.${iyear}.nc tmp.vngp.${ivar}.$iyear.
  done
done

#split change factor to each month
for ivar in $var;do
  cdo -O splityear cf.${ivar}.nc tmp.cf.${ivar}.
  for iyear in $(seq ${ytestbgn} ${ytestend});do # fu length
    cdo -O splitmon tmp.cf.${ivar}.${iyear}.nc tmp.cf.${ivar}.$iyear.
  done
done

lytrain=($(seq 1980 4 ${ytrainend}))                            #leap year train period
lyfu=($(seq 1980 4 ${ytestend}))                               #leap year future periody
nytrain=(1981 1982 1983 1985 1986 1987 1989 1990 1991 1993 1994 1995 1997 1998 1999 2001 2002 2003 2005 2006 2007 2009 2010 2011 2013 2014)  #normal year of train period

for iyear in $(seq ${ytestbgn} ${ytestend}); do #for each year in future period
  for mon in $(seq 1 12); do # for each month
    if [ ${mon} -ne 2 ]; then # If not Februray
      if [ ${mon} -lt 10 ]; then amon=`expr 0${mon}`; else amon=${mon}; fi # add 0 before 1-9 -> 01-09 to call file name
      rdyear=$(((RANDOM % (${ytrainend}-${ytrainbgn}+1)) + ${ytrainbgn})) #random year in TRAIN period
      #Random month * changefactor
      for ivar in ${var}; do
        cdo -O -mul tmp.vngp.${ivar}.${rdyear}.${amon}.nc tmp.cf.${ivar}.${iyear}.${amon}.nc tmp1.nc
        cdo -O -settaxis,${iyear}-${mon}-01,00:00:00,1day tmp1.nc tmp.bcsd.${ivar}.${iyear}.${amon}.nc
      done
    else
      if [[ " ${lyfu[@]} " =~ " ${iyear} " ]]; then       # if Februray, 
        num=$(($RANDOM % ${#lytrain[@]}));rdyear=${lytrain[$num]}  # if leap year, select random leap year
      else 
        num=$(($RANDOM % ${#nytrain[@]}));rdyear=${nytrain[$num]}  # if nornmal year, select random normal year 
      fi  
      # For Feb, same with other months
        for ivar in ${var}; do
          cdo -O -mul tmp.vngp.${ivar}.${rdyear}.02.nc tmp.cf.${ivar}.${iyear}.02.nc tmp1.nc
          cdo -O -settaxis,${iyear}-${mon}-01,00:00:00,1day tmp1.nc tmp.bcsd.${ivar}.${iyear}.02.nc
        done
    fi 
    echo "For $iyear - $mon, time $rdyear : $mon is selected"  # To check with each future year - mon, what historical year - mon was selected to scale
  done
done
