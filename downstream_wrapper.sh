#!/bin/bash -l
#SBATCH --account=snic2021-5-248
#SBATCH -p node -n 1
##SBATCH --partition=core
##SBATCH --ntasks=10
#SBATCH --time=1-00:00:00
#SBATCH --job-name=Downstrm
#SBATCH --mail-user=zn.tportlock@gmail.com
#SBATCH --mail-type=ALL
##SBATCH --output=/proj/uppstore2019028/projects/metagenome/theo/newscripts/meteor/logs/%j 

function Run {
	echo "...$(date): $1 - begin"; echo ""
	$@ \
	&& (echo "...$(date): $1 - done"; echo "") \
	|| (echo "...$(date): $1 - failed"; echo ""; return 1)
}
function Parse_variables {
	v_project_dir=$project_dir_rel
	v_downstream_dir="$v_project_dir/Downstream"
	v_ref_name=$( grep "meteor.reference.name" $ini_file | head -n 1 | sed "s/^.*=//g" )
	vars="$(compgen -A variable | grep "^v_.*")"
	for var in ${vars}; do echo "${var}=${!var}"; done
	for var in ${vars}; do if [[ -z "${!var}" ]]; then echo "missing argument ${var}" ; return 1 ; fi ; done
}
function Init {
	mkdir -p $v_downstream_dir
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
	inFile=$v_downstream_dir/pre_gct.tsv
	outFile=$v_downstream_dir/gct.tsv
	paste $v_project_dir/$catalog_type/profiles/*.tsv > $inFile
	width=$(head -1 $inFile | awk '{print NF}')
	echo $width
	cat $inFile | cut -f1 | sed 's/\#id_fragment/gene_id/g' > ${outFile}.gene
	cat $inFile | awk -v width="$width" 'BEGIN{OFS="\t"}{s="";for(i=2;i<=width;i=i+2){if (i!=width)s=s $i "\t"; if (i==width) s=s $i}; print s}' > ${outFile}.expr
	paste ${outFile}.gene ${outFile}.expr > ${outFile}
	rm ${inFile} ${outFile}.gene ${outFile}.expr
}
function GetMGS {
	echo "${reference_dir}/${v_ref_name}/database/${v_ref_name}_lite_annotation"
	Rscript $wrapper_dir/downstream.r \
		$v_downstream_dir/gct.tsv \
		$v_downstream_dir \
		${reference_dir}/${v_ref_name}/database/${v_ref_name}_lite_annotation \
		$msp_dir \
	|| return 1
}

Downstream() {
	Run Parse_variables &&
	Run Init &&
	#Run PrepareReports counting_report &&
	#Run PrepareReports extended_counting_report &&
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

# Run the downstream analysis
Downstream
