#!/bin/bash

##FileName='/scratch/zx555/NYU-Vision-2Drive/Data/Paper2_NetworkTuning/MFVDriveTestV2.txt'
FileName='/scratch/zx555/NYU-Vision-2Drive/Data/Paper2_NetworkTuning/MFVDriveTestV4.txt'
nl=$(cat $FileName | wc -l)
declare -a x
declare -a y
for i in $(seq 1 $nl)
do
    x[i]="$(cat $FileName | awk -v p="$i" '{if(NR==p) print $1}')"
    y[i]="$(cat $FileName | awk -v p="$i" '{if(NR==p) print $2}')"
done
#upto this point all the numbers from first and second column of the file are stored 
#into x and y respectively. Following lines will just print them again for you.
for it in $(seq 1 $nl)
do
    SIEMtp=${x[$it]}
    SEIMtp=${y[$it]}
    echo "${SIEMtp} ${SEIMtp}"
    export SIEMtp SEIMtp
#
sbatch -o P2F1Dr${it}.stdout.txt \
       -e P2F1Dr${it}.stdout.txt \
       --job-name=Dr_${it} \
       Paper2Fig1Drive.bash
#
sleep 1 # pause to be kind to the scheduler    
done