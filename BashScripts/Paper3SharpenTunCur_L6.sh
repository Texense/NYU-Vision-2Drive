for L6Intesect in 0.65; do
for L6Shape in $(seq 0.12 0.02 0.2); do
for L6End in 1; do
for Grating in $(seq 0 7.5 22.5); do
for SampleInd in $(seq 1 20); do
#
echo "${L6Intesect},${L6Shape},${L6End},${Grating},${SampleInd}" 
export L6Intesect L6Shape L6End Grating SampleInd
#
sbatch -o Paper3TunCur_L6${L6Intesect}_${L6Shape}_${L6End}_${Grating}_${SampleInd}.stdout.txt \
       -e Paper3TunCur_L6${L6Intesect}_${L6Shape}_${L6End}_${Grating}_${SampleInd}.stdout.txt \
       --job-name=${L6Shape}_${L6End}_s${SampleInd} \
       Paper3SharpenTunCur_L6.bash
#
sleep 0.1 # pause to be kind to the scheduler
done
done
done
done
done
