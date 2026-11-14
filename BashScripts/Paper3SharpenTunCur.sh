for SIlgnMpt in $(seq 1 0.04 1.4); do
for Grating in $(seq 0 7.5 22.5); do
for SampleInd in $(seq 1 20); do
#
echo "${SIlgnMpt},${Grating},${SampleInd}" 
export SIlgnMpt Grating SampleInd
#
sbatch -o Paper3TunCur${SIlgnMpt}_${Grating}_${SampleInd}.stdout.txt \
       -e Paper3TunCur${SIlgnMpt}_${Grating}_${SampleInd}.stdout.txt \
       --job-name=Il${SIlgnMpt}_ag${Grating}_s${SampleInd} \
       Paper3SharpenTunCur.bash
#
sleep 0.1 # pause to be kind to the scheduler
done
done
done
