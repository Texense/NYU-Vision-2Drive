#!/bin/bash
##SBATCH --partition=cs
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=6:00:00
#SBATCH --mem=32GB
##SBATCH --job-name=Run20Panel
#SBATCH --mail-type=END
#SBATCH --mail-user=zx555@nyu.edu
##SBATCH --output=%j_Run1_Panel%a.out

module purge
module load matlab/2022b

cd /scratch/$USER/NYU-Vision-2Drive
echo "${BlockID},${NSample},${SaveID},${StepSize}" 
matlab -r "HPCGlobConvTest2_RAND_Paper3(${BlockID},${SaveID},${NSample},${StepSize})"








