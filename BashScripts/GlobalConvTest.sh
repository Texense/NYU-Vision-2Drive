for ICId in $(seq 1 4); do
for ContrastID in $(seq 1 4); do
for ITestSize in 15; do
for PertSize in 5; do
#
echo "${ICId},${ContrastID},${ITestSize},${PertSize}" 
export ICId ContrastID ITestSize PertSize
#
sbatch -o GC_${ICId}_${ContrastID}.stdout.txt \
       -e GC_${ICId}_${ContrastID}.stdout.txt \
       --job-name=GC_${ICId}_${ContrastID} \
       GlobalConvTest.bash
#
sleep 1 # pause to be kind to the scheduler
done
done
done
done
