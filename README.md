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
modify the workflow.ini file to source the necessary programs, sequencing data, and project location and run with:
```bash
bash meteor_pipeline.sh
```
