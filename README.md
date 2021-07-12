# METEOR pipeline

## Description
A wrapper for the automation and parallelisation of METEOR and its downstream analysis on a HPC cluster that is managed by a slurm scheduler

## Requirements
It is required that the machine that runs this code has installed:
* METEOR
* ruby
* Slurm
* R
Your sequences must be paired end, illumina reads.

## Installation
Clone the METEOR repository with 
git clone https://forgemia.inra.fr/metagenopolis/meteor.git

Clone the ALIENTRIMMER repository with 
git clone https://gitlab.pasteur.fr/GIPhy/AlienTrimmer.git

Download ALIENTRIMMER illumina contaminents
wget https://gitlab.pasteur.fr/aghozlan/shaman_bioblend/-/raw/18a17dbb44cece4a8320cce8184adb9966583aaa/alienTrimmerPF8contaminants.fasta?inline=false

Download the gene catalogs that you want to run your samples against (e.g. igc2)

Use the reference importer...

Download the corresponding MSP catalog (e.g. https://data.inrae.fr/dataset.xhtml?persistentId=doi:10.15454/FLANUP)

## Runtime
ensure that the wrapper script has the slurm configurations that you require. As a rule of thumb, each sbatch command should run for 12 hrs X number of samples ran at once + 12 hrs
modify the workflow.ini file (without spaces) to source the necessary programs, sequencing data, and project location and run with:
```bash
sbatch meteor_wrapper.sh gut_msp_pipeline.ini
```
