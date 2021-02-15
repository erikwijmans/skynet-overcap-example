# skynet-overcap-example

In order to use more GPUs than a give lab has, you can submit with `--account=overcap --partition=overcap` (or `-A overcap -p overcap` for short).  This will make the job interruptible however!

Interruptible jobs require some amount of extra overhead.  This example shows how I like to manage interruptible jobs. 
Exact reproducibility is very, very difficult with interruptible jobs and this example does not seek to cover exact reproducibility.  Note that I
have never seen interruption harm approximate reproducibility (for instance, getting very similar accuracy in supervised learning).

## Setup

Make a folder called `interrupted_states` in one of your `/srv/share` folders, i.e. `/srv/share3/<user_name>`, and symlink it to `${HOME}/.interrupted_states`.  This is where
the state of a job will be saved to when it is interrupted and retrieved from when it starts up again.

## Running

To run the job, simply do `sbatch overcap_batch.sh`.  Note that interruptible jobs **must** be submitted as batch jobs.

## Debugging your interrupt logic

There are two ways I like to debug my interrupt logic.  You can simulate the interrupt signal being sent
with `scancel <job_id> --signal USR1`.  This can also be a great way to interrupt normal jobs
to free GPUs for a labmate :)

However, the best way to debug it is to submit the job
with a time-limit of 10 minutes, i.e. `time=10:00`.  `--signal=USR1@300` will also cause slurm to send
`SIGUSR1` when the jobs has 5 minutes (300 seconds) of runtime left. 


Above will test your interrupt due to timelimit reached, this is very similar to preemption due to overcap (and feasible to simulate)
but not precisely the same.  On preemption due to overcap, the job will simply be killed and then slurm will automatically requeue the job
(assuming `#SBATCH --requeue` is in the batch script).  In order to still have a state to resume from, you will need to save out the
state of the job periodically.


## Moving jobs between overcap and your lab's account

Jobs that are in queue can be moved either to overcap or back to your labs account. To move a job
to overcap that has job id `<job_id>`, run

```bash
scontrol update job <job_id> account=overcap qos=overcap partition=overcap
```

To move a job to your lab's account, you will first need to figure out your lab's account name and QOS.
This can be figured out as follows:

```bash
>  sacctmgr -P show assoc where user=$(whoami) format=Account,DefaultQOS
Account|Def QOS
overcap|overcap
cvmlp-lab|cvmlp-user-limits
```

So I am in `cvmlp-lab` and the QOS for my jobs is `cvmlp-user-limits`. Once you know your lab's account name,
you can move a job to it via

```bash
scontrol update job <job_id> account=cvmlp-lab qos=cvmlp-user-limits partition=short
```

Note that SLURM will not let you create an invalid job specification, but it may fail silently.
