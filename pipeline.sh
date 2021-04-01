#!/bin/bash -l
jid=$(sbatch meteor_wrapper.sh)
sbatch --dependency=afterok:$jid downstream_wrapper.sh
