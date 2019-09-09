# skynet-overcap-example

In order to use more GPUs than a give lab has, you can submit to with `--qos=overcap`.  This will make the job interruptible however!

Interruptiple jobs require a slight amount of extra overhead.  This example shows how I like to manager interruptible jobs.  Note that
exact reproducibility is very, very difficult with interruptible jobs and this example does not seek to cover exact reproducibility.  I
have never seen interruption harm approximate reproducibility (for instance, getting very similar accuracy in supervised learning) however.


## Setup

Make a folder called `interruptible_states` in `/srv/share<id>/<user_name>` and then symlink it to `${HOME}/.interrupted_states`.  This is where
the state of a job will be saved to when it is interrupted.

## Running

To run the job, simply do `sbatch overcap_batch.sh`.  Note that interruptible jobs **must** be submitted as batch jobs.


## Debugging your interrupt logic

There are two ways I like to debug my interrupt logic.  You can simulate the interrupt signal being sent
with `scancel <job_id> --signal SIGUSR1`.  This can also be a great way to interrupt jobs that are normally
uninterruptible  to free GPUs for a labmate :)

However, the best way to debug it is to submit the job
with a time-limit of 11 minutes, i.e. `time=11:00`.  `--signal=USR1@600` will also cause SLURM to send
`SIGUSR1` when the jobs has 10 minutes (600 seconds) of runtime left. As far as SLURM as concerned,
interruption due to timelimit and overcap are exactly the same!
