# SD METHOD: SD made in monthly basis, so first all the months during training period as splitted up
# Then with each of future month, select random same month in the train and scale all daily value
# of this month with the change factor (add change factor to each month)

ytrainbgn=iytrainbgn
ytrainend=iytrainend
ytestbgn=iytestbgn
ytestend=iytestend

var='tas tasmax tasmin'
#split daily obs train to each month
for ivar in $var;do
  cdo splityear VnGC.${ivar}.dd.${ytrainbgn}.${ytrainend}.nc tmp.vngp.${ivar}. #obs train
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

lytrain=()
nytrain=()
for i in $(seq ${ytrainbgn} ${ytrainend});do
  a=`expr $i % 4`
  b=`expr $i % 100`
  c=`expr $i % 400`
  if [ $a -eq 0 -a $b -ne 0 -o $c -eq 0 ];then
    echo $i
    lytrain=($(echo ${lytrain[*]}) $(echo ${i[*]})) 
  else nytrain=($(echo ${nytrain[*]}) $(echo ${i[*]})) 
  fi  
done
echo "Leap years in the training dataset:" ${lytrain[*]}
echo "Normal years in the training dataset:" ${nytrain[*]}

lyfu=()
for i in $(seq ${ytestbgn} ${ytestend});do
  a=`expr $i % 4`
  b=`expr $i % 100`
  c=`expr $i % 400`
  if [ $a -eq 0 -a $b -ne 0 -o $c -eq 0 ];then
    echo $i
    lyfu=($(echo ${lyfu[*]}) $(echo ${i[*]})) 
  fi  
done
echo "Leap years in the future dataset:" ${lyfu[*]}

for iyear in $(seq ${ytestbgn} ${ytestend}); do #for each year in future period
  for mon in $(seq 1 12); do # for each month
    if [ ${mon} -ne 2 ]; then # If not Februray
      if [ ${mon} -lt 10 ]; then amon=`expr 0${mon}`; else amon=${mon}; fi # add 0 before 1-9 -> 01-09 to call file name
      rdyear=$(((RANDOM % (${ytrainend}-${ytrainbgn}+1)) + ${ytrainbgn})) #random year in TRAIN period
      #Random month + changefactor - trend bias
      for ivar in ${var}; do
        cdo -O -settaxis,${iyear}-${mon}-01,00:00:00,1day \
               -add tmp.vngp.${ivar}.${rdyear}.${amon}.nc \
               tmp.cf.${ivar}.${iyear}.${amon}.nc \
               tmp.bcsd.${ivar}.${iyear}.${amon}.nc
      done
    else
      if [[ " ${lyfu[@]} " =~ " ${iyear} " ]]; then       # if Februray, 
        num=$(($RANDOM % ${#lytrain[@]}));rdyear=${lytrain[$num]}  # if leap year, select random leap year
      else 
        num=$(($RANDOM % ${#nytrain[@]}));rdyear=${nytrain[$num]}  # if nornmal year, select random normal year 
      fi  
      # For Feb, same with other months
        for ivar in ${var}; do
          cdo -O -settaxis,${iyear}-${mon}-01,00:00:00,1day \
                -add tmp.vngp.${ivar}.${rdyear}.02.nc \
                tmp.cf.${ivar}.${iyear}.02.nc \
                tmp.bcsd.${ivar}.${iyear}.02.nc
        done
    fi 
    echo "For $iyear - $mon, time $rdyear : $mon is selected"  # To check with each future year - mon, what historical year - mon was selected to scale
  done
done
