#!/bin/bash
##SBATCH --partition=cs
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=3:00:00
#SBATCH --mem=32GB
##SBATCH --job-name=Run20Panel
#SBATCH --mail-type=END
#SBATCH --mail-user=zx555@nyu.edu
##SBATCH --output=%j_Run1_Panel%a.out

module purge
module load matlab/2022a

cd /scratch/$USER/NYU-Vision-2Drive
echo "${RadiusInd},${SampleSize},${minId},${maxId}" 
matlab -r "HPCICTest_Paper3_read(${RadiusInd},${SampleSize},${minId},${maxId})"








