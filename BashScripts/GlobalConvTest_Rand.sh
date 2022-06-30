for BlockID in $(seq 1 3); do
for NSample in 500; do
#
echo "${BlockID},${NSample}" 
export BlockID NSample
#
sbatch -o GC_${BlockID}.stdout.txt \
       -e GC_${BlockID}.stdout.txt \
       --job-name=GC_${BlockID} \
       GlobalConvTest_Rand.bash
#
sleep 1 # pause to be kind to the scheduler
done
done
