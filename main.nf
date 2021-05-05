#!/usr/bin/env nextflow

//params.v_project_dir="$params.samples"
//params.v_workdir="${params.v_project_dir}/working"
//params.v_fastqgz1="${params.seq_data_dir}/${params.samples}${params.forward_identifier}"
//params.v_fastqgz2="${params.seq_data_dir}/${params.samples}${params.reverse_identifier}"
//params.v_fastqgz1_unzip="${params.v_workdir}/${params.samples}${params.forward_identifier}.unzipped"
//params.v_final1="${params.v_workdir}/${params.sampleId}_1.fastq"
//params.v_final2="${params.v_workdir}/${params.sampleId}_2.fastq"
//params.v_sampledir="${params.v_project_dir}/${params.catalog_type}/sample/${params.sampleId}"
//params.v_downstream_dir="${params.v_project_dir}/Downstream"
//ch_fasta1 = file(params.v_fastqgz1, checkIfExists: true)
//ch_fasta2 = file(params.v_fastqgz2, checkIfExists: true)

tempfile="../tmp.txt" 
query_ch = Channel.fromPath(params.tempfile)

process Parse_variables {
	input:
	file from query_ch

	output:
	"new" into output_ch

	script:
	'''
	cat $file > new
	'''
}
process Init {
	input:
	output:
	'''
	mkdir -p ${v_project_dir}/${catalog_type}/{sample,mapping,profiles}
	mkdir -p ${v_workdir}
	'''
}
process Decompress {
	input:
	output:
	'''
	zcat $v_fastqgz1 > $v_fastqgz1_unzip & pid1=$!
	zcat $v_fastqgz2 > $v_fastqgz2_unzip & pid2=$!
	trap "kill -2 $pid1 $pid2" SIGINT
	wait
}
process Trim {
	input:
	output:
	'''
	java -jar ${ALIEN_TRIMMER}/AlienTrimmer.jar \
		-k 10 -l 45 -m 5 -p 40 -q 20 \
		-if ${v_fastqgz1_unzip} -ir ${v_fastqgz2_unzip} -c ${trimFasta} \
		-of ${v_final1} -or ${v_final2} -os ${v_trimmedS} \
	'''
}
process Import {
	input:
	output:
	'''
	mv ${v_final1} ${v_final2} ${v_project_dir}/${catalog_type}/sample &&
	rm -r ${v_workdir}
	ruby ${meteorImportScript} \
		-i ${v_project_dir}/${catalog_type}/sample \
		-p ${catalog_type} \
		-t ${seq_platform} \
		-m "${sampleId}*" \
	'''
}
process Map_reads {
	input:
	output:
	'''
	ruby ${meteor}/meteor.rb \
		-w ${ini_file} \
		-i ${v_sampledir} \
		-p ${v_project_dir}/${catalog_type} \
		-o mapping
	'''
}
process Quantify {
	input:
	output:
	'''
	${meteor}/meteor-profiler \
		-p ${v_project_dir}/${catalog_type} \
		-f ${v_project_dir}/${catalog_type}/profiles \
		-t smart_shared_reads \
		-w ${ini_file} \
		-o ${sampleId} ${v_project_dir}/${catalog_type}/mapping/${sampleId}/${sampleId}_${meteor_counting_prefix_name}_gene_profile/census.dat \
	&& rm -r ${v_project_dir}/${catalog_type}/mapping/${sampleId} \
	'''
}
process Recover {
	input:
	output:
	'''
	rsync -aurvP --remove-source-files $v_project_dir $project_dir_rel
	'''
}
process PrepareReports {
	input:
	output:
	'''
	inFile=$v_downstream_dir/$1.csv
	outFile=$v_downstream_dir/$1.final.csv
	cat $v_project_dir/$v_catalog_type/profiles/*$1.csv > $inFile
	head -1 $inFile > ${outFile}.header
	cat $inFile | grep -v sample > ${outFile}.body
	cat ${outFile}.header ${outFile}.body > ${outFile}
	rm ${inFile} ${outFile}.header ${outFile}.body
	'''
}
process PrepareGCT {
	input:
	output:
	'''
	inFile=$v_downstream_dir/merged.tsv
	outFile=$v_downstream_dir/merged.final.tsv
	paste $v_project_dir/$v_catalog_type/profiles/*.tsv > $inFile
	width=$(head -1 $inFile | awk '{print NF}')
	echo $width
	cat $inFile | cut -f1 | sed 's/\#id_fragment/gene_id/g' > ${outFile}.gene
	cat $inFile | awk -v width="$width" 'BEGIN{OFS="\t"}{s="";for(i=2;i<=width;i=i+2){if (i!=width)s=s $i "\t"; if (i==width) s=s $i}; print s}' > ${outFile}.expr
	paste ${outFile}.gene ${outFile}.expr > ${outFile}
	rm ${inFile} ${outFile}.gene ${outFile}.expr
	'''
}
process SaveGCT {
	input:
	output:
	'''
	cd $v_downstream_dir
	Rscript $Rdir/save.gct.r  \
		merged.final.tsv \
		merged.final \
		. \
	'''
}
process Normalize {
	input:
	output:
	'''
	cd $v_downstream_dir
	Rscript $Rdir/get.norm.downsize.r \
		merged.final.RData \
		merged.final \
		. \
		. \
	'''
}
process GetMGS {
	input:
	output:
	'''
	cd $v_downstream_dir
	Rscript $Rdir/get.mgs.from.norm.r \
		merged.final.norm.10M.RData \
		merged.final \
		. \
		. \
	'''
}

println "$params"
