#!/bin/bash
#SBATCH -A snic2020-5-222
#SBATCH -p core
#SBATCH -n 17
#SBATCH -t 15:00:00
#SBATCH -J FMT_momr
#SBATCH --mail-user zn.tportlock@gmail.com
#SBATCH --mail-type=ALL

projDir="/crex/proj/uppstore2019028/projects/metagenome/theo/delivery03711/FMT.gut.project"
addressToSh="/crex/proj/uppstore2019028/projects/metagenome/theo/newscripts/downstream"


$addressToSh/downstream.sh \
	-p $projDir \
	-c "gut_catalog"
