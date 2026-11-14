for AngId in $(seq 1 13); do
for ContrastID in $(seq 1 3); do
for NSample in 50; do
#
echo "${AngId},${ContrastID},${NSample}" 
export AngId ContrastID NSample
#
sbatch -o GC_${AngId}_${ContrastID}.stdout.txt \
       -e GC_${AngId}_${ContrastID}.stdout.txt \
       --job-name=GC_${AngId}_${ContrastID} \
       GlobalConvTest_NESS.bash
#
sleep 1 # pause to be kind to the scheduler
done
done
done