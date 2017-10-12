#!/bin/sh
#
# Cross-correlation of noise data.
# Script finds all possible combinations.
# See 1_README_example_pcc5e for further informations
#
# 22/03/2013, schimmel@ictja.csic.es
#--------------------------------------

tt0=`date`
pcc_bin=~/Tomography/antscripts/Corr_stack_v03

# Working dir:
#-------------

dir0=`pwd `
echo #####################START################################## > "$dir0"/correlation.log 

# Loop over all data:
#--------------------

### Alternative strategy to define loop:
for i in `seq -w 1 366`
do
dir=$dir0"/"$i

# if data dir exists then goto data dir: 
#---------------------------------------
if test -d $dir
then
cd $dir
echo $dir
nl=` ls -1 *SAC | wc -l | tail -1 | awk '{ if ($1 > 1) print "2" }' `
else
nl=1
fi

#process if nl=2:
#----------------
if [ "$nl" -eq "2" ]
then

# Pre-processing:
#----------------
# BP:
echo $nl "aqui antes sac"
sac << END
r *SAC 
rmean
rtrend
bp co 1.0 3.0 p 2
w append bp
quit
END
echo $nl "aqui apos sac"

# running absolute mean normalization + whitening:
#-------------------------------------------------
for f in *SACbp
do
${pcc_bin}/norm_tavg_white $f N=0 white
done

# Bandpass whitened data:
#------------------------
# BP:
sac << END
r *HZ*SACpn
rmean
rtrend
bp co 1.0 3.0 p 2
w over
quit
END

# Correlation loops:
#-------------------
n1=`ls -1 *bpn | wc -l | awk '{ print $1}'`
# start n1 while-loop 
while [ "$n1" -ge "1" ]
do

f1=` ls -1 *bpn | tail -$n1 | head -1 ` 
f3=` echo $f1 | sed 's/bpn/bp/' `
n2=` echo $n1 | awk '{ print $1-1}' ` 

#start n2 while loop:
while [ "$n2" -ge "1" ]
do

f2=` ls -1 *bpn | tail -$n2 | head -1 ` 
f4=` echo $f2 | sed 's/bpn/bp/' `

sta1=`echo $f1 | sed 's/\./\ /g' | awk '{print $1}'`
sta2=`echo $f2 | sed 's/\./\ /g' | awk '{print $1}'`
paar="$sta1"Z_"$sta2"Z
paar0="$dir0"/"$paar"

filename="$paar0"/pcc1_"$paar"_"$i".sac
if [ -e $filename ]
then
echo File "$paar"/pcc1_"$paar"_"$i".sac Exist!!!
echo Cross-correlation Exist  "$paar"/pcc1_"$paar"_"$i".sac Exist!!! >> "$dir0"/correlation.log
echo Cross Correlation Already there, Should pass
echo ""
break
else
echo ""
echo ""
echo Cross Correlation "$i" "$f1" "$f2"
echo ""
echo ""
fi

sac <<- %
rh $f1 $f2
setbb a &1,b
setbb b &2,b
setbb c &1,e
setbb d &2,e
cut o ( (max %a %b%) + 1 ) ( (min %c %d%) - 1 )
r $f1 $f2
setbb e &1,npts
setbb f &2,npts
ch npts (min %e %f%)
sc echo &1,npts > t.t
write d1.sac d2.sac
cut off
rh $f3 $f4
setbb a &1,b
setbb b &2,b
setbb c &1,e
setbb d &2,e
cut o ( (max %a %b%) + 1 ) ( (min %c %d%) - 1 )
r $f3 $f4
write d3.sac d4.sac
quit
%
nsmp=` awk '{ print $1}' t.t `

# Minimum number of samples permitted to perform correlation:
if [ "$nsmp" -gt "700" ]
then

# cross-correlate data without time freq - normalization (PCC):
#===============================================================
echo pcc5e PCC
${pcc_bin}/pcc5e d3.sac d4.sac isac osac pcc nl1=-1500 nl2=1500 nn pov=1

if test -d $paar0
then
mv pcc.sac "$paar0"/pcc1_"$paar"_"$i".sac
else
mkdir $paar0
mv pcc.sac "$paar0"/pcc1_"$paar"_"$i".sac
fi
echo pcc1_"$paar"_"$i".sac >> "$dir0"/correlation.log 

fi

n2=`echo $n2 | awk '{ print $1-1}' ` 
#end n2 while-loop
done

n1=`echo $n1 | awk '{ print $1-1}' `
#end n1 while-loop
done 

# clean up 
\rm -f *SACbp*
\rm -f d?.sac
fi
# end data for-loop:
done

tt1=`date`
echo $tt0
echo $tt1
echo $tt0 >> "$dir0"/correlation.log
echo $tt1 >> "$dir0"/correlation.log
echo #####################FINISH################################## >> "$dir0"/correlation.log 
exit
