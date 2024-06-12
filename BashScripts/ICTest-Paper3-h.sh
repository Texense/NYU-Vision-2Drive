for RadiusInd in -1; do
for SampleSize in 20; do
for SaveID  in $(seq 1 30); do
for StepSize in 0.5; do
#
echo "${RadiusInd},${SampleSize},${SaveID},${StepSize}" 
export RadiusInd SampleSize SaveID StepSize
#
sbatch -o IC_${RadiusInd}_${SaveID}_${StepSize}.stdout.txt \
       -e IC_${RadiusInd}_${SaveID}_${StepSize}.stdout.txt \
       --job-name=IC_${RadiusInd}_${SaveID}_${StepSize} \
       ICTest-Paper3-h.bash
#
sleep 0.1 # pause to be kind to the scheduler
done
done
done
done