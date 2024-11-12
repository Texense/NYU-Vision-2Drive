for BlockID in 2; do
for SaveID in $(seq 1 30); do
for NSample in 15; do
for StepSize in 0.50 0.60; do
#
# Define the full path to the result file
resultFile="/scratch/zx555/NYU-Vision-2Drive/Data/Paper2_NetworkTuning/Fig1V4/Paper3PlotingData_Global/Paper3GlobConv_BlockID${BlockID}_SaveId${SaveID}_Samp${NSample}_h$(printf '%.2f' ${StepSize}).mat"
echo "${BlockID},${NSample},${SaveID},${StepSize}" 
export BlockID NSample SaveID StepSize
#
sbatch -o GC_${BlockID}_${SaveID}_${StepSize}.stdout.txt \
       -e GC_${BlockID}_${SaveID}_${StepSize}.stdout.txt \
       --job-name=GC_${BlockID}_${SaveID}_${StepSize} \
       GlobalConvTest_Rand-Paper3.bash
#
sleep 0.03 # pause to be kind to the scheduler
done
done
done
done
