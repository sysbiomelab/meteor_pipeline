#!/bin/bash -l
#SBATCH --account=snic2020-5-222
#SBATCH --partition=core
#SBATCH --ntasks=10
#SBATCH --time=12:00:00
#SBATCH --job-name=FMT_batch_prepare
#SBATCH --mail-user=zn.tportlock@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/proj/uppstore2019028/projects/metagenome/theo/logs/slurm_%j.log 

### Each run requires 10 hours and 10 cores/jobs/tasks to complete

module load gnuparallel/20180822

meteor="/proj/uppstore2019028/projects/metagenome/theo/newscripts/meteor/meteor.sh"
project="/proj/snic2020-6-153/delivery03711/FMT.gut.project"
seq_data_dir="/proj/snic2020-6-153/delivery03711"

# First argument is a file that contains the sample names
samples="$1"
parallel -j 3 " \
	$meteor \
		-f $samples/{}_1.fastq.gz \
		-f $samples/{}_2.fastq.gz \
		-p $TMPDIR/{} \
		-s illumina \
		-c gut_catalog \
	&& \
		rsync -aurvP --remove-source-files $TMPDIR/{}/ $project" \
:::: $samples
