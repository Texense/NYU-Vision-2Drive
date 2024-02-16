for Grating in $(seq 0 7.5 22.5); do
for SampleInd in $(seq 1 20); do
#
echo "${Grating},${SampleInd}" 
export Grating SampleInd
#
sbatch -o Paper3L6_${Grating}_${SampleInd}.stdout.txt \
       -e Paper3L6_${Grating}_${SampleInd}.stdout.txt \
       --job-name=ag${Grating}_s${SampleInd} \
       Paper3SharpenTunCur_L6_Final.bash
#
sleep 0.1 # pause to be kind to the scheduler
done
done
