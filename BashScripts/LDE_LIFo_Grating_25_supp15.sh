declare -a AngleMat LGNctgrMat L6ctgrMat
##AngleMat=(0 0 15 15 15 15 15 15 22.5 22.5 7.5 7.5 7.5)
##LGNctgrMat=(4 4 1 1 2 2 2 4 1 2 1 2 3)
##L6ctgrMat=(1 2 2 3 1 2 4 4 1 2 3 2 4)
##AngleMat=(15 15 15 15)
LGNctgrMat=(1 1 1 1 2 2 2 2 3 3 3 3 5 5)
L6ctgrMat=(1 1 3 3 1 2 4 4 2 2 4 4 3 4)
FlagLargeMat=(2 3 1 2 3 1 2 3 2 3 2 3 3 1)
#
for Angle in 15; do
for MatInd in $(seq 0 13); do
for LGNL6Mapctgr in 3; do
#
##Angle=${AngleMat[${MatInd}]}
LGNctgr=${LGNctgrMat[${MatInd}]}
L6ctgr=${L6ctgrMat[${MatInd}]}
FlagLargeDom=${FlagLargeMat[${MatInd}]}
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