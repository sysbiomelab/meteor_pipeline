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
wget https://gitlab.pasteur.fr/aghozlan/shaman_bioblend/-/raw/18a17dbb44cece4a8320cce8184adb9966583aaa/alienTrimmerPF8contaminants.fasta

Download the gene catalogs that you want to run your samples against (e.g. igc2)

Use the reference importer...

Download the corresponding MSP catalog (e.g. https://data.inrae.fr/dataset.xhtml?persistentId=doi:10.15454/FLANUP for igc2 or https://data.inrae.fr/dataset.xhtml?persistentId=doi:10.15454/WQ4UTV for oral)

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
