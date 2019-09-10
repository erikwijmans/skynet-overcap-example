# skynet-overcap-example

In order to use more GPUs than a give lab has, you can submit to with `--qos=overcap`.  This will make the job interruptible however!


Interruptible jobs require some amount of extra overhead.  This example shows how I like to manage interruptible jobs.  Note that
exact reproducibility is very, very difficult with interruptible jobs and this example does not seek to cover exact reproducibility.  Note that I
have never seen interruption harm approximate reproducibility (for instance, getting very similar accuracy in supervised learning).

## Setup

Make a folder called `interrupted_states` in one of your `/srv/share` folders, i.e. `/srv/share3/<user_name>`, and symlink it to `${HOME}/.interrupted_states`.  This is where
the state of a job will be saved to when it is interrupted and retrieved from when it starts up again.

## Running

To run the job, simply do `sbatch overcap_batch.sh`.  Note that interruptible jobs **must** be submitted as batch jobs.


## Debugging interrupt/requeue logic

There are two ways I like to debug this logic.  You can simulate the interrupt signal being sent
with `scancel <job_id> --signal USR1`.  This can also be a great way to interrupt jobs that are normally
uninterruptible to free GPUs for a labmate :)

However, the best way to debug it is to submit the job
with a time-limit of 11 minutes, i.e. `--time=11:00`.  `--signal=USR1@600` will also cause SLURM to send
`SIGUSR1` when the jobs has 10 minutes (600 seconds) of runtime left. As far as SLURM as concerned,
interruption due to timelimit and overcap preemption are exactly the same!
