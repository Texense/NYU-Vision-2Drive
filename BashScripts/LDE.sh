for InputCtgr in $(seq 1 3); do

#
echo "${InputCtgr}"
export InputCtgr
#
sbatch -o LDE${InputCtgr}.stdout.txt \
       -e LDE${InputCtgr}.stdout.txt \
       --job-name=LDE_${InputCtgr} \
       LDE.bash
#
sleep 1 # pause to be kind to the scheduler
done
