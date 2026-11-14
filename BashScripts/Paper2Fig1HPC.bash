#!/bin/bash
##SBATCH --partition=cs
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=47
#SBATCH --time=50:00:00
#SBATCH --mem=128GB
#SBATCH --job-name=P2F1
#SBATCH --mail-type=END
#SBATCH --mail-user=zx555@nyu.edu
#SBATCH --output=P2F1.out

module purge
module load matlab/2020b

cd /scratch/$USER/NYU-Vision-2Drive
matlab -r "Paper2Fig1HPC"








