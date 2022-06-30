for RadiusInd in $(seq 6 10); do
for SampleSize in 1000; do
for SaveID  in $(seq 1 10); do
#
echo "${RadiusInd},${SampleSize},${SaveID}" 
export RadiusInd SampleSize SaveID
#
sbatch -o IC_${RadiusInd}_${SaveID}.stdout.txt \
       -e IC_${RadiusInd}_${SaveID}.stdout.txt \
       --job-name=IC_${RadiusInd}_${SaveID} \
       ICTest.bash
#
sleep 1 # pause to be kind to the scheduler
done
done
done
