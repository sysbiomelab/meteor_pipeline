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

## Runtime
ensure that the wrapper script has the slurm configurations that you require. As a rule of thumb, each sbatch command should run for 5 hrs. 
modify the workflow.ini file (without spaces) to source the necessary programs, sequencing data, and project location and run with:
```bash
sbatch meteor_wrapper.sh gut_msp_pipeline.ini
```
