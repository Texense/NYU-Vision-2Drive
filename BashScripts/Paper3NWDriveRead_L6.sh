for SampleInd in $(seq 1 20); do
#
echo "${SampleInd}" 
export SampleInd
#
sbatch -o Paper3NWReadL6_${SampleInd}.stdout.txt \
       -e Paper3NWReadL6_${SampleInd}.stdout.txt \
       --job-name=Read${SampleInd} \
       Paper3NWDriveRead_L6.bash
#
sleep 0.1 # pause to be kind to the scheduler
done
