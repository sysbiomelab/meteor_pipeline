#!/bin/bash -l
#SBATCH --account=snic2021-5-248
#SBATCH --partition=core
#SBATCH --ntasks=10
#SBATCH --time=2-06:00:00
#SBATCH --job-name=METEOR
##SBATCH --output=%j 

function Run {
	echo "...$(date): $1 - begin"; echo ""
	$@ \
	&& (echo "...$(date): $1 - done") \
	|| (echo "...$(date): $1 - failed"; return 1)
}
function Parse_variables {
	sampleId=$(basename $sample .fastq.gz)
	v_project_dir="$TMPDIR"
	v_prefix=$( grep "meteor.counting.prefix.name" $ini_file | sed "s/^.*=//g" )
	v_workdir="${v_project_dir}/working"
	v_refdir="${v_project_dir}/reference"
	v_fastqgz1="$(readlink -f $seq_data_dir/${sample}${forward_identifier})"
	v_fastqgz2="$(readlink -f $seq_data_dir/${sample}${reverse_identifier})"
	v_fastqgz1_unzip="${v_workdir}/$(basename $v_fastqgz1 .gz).unzipped"
	v_fastqgz2_unzip="${v_workdir}/$(basename $v_fastqgz2 .gz).unzipped"
	v_trimmedS="${v_workdir}/${sampleId}.trimmed.s.fastq"
	v_final1="${v_workdir}/${sampleId}_1.fastq"
	v_final2="${v_workdir}/${sampleId}_2.fastq"
	v_sampledir="${v_project_dir}/${catalog_type}/sample/${sampleId}"
	vars="$(compgen -A variable | grep "^v_.*")"
	for var in ${vars}; do echo "${var}=${!var}"; done
	for var in ${vars}; do if [[ -z "${!var}" ]]; then echo "missing argument ${var}" ; return 1 ; fi ; done
}
function Init {
	mkdir -p ${v_project_dir}/${catalog_type}/{sample,mapping,profiles}
	mkdir -p ${v_workdir}
	mkdir -p ${v_refdir}
}
function Send {
	cp $v_fastqgz1 $v_workdir
	cp $v_fastqgz2 $v_workdir
	cp -r ${reference_dir}/* $v_refdir
	cp -r $trimFasta $v_project_dir
}
function Decompress {
	zcat ${v_workdir}/$(basename $v_fastqgz1) > $v_fastqgz1_unzip & pid1=$!
	zcat ${v_workdir}/$(basename $v_fastqgz2) > $v_fastqgz2_unzip & pid2=$!
	trap "kill -2 $pid1 $pid2" SIGINT
	wait
}
function Trim {
	[[ -f $v_fastqgz1_unzip && -f $v_fastqgz2_unzip ]] \
	|| (echo "zip file not found" ; return 1 )
	java -jar ${ALIEN_TRIMMER}/AlienTrimmer.jar \
		-k 10 -l 45 -m 5 -p 40 -q 20 \
		-if ${v_fastqgz1_unzip} -ir ${v_fastqgz2_unzip} -c $TMPDIR/$(basename $trimFasta) \
		-of ${v_final1} -or ${v_final2} -os ${v_trimmedS} \
	|| return 1
}
function Import {
	[[ -f $v_final1 && -f $v_final2 ]] \
	|| (echo "trimmed files not found" ; return 1 )
	mv ${v_final1} ${v_final2} ${v_project_dir}/${catalog_type}/sample &&
	rm -r ${v_workdir}
	ruby ${meteor_rep}/data_preparation_tools/MeteorImportFastq.rb \
		-i ${v_project_dir}/${catalog_type}/sample \
		-p ${catalog_type} \
		-t ${seq_platform} \
		-m "${sampleId}*" \
	|| return 1
}
function Map_reads {
	ruby ${meteor_rep}/meteor-pipeline/meteor.rb \
		-w ${ini_file} \
		-i ${v_sampledir} \
		-p ${v_project_dir}/${catalog_type} \
		-o mapping \
	|| return 1
}
function Quantify {
	${meteor_rep}/meteor-pipeline/src/build/meteor-profiler \
		-p ${v_project_dir}/${catalog_type} \
		-f ${v_project_dir}/${catalog_type}/profiles \
		-t smart_shared_reads \
		-w ${ini_file} \
		-o ${sampleId} ${v_project_dir}/${catalog_type}/mapping/${sampleId}/${sampleId}_${v_prefix}_gene_profile/census.dat \
	&& rm -r ${v_project_dir}/${catalog_type}/mapping/${sampleId} \
	|| return 1
}
function Recover {
	rm $TMPDIR/$(basename $trimFasta)
	rm -r ${v_workdir}
	rm -r ${v_refdir}
	rm $ini_file
	rsync -aurvP --remove-source-files $v_project_dir/ $project_dir_rel
}

Main() {
	Run Parse_variables &&
	Run Init &&
	Run Send &&
	Run Decompress &&
	Run Trim &&
	Run Import &&
	Run Map_reads &&
	Run Quantify &&
	Run Recover
}

echo "...$(date): - begin running script"
cat $0
echo ""

# Load modules
echo "...$(date): - load modules"
module load bioinfo-tools
module load ruby/2.6.2
module load AlienTrimmer/0.4.0
module load bowtie2/2.3.4.1
echo "...$(date): - done"; echo "" 

# Load ini file
echo "...$(date): - load ini file"
echo $TMPDIR/$(basename $1)
sed "s|meteor.reference.dir=.*|meteor.reference.dir=$TMPDIR/reference|g" $1 > $TMPDIR/$(basename $1)
ini_file=$TMPDIR/$(basename $1)
source $ini_file > /dev/null 2>&1
cat $ini_file
echo "...$(date): - done"; echo "" 

# Run
Main
