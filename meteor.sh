#!/bin/bash -l

Help() {
	tput bold; echo 'Initialises, unzips, prepares, and runs METEOR'; tput sgr0
	echo '-f: first fastqz.gz file from paired end sequencing data'
	echo '-f: second fastqz.gz file from paired end sequencing data'
	echo '-p: directory for project (default=current_directory)'
	echo '-c: catalog type (default=catalog)'
	echo '-s: platform used to sequence data'
}

function Run {
	echo "...$(date): $1 - begin"
	$@ \
	&& (echo "...$(date): $1 - done"; echo "") \
	|| (echo "...$(date): $1 - failed"; echo "")
}

function Load_modules {
	module load bioinfo-tools
	module load ruby/2.6.2
	module load AlienTrimmer/0.4.0
	module load bowtie2/2.3.4.1
}

function Parse_variables {
	v_project_dir=$(readlink -f $v_project_dir_rel)
	v_fastqgz1=$(readlink -f ${fastqgzs[0]})
	v_fastqgz2=$(readlink -f ${fastqgzs[1]})
	v_sampleId=$(printf "%s\n%s\n" "$(basename $v_fastqgz1 .gz)" "$(basename $v_fastqgz2 .gz)" | sed -e 'N;s/^\(.*\).*\n\1.*$/\1/' -e "s/[^[:alnum:]]//g")
	v_tempdir=${v_project_dir}/${v_sampleId}
	v_fastqgz1_unzip="${v_tempdir}/$(basename $v_fastqgz1 .gz).unzipped"
	v_fastqgz2_unzip="${v_tempdir}/$(basename $v_fastqgz2 .gz).unzipped"
	v_trimmedS="${v_tempdir}/${v_sampleId}.trimmed.s.fastq"
	v_final1="${v_tempdir}/${v_sampleId}_1.fastq"
	v_final2="${v_tempdir}/${v_sampleId}_2.fastq"
	v_sampledir=${v_project_dir}/${v_catalog_type}/sample/${v_sampleId}
	v_trimFasta="/proj/uppstore2019028/projects/metagenome/alienTrimmerPF8contaminants.fasta"
	v_meteorImportScript="/proj/uppstore2019028/meteor.2019.11.04/MeteorImportFastq.rb"
	v_ini_file="/proj/uppstore2019028/projects/metagenome/gut_msp_pipeline.ini"
	v_reference="/proj/uppstore2019028/projects/metagenome/meteor.reference"
	v_meteor="/proj/uppstore2019028/projects/metagenome/software/meteor_linux_2019.11.04"
	vars=$(compgen -A variable | grep "^v_.*")
	for var in ${vars}; do echo "${var}=${!var}"; done
	for var in ${vars}; do if [[ -z "${!var}" ]]; then echo "missing argument ${var}" ; return 1 ; fi ; done
}

function Init {
	mkdir -p ${v_project_dir}/${v_catalog_type}/{sample,mapping,profiles}
}

function Decompress {
	mkdir -p ${v_tempdir}
	zcat $v_fastqgz1 > $v_fastqgz1_unzip & pid1=$!
	zcat $v_fastqgz2 > $v_fastqgz2_unzip & pid2=$!
	trap "kill -2 $pid1 $pid2" SIGINT
	wait
}

function Trim {
	[[ -f $v_fastqgz1_unzip && -f $v_fastqgz2_unzip ]] \
	|| (echo "zip file not found" ; return 1 )
	java -jar ${ALIEN_TRIMMER}/AlienTrimmer.jar \
		-k 10 -l 45 -m 5 -p 40 -q 20 \
		-if ${v_fastqgz1_unzip} -ir ${v_fastqgz2_unzip} -c ${v_trimFasta} \
		-of ${v_final1} -or ${v_final2} -os ${v_trimmedS} \
	|| return 1
}

function Import {
	[[ -f $v_final1 && -f $v_final2 ]] \
	|| (echo "trimmed files not found" ; return 1 )
	mv ${v_final1} ${v_final2} ${v_project_dir}/${v_catalog_type}/sample &&
	rm -r ${v_tempdir}
	ruby ${v_meteorImportScript} \
		-i ${v_project_dir}/${v_catalog_type}/sample \
		-p ${v_catalog_type} \
		-t ${v_seq_platform} \
		-m "${v_sampleId}*" \
	|| return 1
}

function Map_reads {
	ruby ${v_meteor}/meteor.rb \
		-w ${v_ini_file} \
		-i ${v_sampledir} \
		-p ${v_project_dir}/${v_catalog_type} \
		-o mapping \
	|| return 1
}

function Quantify {
	${v_meteor}/meteor-profiler \
		-p ${v_project_dir}/${v_catalog_type} \
		-f ${v_project_dir}/${v_catalog_type}/profiles \
		-t smart_shared_reads \
		-w ${v_ini_file} \
		-o ${v_sampleId} ${v_project_dir}/${v_catalog_type}/mapping/${v_sampleId}/${v_sampleId}_vs_hs_10_4_igc2_id95_rmHost_id95_gene_profile/census.dat \
	&& rm -r ${v_project_dir}/${v_catalog_type}/mapping/${v_sampleId} \
	|| return 1
}

while getopts 'f:p:c:s:' flag; do
	case $flag in
		f) fastqgzs+=("${OPTARG}") ;;
		p) v_project_dir_rel="${OPTARG}" ;;
		c) v_catalog_type="${OPTARG}" ;;
		s) v_seq_platform="${OPTARG}" ;;
		*) Help ; exit 1 ;;
		:) Help ; exit 1
	esac
done

Run Parse_variables &&
Run Load_modules &&
Run Init &&
Run Decompress &&
Run Trim &&
Run Import &&
Run Map_reads &&
Run Quantify
