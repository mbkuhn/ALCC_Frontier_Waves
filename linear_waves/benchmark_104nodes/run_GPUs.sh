#!/bin/bash

#SBATCH --job-name=32x16_debug
#SBATCH --account=CFD162
#SBATCH --time=2:00:00
#SBATCH --nodes=104
#SBATCH --output=%x-%j.out
#SBATCH --mail-user=mkuhn@nrel.gov
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --exclusive
#SBATCH -q debug

# cancel other job
scancel 1636278

export rocm_version=5.4.3
export MPICH_GPU_SUPPORT_ENABLED=1

module purge
module load amd/${rocm_version}
module load craype-accel-amd-gfx90a
module load PrgEnv-amd
module load cray-mpich

#source /lustre/orion/cfd162/proj-shared/lcheung/spackbuilds/spack-manager.2/loadexawind.sh
source /lustre/orion/cfd162/proj-shared/lcheung/spackbuilds/spack-manager.jrood/loadexawind.sh

export LD_LIBRARY_PATH=/opt/rocm-${rocm_version}/llvm/lib/:$LD_LIBRARY_PATH
# export HIP_LAUNCH_BLOCKING=1

export FI_MR_CACHE_MONITOR=memhooks
export FI_CXI_RX_MATCH_MODE=software
export CONFFILE=ow_linear_maxlev2.inp

export TASKSPERNODE=8
export NTASKS=$((TASKSPERNODE*SLURM_JOB_NUM_NODES))

# # Get the latest restart dir
# unlink chkrestart
# chklast=`ls -1drt chk[0-9]*/ |tail -n1`
# ln -s $chklast chkrestart

cd $MEMBERWORK/cfd162/linear_waves
cp $HOME/scripts/linear_waves_frontier_benchmark/ow_linear_maxlev2.inp .
cp $HOME/scripts/linear_waves_frontier_benchmark/static_box2.refine .

srun -N $SLURM_JOB_NUM_NODES -n $NTASKS --ntasks-per-node=$TASKSPERNODE --gpu-bind=closest amr_wind $CONFFILE
