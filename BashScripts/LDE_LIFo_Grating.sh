for InputCtgr in $(seq 1 2); do

#
echo "${InputCtgr}"
export InputCtgr
#
sbatch -o LDE_LIFo${InputCtgr}.stdout.txt \
       -e LDE_LIFo${InputCtgr}.stdout.txt \
       --job-name=LDE_${InputCtgr} \
       LDE_LIFo_Grating.bash
#
sleep 1 # pause to be kind to the scheduler
done
