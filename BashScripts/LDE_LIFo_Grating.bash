#!/bin/bash
##SBATCH --partition=cs
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=47
#SBATCH --time=50:00:00
#SBATCH --mem=128GB
##SBATCH --job-name=Run20Panel
#SBATCH --mail-type=END
#SBATCH --mail-user=zx555@nyu.edu
##SBATCH --output=%j_Run1_Panel%a.out

module purge
module load matlab/2020b

cd /scratch/$USER/NYU-Vision-2Drive
echo "${InputCtgr}"
matlab -r "LIFoLDEComput_Grating(${InputCtgr})"








