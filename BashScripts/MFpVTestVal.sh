mode=0
##for testVal in 0.5 1 1.5 2; do
for testVal in 0.2 0.15 0.1 0.05; do
#
echo "${mode} ${testVal}"
export mode testVal
#
sbatch -o MFpVTestVal${testVal}.stdout.txt \
       -e MFpVTestVal${testVal}.stdout.txt \
       --job-name=MFpV_${testVal} \
       MFpVTestVal.bash
#
sleep 1 # pause to be kind to the scheduler
done
