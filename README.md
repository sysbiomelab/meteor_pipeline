# METEOR pipeline

## Description
A wrapper for the automation and parallelisation of METEOR and its downstream analysis on a HPC cluster that is managed by a slurm scheduler

## Requirements
It is required that the machine that runs this code has installed:
* METEOR
* Slurm
* R

## Installation
None required, simply clone this repository

## Meteor_wrapper Runtime
* Ensure that the wrapper script has the slurm configurations that you require. As a rule of thumb, each sbatch meteor_wrapper command should run for 8 hrs. 
* modify the workflow.ini file (without spaces) to source the necessary programs, sequencing data, and project location
* run the meteor wrapper with:
```bash
sbatch meteor_wrapper.sh workflow.ini
```

If there are multiple samples for analysis then you must also:
* compile a list of all the samples from the reference of the directory containing the sequencing files (see all_samples)
* run the generate_inifiles.sh:
```bash
bash generate_inifiles.sh workflow.ini all_samples
```
* run the wrapper on all the files with:
```bash
bash run_inifiles.sh inifiles
```
