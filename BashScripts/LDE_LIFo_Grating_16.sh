for Angle   in 0 7.5 15 22.5; do
for LGNctgr in $(seq 1 4); do
for L6ctgr  in $(seq 1 4); do
for LGNL6Mapctgr in 3; do
for FlagLargeDom in 3; do
#
echo "${Angle},${LGNctgr},${L6ctgr},${LGNL6Mapctgr},${FlagLargeDom}" 
export Angle LGNctgr L6ctgr LGNL6Mapctgr FlagLargeDom
#
sbatch -o LDE_${Angle}_${LGNctgr}_${L6ctgr}.stdout.txt \
       -e LDE_${Angle}_${LGNctgr}_${L6ctgr}.stdout.txt \
       --job-name=Ag${Angle}_${LGNctgr}_${L6ctgr} \
       LDE_LIFo_Grating_16.bash
#
sleep 1 # pause to be kind to the scheduler
done
done
done
done
done
