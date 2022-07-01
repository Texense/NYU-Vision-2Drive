declare -a AngleMat LGNctgrMat L6ctgrMat
##AngleMat=(0 0 15 15 15 15 15 15 22.5 22.5 7.5 7.5 7.5)
##LGNctgrMat=(4 4 1 1 2 2 2 4 1 2 1 2 3)
##L6ctgrMat=(1 2 2 3 1 2 4 4 1 2 3 2 4)
AngleMat=(0 0 7.5 7.5)
LGNctgrMat=(4 4 1 1)
L6ctgrMat=(3 4 1 2)
#
for MatInd in $(seq 0 7); do
for LGNL6Mapctgr in 3; do
for FlagLargeDom in 2; do
#
Angle=${AngleMat[${MatInd}]}
LGNctgr=${LGNctgrMat[${MatInd}]}
L6ctgr=${L6ctgrMat[${MatInd}]}
#
echo "${Angle},${LGNctgr},${L6ctgr},${LGNL6Mapctgr},${FlagLargeDom}" 
export Angle LGNctgr L6ctgr LGNL6Mapctgr FlagLargeDom
#
sbatch -o LDE_${Angle}_${LGNctgr}_${L6ctgr}.stdout.txt \
       -e LDE_${Angle}_${LGNctgr}_${L6ctgr}.stdout.txt \
       --job-name=LDE_${Angle}_${LGNctgr}_${L6ctgr} \
       LDE_LIFo_Grating_16.bash
#
sleep 1 # pause to be kind to the scheduler
done
done
done
