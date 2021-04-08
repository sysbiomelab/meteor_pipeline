#!/bin/bash -l
#SBATCH --account=snic2020-5-222
#SBATCH --partition=core
#SBATCH --ntasks=10
#SBATCH --time=12:00:00
#SBATCH --job-name=METEOR_run_batch
#SBATCH --mail-user=zn.tportlock@gmail.com
#SBATCH --mail-type=ALL
set -a

function Run {
	echo "...$(date): $1 - begin"
	$@ \
	&& (echo "...$(date): $1 - done"; echo "") \
	|| (echo "...$(date): $1 - failed"; echo ""; exit 1)
}
function Parse_variables {
	v_downstream_dir="$v_project_dir/Downstream"
	v_project_dir=$TMPDIR/$sampleId
	v_workdir="${v_project_dir}/working"
	v_fastqgz1=$(readlink -f ${fastqgzs[0]})
	v_fastqgz2=$(readlink -f ${fastqgzs[1]})
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
	mkdir -p ${v_workdir}
}
function Decompress {
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
		-o ${sampleId} ${v_project_dir}/${catalog_type}/mapping/${sampleId}/${sampleId}_${meteor_counting_prefix_name}_gene_profile/census.dat \
	&& rm -r ${v_project_dir}/${catalog_type}/mapping/${sampleId} \
	|| return 1
}
function PrepareReports {
	inFile=$v_downstream_dir/$1.csv
	outFile=$v_downstream_dir/$1.final.csv
	cat $v_project_dir/$v_catalog_type/profiles/*$1.csv > $inFile
	head -1 $inFile > ${outFile}.header
	cat $inFile | grep -v sample > ${outFile}.body
	cat ${outFile}.header ${outFile}.body > ${outFile}
	rm ${inFile} ${outFile}.header ${outFile}.body
}
function PrepareGCT {
	inFile=$v_downstream_dir/merged.tsv
	outFile=$v_downstream_dir/merged.final.tsv
	paste $v_project_dir/$v_catalog_type/profiles/*.tsv > $inFile
	width=$(head -1 $inFile | awk '{print NF}')
	echo $width
	cat $inFile | cut -f1 | sed 's/\#id_fragment/gene_id/g' > ${outFile}.gene
	cat $inFile | awk -v width="$width" 'BEGIN{OFS="\t"}{s="";for(i=2;i<=width;i=i+2){if (i!=width)s=s $i "\t"; if (i==width) s=s $i}; print s}' > ${outFile}.expr
	paste ${outFile}.gene ${outFile}.expr > ${outFile}
	rm ${inFile} ${outFile}.gene ${outFile}.expr
}
function SaveGCT {
	cd $v_downstream_dir
	Rscript $Rdir/save.gct.r  \
		merged.final.tsv \
		merged.final \
		. \
	|| return 1
}
function Normalize {
	cd $v_downstream_dir
	Rscript $Rdir/get.norm.downsize.r \
		merged.final.RData \
		merged.final \
		. \
		. \
	|| return 1
}
function GetMGS {
	cd $v_downstream_dir
	Rscript $Rdir/get.mgs.from.norm.r \
		merged.final.norm.10M.RData \
		merged.final \
		. \
		. \
	|| return 1
}

Main() {
	sampleId=("$1")
	fastqgzs+=("$2")
	fastqgzs+=("$3")

	Run Parse_variables &&
	Run Init &&
	Run Decompress &&
	Run Trim &&
	Run Import &&
	Run Map_reads &&
	Run Quantify
}
Downstream() {
	v_project_dir=$(readlink -f $project_dir_rel)
	v_downstream_dir="$v_project_dir/Downstream"
	mkdir -p $v_downstream_dir

	Run PrepareReports counting_report &&
	Run PrepareReports extended_counting_report &&
	Run PrepareGCT &&
	Run SaveGCT &&
	Run Normalize &&
	Run GetMGS 
}

# Load modules
module load bioinfo-tools
module load ruby/2.6.2
module load AlienTrimmer/0.4.0
module load bowtie2/2.3.4.1
module load gnuparallel/20180822

# Load ini file
ini_file=$1
source $ini_file > /dev/null 2>&1
cat $ini_file

# Run meteor
sr="\
srun \
--account=snic2020-5-222 \
--partition=core \
--ntasks=5 \
--time=12:00:00 \
--job-name=METEOR_run \
--output=/proj/uppstore2019028/projects/metagenome/theo/logs/slurm_%j.log\
"
parallel -j 6 $sr "Main {} $seq_data_dir/{}$forward_identifier $seq_data_dir/{}$reverse_identifier ; rsync -aurvP --remove-source-files $TMPDIR/{}/ $project_dir_rel" ::: $samples

# Run the downstream analysis
$sr Downstream
