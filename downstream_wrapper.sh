#!/bin/bash -l
#SBATCH --account=snic2021-5-248
#SBATCH --partition=core
#SBATCH --ntasks=10
#SBATCH --time=3-00:00:00
#SBATCH --job-name=Meteor
#SBATCH --mail-user=zn.tportlock@gmail.com
#SBATCH --mail-type=ALL
##SBATCH --output=/proj/uppstore2019028/projects/metagenome/theo/newscripts/meteor/logs/%j 

function Run {
	start=$(date +%m)
	echo "...$(date): $1 - begin"; echo ""
	$@ \
	&& (echo "...$(date): $1 - done"; echo "") \
	|| (echo "...$(date): $1 - failed"; echo "")
	end=$(date +%s)
	echo "...time taken: $((end-start))"; echo ""
}
function Parse_variables {
	v_project_dir="$TMPDIR"
	v_workdir="${v_project_dir}/working"
	v_refdir="${v_project_dir}/reference"
	v_fastqgz1="$(readlink -f ${fastqgzs[0]})"
	v_fastqgz2="$(readlink -f ${fastqgzs[1]})"
	v_fastqgz1_unzip="${v_workdir}/$(basename $v_fastqgz1 .gz).unzipped"
	v_fastqgz2_unzip="${v_workdir}/$(basename $v_fastqgz2 .gz).unzipped"
	v_trimmedS="${v_workdir}/${sampleId}.trimmed.s.fastq"
	v_final1="${v_workdir}/${sampleId}_1.fastq"
	v_final2="${v_workdir}/${sampleId}_2.fastq"
	v_sampledir="${v_project_dir}/${catalog_type}/sample/${sampleId}"
	v_downstream_dir="$v_project_dir/Downstream"
	vars="$(compgen -A variable | grep "^v_.*")"
	for var in ${vars}; do echo "${var}=${!var}"; done
	for var in ${vars}; do if [[ -z "${!var}" ]]; then echo "missing argument ${var}" ; return 1 ; fi ; done
}
function Init {
	mkdir -p ${v_project_dir}/${catalog_type}/{sample,mapping,profiles}
	mkdir -p ${v_workdir}
	mkdir -p ${v_refdir}
}
function PrepareReports {
	inFile=$v_downstream_dir/$1.csv
	outFile=$v_downstream_dir/$1.final.csv
	cat $v_project_dir/$catalog_type/profiles/*$1.csv > $inFile
	head -1 $inFile > ${outFile}.header
	cat $inFile | grep -v sample > ${outFile}.body
	cat ${outFile}.header ${outFile}.body > ${outFile}
	rm ${inFile} ${outFile}.header ${outFile}.body
}
function PrepareGCT {
	inFile=$v_downstream_dir/merged.tsv
	outFile=$v_downstream_dir/merged.final.tsv
	paste $v_project_dir/$catalog_type/profiles/*.tsv > $inFile
	width=$(head -1 $inFile | awk '{print NF}')
	echo $width
	cat $inFile | cut -f1 | sed 's/\#id_fragment/gene_id/g' > ${outFile}.gene
	cat $inFile | awk -v width="$width" 'BEGIN{OFS="\t"}{s="";for(i=2;i<=width;i=i+2){if (i!=width)s=s $i "\t"; if (i==width) s=s $i}; print s}' > ${outFile}.expr
	paste ${outFile}.gene ${outFile}.expr > ${outFile}
	rm ${inFile} ${outFile}.gene ${outFile}.expr
}
function SaveGCT {
	#cd $v_downstream_dir
	Rscript $Rdir/save.gct.r  \
		$v_downstream_dir/merged.final.tsv \
		merged.final \
		$v_downstream_dir \
	|| return 1
}
function Normalize {
	#cd $v_downstream_dir
	Rscript $Rdir/get.norm.downsize.r \
		$v_downstream_dir/merged.final.RData \
		merged.final \
		$v_downstream_dir \
		$v_downstream_dir \
	|| return 1
}
function GetMGS {
	Rscript $Rdir/get.oral.mgs.from.norm.r \
		$v_downstream_dir/merged.final.norm.10M.RData \
		merged.final \
		$v_downstream_dir \
		$v_downstream_dir \
	|| return 1
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

echo "...$(date): - begin running script"
cat $0
echo ""

# Load ini file
echo "...$(date): - load ini file"
ini_file=$1
source $ini_file > /dev/null 2>&1
cat $ini_file
echo "...$(date): - done"; echo "" 

# Load modules
echo "...$(date): - load modules"
module load bioinfo-tools
module load ruby/2.6.2
module load AlienTrimmer/0.4.0
module load bowtie2/2.3.4.1
echo "...$(date): - done"; echo "" 

# Run the downstream analysis
Downstream
