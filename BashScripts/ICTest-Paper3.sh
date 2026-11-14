for RadiusInd in -1; do
for SampleSize in 20; do
for SaveID  in $(seq 1 300); do
#
echo "${RadiusInd},${SampleSize},${SaveID}" 
export RadiusInd SampleSize SaveID
#
sbatch -o IC_${RadiusInd}_${SaveID}.stdout.txt \
       -e IC_${RadiusInd}_${SaveID}.stdout.txt \
       --job-name=IC_${RadiusInd}_${SaveID} \
       ICTest-Paper3.bash
#
sleep 0.1 # pause to be kind to the scheduler
done
done
done
