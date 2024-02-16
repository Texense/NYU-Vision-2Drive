#!/bin/bash
##SBATCH --partition=cs
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=10:00:00
#SBATCH --mem=30GB
#SBATCH --mail-type=END
#SBATCH --mail-user=zx555@nyu.edu

module purge
module load matlab/2020b

cd /scratch/$USER/NYU-Vision-2Drive
echo "${Grating},${SampleInd}" 
matlab -r "Paper3_TestL6ShapeDriveHPC_Final(${Grating},${SampleInd})"








