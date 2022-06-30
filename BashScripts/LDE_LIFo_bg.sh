for FlagLargeDom in $(seq 1 3); do
#
echo "${FlagLargeDom}" 
export FlagLargeDom
#
sbatch -o LDE_bg_${FlagLargeDom}.stdout.txt \
       -e LDE_bg_${FlagLargeDom}.stdout.txt \
       --job-name=Bg_${FlagLargeDom} \
       LDE_LIFo_bg.bash
#
sleep 1 # pause to be kind to the scheduler
done
