## Angle: 0 7.5 15 22.5
## L6Mapctgr should be 2 if we want cos L6, 3 for finalized L6-LGN
for Angle   in 0 7.5 15 22.5; do
for LGNctgr in $(seq 1 5); do
for lgnTF in 2 4 16 24; do
## it was lgnTF = 10
for lgnSF in 2.5; do
for L6ctgr  in $(seq 1 5); do
for L6Mapctgr in 3; do
for FlagLargeDom in $(seq 1 3); do
#
echo "${Angle},${LGNctgr},${L6ctgr},${lgnTF},${lgnSF},${L6Mapctgr},${FlagLargeDom}"  
export Angle LGNctgr L6ctgr lgnTF lgnSF L6Mapctgr FlagLargeDom
#
sbatch -o LDE_${Angle}_${LGNctgr}_${L6ctgr}_${lgnTF}_${lgnSF}_${FlagLargeDom}.stdout.txt \
       -e LDE_${Angle}_${LGNctgr}_${L6ctgr}_${lgnTF}_${lgnSF}_${FlagLargeDom}.stdout.txt \
       --job-name=${Angle}_${LGNctgr}-${lgnTF}-${lgnSF}_${L6ctgr}-${FlagLargeDom} \
       LDE_LIF_realLGN_25.bash
#
sleep 0.1 # pause to be kind to the scheduler
done
done
done
done
done
done
done
