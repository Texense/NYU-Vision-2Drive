for RadiusInd in 2; do
for SampleSize in 20; do
for SaveID  in $(seq 1 30); do
for StepSize in 0.6; do
#
# Define the full path to the result file
resultFile="/scratch/zx555/NYU-Vision-2Drive/Data/Paper2_NetworkTuning/Fig1V4/Paper3ICTestData/Paper3LocalTest-Edep_Rad${RadiusInd}_size${SampleSize}_ID${SaveID}_h$(printf '%.2f' ${StepSize}).mat"
echo "Checking for ${resultFile}"
if [ ! -f "${resultFile}" ]; then
    echo "File ${resultFile} not found, submitting job..."
    echo "${RadiusInd},${SampleSize},${SaveID},${StepSize}" 
    export RadiusInd SampleSize SaveID StepSize
    #
    sbatch -o IC_${RadiusInd}_${SaveID}_${StepSize}.stdout.txt \
           -e IC_${RadiusInd}_${SaveID}_${StepSize}.stdout.txt \
           --job-name=IC_${RadiusInd}_${SaveID}_${StepSize} \
           ICTest-Paper3-h.bash
    #
    sleep 0.1 # pause to be kind to the scheduler
else
    echo "File ${resultFile} already exists, skipping..."
fi
#
done
done
done
done