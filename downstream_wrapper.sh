#!/bin/bash
#SBATCH --account=snic2020-5-222
#SBATCH --partition=core
#SBATCH --ntasks=17
#SBATCH --time=12:00:00
#SBATCH --job-name=FMT_downstream
#SBATCH --mail-user zn.tportlock@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/proj/uppstore2019028/projects/metagenome/theo/logs/slurm_%j.log 

projDir="/proj/snic2020-6-153/delivery03711/FMT.gut.project"
Downstream="/crex/proj/uppstore2019028/projects/metagenome/theo/newscripts/meteor/downstream.sh"

$Downstream \
	-p $projDir \
	-c "gut_catalog"
