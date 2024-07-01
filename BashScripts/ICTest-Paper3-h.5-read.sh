for RadiusInd in -1; do
for SampleSize in 20; do
for minId  in 1; do
for maxId in 30; do
for StepSize in 0.33 0.50 0.60 0.65 0.70; do
#
echo "${RadiusInd},${SampleSize},${minId},${maxId},${StepSize}" 
export RadiusInd SampleSize minId maxId StepSize
#
sbatch -o ICread_${RadiusInd}_${SaveID}_${maxId}_${StepSize}.stdout.txt \
       -e ICread_${RadiusInd}_${SaveID}_${maxId}_${StepSize}.stdout.txt \
       --job-name=IC_${RadiusInd}_${SaveID}_${maxId}_${StepSize} \
       ICTest-Paper3-h.5-read.bash
#
sleep 0.03 # pause to be kind to the scheduler
done
done
done
done
done