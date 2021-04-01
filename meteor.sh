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
	|| (echo "...$(date): $1 - failed"; echo ""; exit 1)
}
function Load_modules {
	module load bioinfo-tools
	module load ruby/2.6.2
	module load AlienTrimmer/0.4.0
	module load bowtie2/2.3.4.1
}
function Parse_variables {
	cat $ini_file
	source $ini_file
	project_dir=$(readlink -f $project_dir_rel)
	fastqgz1=$(readlink -f ${fastqgzs[0]})
	fastqgz2=$(readlink -f ${fastqgzs[1]})
	sampleId=$(printf "%s\n%s\n" "$(basename $fastqgz1 .gz)" "$(basename $fastqgz2 .gz)" \
	| sed -e 'N;s/^\(.*\).*\n\1.*$/\1/'
	tempdir=${project_dir}/${sampleId}
	fastqgz1_unzip="${tempdir}/$(basename $fastqgz1 .gz).unzipped"
	fastqgz2_unzip="${tempdir}/$(basename $fastqgz2 .gz).unzipped"
	trimmedS="${tempdir}/${sampleId}.trimmed.s.fastq"
	final1="${tempdir}/${sampleId}_1.fastq"
	final2="${tempdir}/${sampleId}_2.fastq"
	sampledir=${project_dir}/${catalog_type}/sample/${sampleId}

	#just to test
	echo $project_dir
}
function Init {
	mkdir -p ${project_dir}/${catalog_type}/{sample,mapping,profiles}
}
function Prepare {
	mkdir -p ${tempdir}
	cp $fastqgz1 ${tempdir}/$fastqgz1 & pid1=$!
	cp $fastqgz2 ${tempdir}/$fastqgz2 & pid2=$!
	trap "kill -2 $pid1 $pid2" SIGINT
	wait
}
function Decompress {
	mkdir -p ${tempdir}
	zcat ${tempdir}/$fastqgz1 > $fastqgz1_unzip & pid1=$!
	zcat ${tempdir}/$fastqgz2 > $fastqgz2_unzip & pid2=$!
	trap "kill -2 $pid1 $pid2" SIGINT
	wait
}
function Trim {
	[[ -f $fastqgz1_unzip && -f $fastqgz2_unzip ]] \
	|| (echo "zip file not found" ; return 1 )
	java -jar ${ALIEN_TRIMMER}/AlienTrimmer.jar \
		-k 10 -l 45 -m 5 -p 40 -q 20 \
		-if ${fastqgz1_unzip} -ir ${fastqgz2_unzip} -c ${trimFasta} \
		-of ${final1} -or ${final2} -os ${trimmedS} \
	|| return 1
}
function Import {
	[[ -f $final1 && -f $final2 ]] \
	|| (echo "trimmed files not found" ; return 1 )
	mv ${final1} ${final2} ${project_dir}/${catalog_type}/sample &&
	rm -r ${tempdir}
	ruby ${meteorImportScript} \
		-i ${project_dir}/${catalog_type}/sample \
		-p ${catalog_type} \
		-t ${seq_platform} \
		-m "${sampleId}*" \
	|| return 1
}
function Map_reads {
	ruby ${meteor}/meteor.rb \
		-w ${ini_file} \
		-i ${sampledir} \
		-p ${project_dir}/${catalog_type} \
		-o mapping \
	|| return 1
}
function Quantify {
	${meteor}/meteor-profiler \
		-p ${project_dir}/${catalog_type} \
		-f ${project_dir}/${catalog_type}/profiles \
		-t smart_shared_reads \
		-w ${ini_file} \
		-o ${sampleId} ${project_dir}/${catalog_type}/mapping/${sampleId}/${sampleId}_vs_hs_10_4_igc2_id95_rmHost_id95_gene_profile/census.dat \
	&& rm -r ${project_dir}/${catalog_type}/mapping/${sampleId} \
	|| return 1
}
while getopts 'f:i:' flag; do
	case $flag in
		f) fastqgzs+=("${OPTARG}") ;;
		i) ini_file="${OPTARG}" ;;
		*) Help ; exit 1 ;;
		:) Help ; exit 1
	esac
done
Run Parse_variables
Run Load_modules
Run Init
Run Prepare
#Run Decompress &&
#Run Trim &&
#Run Import &&
#Run Map_reads &&
#Run Quantify
