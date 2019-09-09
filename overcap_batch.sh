#!/bin/bash
#SBATCH --job-name=cifar10-overcap
#SBATCH --output=logs.out
#SBATCH --gres gpu:1
#SBATCH --nodes 1
#SBATCH --partition=dev
#SBATCH --time=11:00
#SBATCH --signal=USR1@600
#SBATCH -c 10

# "--signal=USR1@600" sends a signal to the job _step_ when it needs to exit.  
# It has 10 minutes to do so, otherwise it is forcability killed

# This srun is critical!  The signal won't be sent correctly otherwise
srun python -u -m overcap_example.train_cifar10
