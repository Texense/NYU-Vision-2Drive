#!/bin/bash
##SBATCH --partition=cs
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=1:00:00
#SBATCH --mem=30GB
#SBATCH --mail-type=END
#SBATCH --mail-user=zx555@nyu.edu

module purge
module load matlab/2020b

cd /scratch/$USER/NYU-Vision-2Drive
echo "${SampleInd}" 
matlab -r "Paper3_ReadDataDriveHPC_L6(${SampleInd})"








