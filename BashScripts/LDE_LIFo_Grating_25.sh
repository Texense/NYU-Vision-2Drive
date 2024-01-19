## Angle: 0 7.5 15 22.5
for Angle   in 0 7.5 15 22.5; do
for LGNctgr in $(seq 1 5); do
for L6ctgr  in $(seq 1 5); do
for LGNL6Mapctgr in 3; do
for FlagLargeDom in $(seq 1 3); do
#
echo "${Angle},${LGNctgr},${L6ctgr},${LGNL6Mapctgr},${FlagLargeDom}" 
export Angle LGNctgr L6ctgr LGNL6Mapctgr FlagLargeDom
#
sbatch -o LDE_${Angle}_${LGNctgr}_${L6ctgr}_${FlagLargeDom}.stdout.txt \
       -e LDE_${Angle}_${LGNctgr}_${L6ctgr}_${FlagLargeDom}.stdout.txt \
       --job-name=${Angle}_${LGNctgr}_${L6ctgr}_${FlagLargeDom} \
       LDE_LIFo_Grating_16.bash
#
sleep 1 # pause to be kind to the scheduler
done
done
done
done
done
