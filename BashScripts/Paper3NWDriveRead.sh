for SampleInd in $(seq 1 10); do
#
echo "${SampleInd}" 
export SampleInd
#
sbatch -o Paper3NWRead_${SampleInd}.stdout.txt \
       -e Paper3NWRead_${SampleInd}.stdout.txt \
       --job-name=Read${SampleInd} \
       Paper3NWDriveRead.bash
#
sleep 0.1 # pause to be kind to the scheduler
done
