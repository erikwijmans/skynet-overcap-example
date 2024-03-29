#!/bin/bash
#SBATCH --job-name=cifar10-overcap
#SBATCH --output=logs.out
#SBATCH --error=logs.err
#SBATCH --gpus 1
#SBATCH --partition=short
#SBATCH --signal=USR1@300
#SBATCH --requeue
#SBATCH --account=overcap

# "--signal=USR1@300" sends a signal to the job _step_ when it needs to exit.
# It has 5 minutes to do so, otherwise it is forcibly killed

# This srun is critical!  The signal won't be sent correctly otherwise
srun python -u -m overcap_example.train_cifar10
