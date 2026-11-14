for xE in $(seq 0 0.1 1); do
for xI in $(seq 0 0.1 1); do
#
echo "${xE},${xI}" 
export xE xI
#
sbatch -o TestXY_${xE}_${xI}.stdout.txt \
       -e TestXY_${xE}_${xI}.stdout.txt \
       --job-name=xE${xE}_xI${xI} \
       Test_xy.bash
#
sleep 1 # pause to be kind to the scheduler
done
done
