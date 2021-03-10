#!/bin/bash -l

Help() {
	tput bold; echo 'Initialises, unzips, prepares, and runs METEOR'; tput sgr0
	echo '-p: directory for project (default=current_directory)'
	echo '-c: catalog type (default=catalog)'
}

function Run {
	echo "...$(date): $1 - begin"
	$@ \
	&& (echo "...$(date): $1 - done"; echo "") \
	|| (echo "...$(date): $1 - failed"; echo "")
}

function Parse_variables {
	v_project_dir=$(readlink -f $v_project_dir_rel)
	v_downstream_dir="$v_project_dir/Downstream"
	v_Rdir="/crex/proj/uppstore2019028/projects/metagenome/theo/newscripts/meteor/rscripts"

	vars=$(compgen -A variable | grep "^v_.*") 
	for var in ${vars}; do echo "${var}=${!var}"; done
	for var in ${vars}; do if [[ -z "${!var}" ]]; then echo "missing argument ${var}" ; return 1 ; fi ; done
}

function Init {
	mkdir -p $v_downstream_dir
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
	[[ -f $v_downstream_dir/merged.final.tsv ]] \
	|| (echo "GCT file not found" ; return 1 )
	cd $v_downstream_dir
	Rscript $v_Rdir/save.gct.r  \
		merged.final.tsv \
		merged.final \
		. \
	|| return 1
}

function Normalize {
	[[ -f $v_downstream_dir/merged.final.RData ]] \
	|| (echo "RData file not found" ; return 1 )
	cd $v_downstream_dir
	Rscript $v_Rdir/get.norm.downsize.r \
		merged.final.RData \
		merged.final \
		. \
		. \
	|| return 1
}

function GetMGS {
	[[ -f $v_downstream_dir/merged.final.norm.10M.RData ]] \
	|| (echo "zip file not found" ; return 1 )
	cd $v_downstream_dir
	Rscript $v_Rdir/get.mgs.from.norm.r \
		merged.final.norm.10M.RData \
		merged.final \
		. \
		. \
	|| return 1
}

while getopts 'p:c:' flag; do
	case $flag in
		p) v_project_dir_rel="${OPTARG}" ;;
		c) v_catalog_type="${OPTARG}" ;;
		*) Help ; exit 1 ;;
		:) Help ; exit 1
	esac
done

Run Parse_variables &&
Run Init &&
Run PrepareReports counting_report &&
Run PrepareReports extended_counting_report &&
Run PrepareGCT &&
Run SaveGCT &&
Run Normalize &&
Run GetMGS 
