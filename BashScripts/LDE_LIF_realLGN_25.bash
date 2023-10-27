#!/bin/bash
##SBATCH --partition=cs
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=47
#SBATCH --time=10:00:00
#SBATCH --mem=64GB
#SBATCH --mail-type=END
#SBATCH --mail-user=zx555@nyu.edu
##SBATCH --output=%j_Run1_Panel%a.out

module purge
module load matlab/2022a

cd /scratch/$USER/NYU-Vision-2Drive
echo "${Angle},${LGNctgr},${L6ctgr},${lgnTF},${lgnSF},${L6Mapctgr},${FlagLargeDom}"  
matlab -r "LIFoLDEComput_Grating_25Func_RealLGN(${Angle},${LGNctgr},${L6ctgr},${lgnTF},${lgnSF},${L6Mapctgr},${FlagLargeDom})"


