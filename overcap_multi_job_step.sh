#!/bin/zsh
#SBATCH --job-name=my_job_1
#SBATCH --array=1-4
#SBATCH --output=logs.out
#SBATCH --error=logs.err
#SBATCH --open-mode=append
#SBATCH --gres gpu:1
#SBATCH -c 7
#SBATCH --partition=overcap
#SBATCH --requeue
#SBATCH --signal=B:USR1@600

# "--signal=B:USR1@600" sends a signal to the job _step_ 600 seconds before its termination time limit.
# The "B:" prefix makes it send the signal only to this batch shell process.
# It has 600 seconds to do so in this example, otherwise it is forcibly killed

set -e

sb_handler() {
	echo "SBATCH signal handler started at $(date)";
	kill -s USR1 ${PID}; # Send USR1 signal to child process
	echo "SBATCH signal handler waiting at $(date)...";
	wait "${PID}";
	echo "SBATCH signal handler ended at $(date)!";
}
trap 'sb_handler' USR1

echo "SBATCH script start at: $(date)"
echo "slurm job id: $SLURM_JOB_ID"
echo "node: $SLURM_NODELIST"
echo "cuda: $CUDA_VISIBLE_DEVICES"
echo "slurm array_task_id: $SLURM_ARRAY_TASK_ID"

# Launch python script in background, grab its PID, then wait
srun zsh python_job_array.sh $SLURM_ARRAY_TASK_ID &

PID="$!"
echo "PID of python job array process: ${PID}"
wait ${PID}

echo 'SBATCH script completed!'
