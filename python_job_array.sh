#!/bin/zsh

# This script takes a job array ID (from $SLURM_ARRAY_TASK_ID)
# as its first argument (stored in $1)

echo "PYTHON script start at: $(date)"
echo "slurm array_task_id: $SLURM_ARRAY_TASK_ID"

py_handler() {
	echo "Handler started at $(date)";
	echo "Handler PIDARRAY: ${PIDARRAY}";
	# Relay USR1 signal to all background child processes running
	# on current allocated slurm job
	kill -s USR1 ${PIDARRAY};
	echo "Handler ended at date $(date)";
}

trap 'py_handler' USR1

# Collect PIDs of all child processes running parallel
# on the same allocated slurm job in the following array.
PIDARRAY=()

if [ $1 -eq 1 ]; then
	# Job 1 and Job 2 belong to first job array i.e. they are
	# parallel job steps which share the allocated slurm resources.
	echo "Starting job array $1";

	# Job 1
	python -u -m overcap_example.train_cifar10 &
	PIDARRAY+=($!) # Append above process' PID to PIDARRAY

	# Job 2
	python -u -m overcap_example.train_cifar10 &
	PIDARRAY+=($!)

elif [ $1 -eq 2 ]; then
	echo "Starting job array $1";

	# Job 3
	python -u -m overcap_example.train_cifar10 &
	PIDARRAY+=($!)

	# Job 4
	python -u -m overcap_example.train_cifar10 &
	PIDARRAY+=($!)
fi

echo "PID List for job array $1: ${PIDARRAY}"
wait

echo 'PYTHON script completed!'
