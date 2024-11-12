for RadiusInd in -1; do
for SampleSize in 20; do
for minId  in 1; do
for maxId in 300; do
## for StepSize in 0.5; do
#
echo "${RadiusInd},${SampleSize},${minId},${maxId}" 
export RadiusInd SampleSize minId maxId
#
sbatch -o ICread_${RadiusInd}_${SaveID}_${maxId}.stdout.txt \
       -e ICread_${RadiusInd}_${SaveID}_${maxId}.stdout.txt \
       --job-name=IC_${RadiusInd}_${SaveID}_${maxId} \
       ICTest-Paper3-h-read.bash
#
sleep 0.1 # pause to be kind to the scheduler
## done
done
done
done
done