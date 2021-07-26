#!/bin/bash -le
#SBATCH --job-name=meteor
#SBATCH --ntasks=10
#SBATCH --partition=shared
#SBATCH --mem=20G
#SBATCH --time=1-00:00:00

function Run {
	echo "...$(date): $1 - begin"; echo ""
	$@ \
	&& (echo "...$(date): $1 - done") \
	|| (echo "...$(date): $1 - failed"; return 1)
}
function Parse_variables {
	v_sampleId=$(basename $sample)
	v_project_dir="/scratch/users/k1809704/$v_sampleId"
	v_ini_file=$v_project_dir/tmpini.ini
	sed "s|meteor.reference.dir=.*|meteor.reference.dir=$v_project_dir/reference|g" $ini_file > $v_inifile
	source $v_ini_file > /dev/null 2>&1

	v_prefix=$( grep "meteor.counting.prefix.name" $ini_file | sed "s/^.*=//g" )
	v_workdir="${v_project_dir}/working"
	v_refdir="${v_project_dir}/reference"
	v_fastqgz1="$(readlink -f $seq_data_dir/${sample}${forward_identifier})"
	v_fastqgz2="$(readlink -f $seq_data_dir/${sample}${reverse_identifier})"
	v_final1="${v_workdir}/${v_sampleId}.1.fastq"
	v_final2="${v_workdir}/${v_sampleId}.2.fastq"
	v_sampledir="${v_project_dir}/${catalog_type}/sample/${v_sampleId}"
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
	cp $trimFasta $v_project_dir
}
function Trim {
	echo $v_project_dir/$(basename $trimFasta)
	java -jar ${ALIEN_TRIMMER} \
		-k 10 -l 45 -m 5 -p 40 -q 20 \
		-1 $v_workdir/$(basename ${v_fastqgz1}) \
		-2 $v_workdir/$(basename ${v_fastqgz2}) \
		-a $v_project_dir/$(basename $trimFasta) \
		-o $v_workdir/${v_sampleId} \
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
		-m "${v_sampleId}*" \
	|| return 1
}
function Map_reads {
	readlink -f $v_ini_file
	ruby ${meteor_rep}/meteor-pipeline/meteor.rb \
		-w ${v_ini_file} \
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
		-w ${v_ini_file} \
		-o ${v_sampleId} ${v_project_dir}/${catalog_type}/mapping/${v_sampleId}/${v_sampleId}_${v_prefix}_gene_profile/census.dat \
	&& rm -r ${v_project_dir}/${catalog_type}/mapping/${v_sampleId} \
	|| return 1
}
function Recover {
	rm $v_project_dir/$(basename $trimFasta)
	rm -r ${v_workdir}
	rm -r ${v_refdir}
	rm $v_ini_file
	rsync -aurvP --remove-source-files $v_project_dir/ $project_dir_rel
}

Main() {
	Run Parse_variables &&
	Run Init &&
	Run Send &&
	Run Trim &&
	Run Import &&
	Run Map_reads &&
	Run Quantify &&
	Run Recover
}

# Load modules
echo "...$(date): - load modules"
module load apps/bowtie2
module load devtools/ruby
module load apps/openjdk
echo "...$(date): - done"; echo "" 

# Load ini file
echo "...$(date): - load ini file"
ini_file=$1
source $ini_file > /dev/null 2>&1
cat $ini_file
echo "...$(date): - done"; echo "" 

echo "...$(date): - begin running script"
cat $0
echo ""

# Run
Main
