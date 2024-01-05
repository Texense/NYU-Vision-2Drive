for SIlgnMpt in $(seq 1 0.04 1.2); do
for Grating in $(seq 0 7.5 22.5); do
#
echo "${SIlgnMpt},${Grating}" 
export SIlgnMpt Grating
#
sbatch -o Paper3TunCur${SIlgnMpt}_${Grating}.stdout.txt \
       -e Paper3TunCur${SIlgnMpt}_${Grating}.stdout.txt\
       --job-name=Il${SIlgnMpt}_ag${Grating} \
       Paper3SharpenTunCur.bash
#
sleep 1 # pause to be kind to the scheduler
done
done
