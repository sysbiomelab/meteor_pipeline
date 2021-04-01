#!/bin/bash -l
#SBATCH --account=snic2020-5-222
#SBATCH --partition=core
#SBATCH --ntasks=10
#SBATCH --time=12:00:00
#SBATCH --job-name=FMT_batch_prepare
#SBATCH --mail-user=zn.tportlock@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/proj/uppstore2019028/projects/metagenome/theo/logs/slurm_%j.log 
set -a

function Run {
	echo "...$(date): $1 - begin"
	$@ \
	&& (echo "...$(date): $1 - done"; echo "") \
	|| (echo "...$(date): $1 - failed"; echo ""; exit 1)
}
function Parse_variables {
	v_project_dir=$TMPDIR/$sampleId
	v_fastqgz1=$(readlink -f ${fastqgzs[0]})
	v_fastqgz2=$(readlink -f ${fastqgzs[1]})
	v_workdir="${v_project_dir}/working"
	v_fastqgz1_unzip="${v_workdir}/$(basename $v_fastqgz1 .gz).unzipped"
	v_fastqgz2_unzip="${v_workdir}/$(basename $v_fastqgz2 .gz).unzipped"
	v_trimmedS="${v_workdir}/${sampleId}.trimmed.s.fastq"
	v_final1="${v_workdir}/${sampleId}_1.fastq"
	v_final2="${v_workdir}/${sampleId}_2.fastq"
	v_sampledir=${v_project_dir}/${catalog_type}/sample/${sampleId}
	vars=$(compgen -A variable | grep "^v_.*")
	for var in ${vars}; do echo "${var}=${!var}"; done
	for var in ${vars}; do if [[ -z "${!var}" ]]; then echo "missing argument ${var}" ; return 1 ; fi ; done
}
function Init {
	mkdir -p ${v_project_dir}/${catalog_type}/{sample,mapping,profiles}
}
function Prepare {
	mkdir -p ${v_workdir}
	cp $v_fastqgz1 ${v_workdir} & pid1=$!
	cp $v_fastqgz2 ${v_workdir} & pid2=$!
	trap "kill -2 $pid1 $pid2" SIGINT
	wait
}
function Decompress {
	mkdir -p ${v_workdir}
	zcat ${v_workdir}/$v_fastqgz1 > $v_fastqgz1_unzip & pid1=$!
	zcat ${v_workdir}/$v_fastqgz2 > $v_fastqgz2_unzip & pid2=$!
	trap "kill -2 $pid1 $pid2" SIGINT
	wait
}
function Trim {
	[[ -f $v_fastqgz1_unzip && -f $v_fastqgz2_unzip ]] \
	|| (echo "zip file not found" ; return 1 )
	java -jar ${ALIEN_TRIMMER}/AlienTrimmer.jar \
		-k 10 -l 45 -m 5 -p 40 -q 20 \
		-if ${v_fastqgz1_unzip} -ir ${v_fastqgz2_unzip} -c ${trimFasta} \
		-of ${v_final1} -or ${v_final2} -os ${v_trimmedS} \
	|| return 1
}
function Import {
	[[ -f $v_final1 && -f $v_final2 ]] \
	|| (echo "trimmed files not found" ; return 1 )
	mv ${v_final1} ${v_final2} ${v_project_dir}/${catalog_type}/sample &&
	rm -r ${v_workdir}
	ruby ${meteorImportScript} \
		-i ${v_project_dir}/${catalog_type}/sample \
		-p ${catalog_type} \
		-t ${seq_platform} \
		-m "${sampleId}*" \
	|| return 1
}
function Map_reads {
	ruby ${meteor}/meteor.rb \
		-w ${ini_file} \
		-i ${v_sampledir} \
		-p ${v_project_dir}/${catalog_type} \
		-o mapping \
	|| return 1
}
function Quantify {
	${meteor}/meteor-profiler \
		-p ${v_project_dir}/${catalog_type} \
		-f ${v_project_dir}/${catalog_type}/profiles \
		-t smart_shared_reads \
		-w ${ini_file} \
		-o ${sampleId} ${v_project_dir}/${catalog_type}/mapping/${sampleId}/${sampleId}_vs_hs_10_4_igc2_id95_rmHost_id95_gene_profile/census.dat \
	&& rm -r ${v_project_dir}/${catalog_type}/mapping/${sampleId} \
	|| return 1
}
Main() {
	sampleId=("$1")
	fastqgzs+=("$2")
	fastqgzs+=("$3")

	Run Parse_variables &&
	Run Init &&
	Run Prepare &&
	Run Decompress &&
	Run Trim &&
	Run Import &&
	Run Map_reads &&
	Run Quantify
}

module load bioinfo-tools
module load ruby/2.6.2
module load AlienTrimmer/0.4.0
module load bowtie2/2.3.4.1
module load gnuparallel/20180822

ini_file="gut_msp_pipeline.ini"
source $ini_file > /dev/null 2>&1
cat $ini_file

parallel -j 3 "Main {} $seq_data_dir/{}$forward_identifier $seq_data_dir/{}$reverse_identifier && rsync -aurvP --remove-source-files $TMPDIR/{}/ $project_dir_rel" ::: $samples
