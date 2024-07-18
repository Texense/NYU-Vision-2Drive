## Angle: 0 7.5 15 22.5
## L6Mapctgr should be 4 for real L6, and L6 catgory in 1:23 for 6:3:72Hz
for C in 66; do
## C: 19 42 66 100; 100 is the full contrast and already exists
for Angle in 0 7.5 15 22.5; do
for LGNctgr in $(seq 1 5); do
for lgnTF in 10; do
## lgnTF was 10 should be 2 4 10 16 24
for lgnSF in 2.5; do
for L6ctgr in $(seq 1 40); do
for L6Mapctgr in 4; do
for FlagLargeDom in $(seq 1 2); do
## should be 1-3 for small, Large, Larger
#
# Determine the string based on FlagLargeDom
case ${FlagLargeDom} in
    1) X='S';;
    2) X='L';;
    3) X='Ler';;
esac

# Define the full path to the result file
resultFile="/scratch/zx555/NYU-Vision-2Drive/Data/Paper2_NetworkTuning/Fig1V4/25Function_binocular_realLGN/Paper3_LIFLib_V4D2_Ang$(printf '%.1f' ${Angle})_LGNc${LGNctgr}_SF${lgnSF}_TF${lgnTF}_Contr${C}_L6c${L6ctgr}_uplow120-3_CtrlL4_${X}.mat"
echo "Checking for ${resultFile}"
if [ ! -f "${resultFile}" ]; then
    echo "File ${resultFile} not found, submitting job..."
    echo "${C},${Angle},${LGNctgr},${L6ctgr},${lgnTF},${lgnSF},${L6Mapctgr},${FlagLargeDom}"  
    export C Angle LGNctgr L6ctgr lgnTF lgnSF L6Mapctgr FlagLargeDom
    #
    sbatch -o LDE_${C}_${Angle}_${LGNctgr}_${L6ctgr}_${lgnTF}_${lgnSF}_${FlagLargeDom}.stdout.txt \
           -e LDE_${C}_${Angle}_${LGNctgr}_${L6ctgr}_${lgnTF}_${lgnSF}_${FlagLargeDom}.stderr.txt \
           --job-name=${C}_${Angle}_${LGNctgr}-${lgnTF}-${lgnSF}_${L6ctgr}-${FlagLargeDom} \
           LDE_LIF_realLGN_realL6.bash
    #
    sleep 0.03 # pause to be kind to the scheduler
else
    echo "File ${resultFile} already exists, skipping..."
fi
#
done
done
done
done
done
done
done
done
