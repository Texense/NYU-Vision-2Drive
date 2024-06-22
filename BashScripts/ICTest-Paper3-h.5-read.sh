for RadiusInd in 2; do
for SampleSize in 3; do
for minId  in 1; do
for maxId in 50; do
for StepSize in 0.1; do
#
echo "${RadiusInd},${SampleSize},${minId},${maxId},${StepSize}" 
export RadiusInd SampleSize minId maxId StepSize
#
sbatch -o ICread_${RadiusInd}_${SaveID}_${maxId}_${StepSize}.stdout.txt \
       -e ICread_${RadiusInd}_${SaveID}_${maxId}_${StepSize}.stdout.txt \
       --job-name=IC_${RadiusInd}_${SaveID}_${maxId}_${StepSize} \
       ICTest-Paper3-h.5-read.bash
#
sleep 0.1 # pause to be kind to the scheduler
done
done
done
done
done