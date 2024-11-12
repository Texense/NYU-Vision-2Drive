for RadiusInd in 2; do
for SampleSize in 3; do
for SaveID  in $(seq 1 50); do
for StepSize in 0.1; do
for EpocTest in 2000; do
#
# Define the full path to the result file
resultFile="/scratch/zx555/NYU-Vision-2Drive/Data/Paper2_NetworkTuning/Fig1V4/Paper3ICTestData/Paper3LocalTest_Rad${RadiusInd}_size${SampleSize}_ID${SaveID}_h$(printf '%.2f' ${StepSize}).mat"
echo "Checking for ${resultFile}"
if [ ! -f "${resultFile}" ]; then
    echo "File ${resultFile} not found, submitting job..."
    echo "${RadiusInd},${SampleSize},${SaveID},${StepSize},${EpocTest}" 
    export RadiusInd SampleSize SaveID StepSize EpocTest
    #
    sbatch -o IC_${RadiusInd}_${SaveID}_${StepSize}_${EpocTest}.stdout.txt \
           -e IC_${RadiusInd}_${SaveID}_${StepSize}_${EpocTest}.stdout.txt \
           --job-name=IC_${RadiusInd}_${SaveID}_${StepSize}_${EpocTest} \
           ICTest-Paper3-h-Epoc.bash
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
done