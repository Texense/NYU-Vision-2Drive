for BlockID in 1 2 3; do
for SampleSize in 15; do
for minId  in 1; do
for maxId in 30; do
for StepSize in 0.50 0.60; do
#
echo "${BlockID},${SampleSize},${minId},${maxId},${StepSize}"
export BlockID SampleSize minId maxId StepSize
#
sbatch -o GCread_${BlockID}_${minId}_${maxId}_${StepSize}.stdout.txt \
       -e GCread_${BlockID}_${minId}_${maxId}_${StepSize}.stdout.txt \
       --job-name=GC_${BlockID}_${minId}_${maxId}_${StepSize} \
       GlobalConvTest_Rand-Paper3-read.bash
#
sleep 0.03 # pause to be kind to the scheduler
done
done
done
done
done