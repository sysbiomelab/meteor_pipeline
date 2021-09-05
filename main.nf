#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process TRIM {
	memory '6GB'
	//memory { 12.GB * task.attempt }
	cpus '1'
	time '12h'
	container 'theoportlock/alientrimmer'
	//scratch true
	
	input:
	tuple val(name), path(reads)

	output:
	path '*.{1,2}.fastq'
	val(name)

	shell:
	'''
	alientrimmer\
		-k 10 -l 45 -m 5 -p 40 -q 20\
		-1 !{reads[0]}\
		-2 !{reads[1]}\
		-a !{params.trimFasta}\
		-o !{name}
	'''
}
process METEOR {
	cpus 10
	memory '60GB'
	//cpus 1
	//memory '6GB'
	time '120h'
	container 'theoportlock/meteor'
	//scratch true

	input:
	tuple path(forward), path(reverse)
	val(name)

	output:
	path 'project/*/profiles/*.tsv', emit: sample_gct
	path 'project/*/profiles/*_counting_report.csv', emit: sample_counting_report

	shell:
	'''
	mkdir -p project/!{params.catalog_type}/{sample,mapping,profiles}
	mv !{forward} !{reverse} project/!{params.catalog_type}/sample
	echo "!{params.inifile}" > workflow.ini
	MeteorImportFastq.rb \
		-i project/!{params.catalog_type}/sample \
		-p !{params.catalog_type} \
		-t !{params.seq_platform} \
		-m "!{name}*"
	meteor.rb \
		-w workflow.ini \
		-i project/!{params.catalog_type}/sample/!{name} \
		-p project/!{params.catalog_type} \
		-o mapping
	meteor-profiler \
		-p project/!{params.catalog_type} \
		-f project/!{params.catalog_type}/profiles \
		-t smart_shared_reads \
		-w workflow.ini \
		-o !{name} project/!{params.catalog_type}/mapping/!{name}/!{name}_vs_*_gene_profile/census.dat
	'''
}
process REPORT {
	cpus 1
	time '1m'
	publishDir "${params.outdir}", mode: 'copy'
	//scratch true

	input:
	path(report)
	
	output:
	path "counting_report.csv"

	shell:
	'''
	inFile="merged_counting_report.csv"
	outFile="counting_report.csv"
	cat !{report} > $inFile
	head -1 ${inFile} > ${outFile}.header
	cat ${inFile} | grep -v sample > ${outFile}.body
	cat ${outFile}.header ${outFile}.body > ${outFile}
	rm ${inFile} ${outFile}.header ${outFile}.body
	'''
}
process GCT {
	cpus 1
	time '1m'
	publishDir "${params.outdir}", mode: 'copy'
	//scratch true

	input:
	path(sample_gct)

	output:
	path "gct.tsv"

	shell:
	'''
	inFile=pre_gct.tsv
	outFile=gct.tsv
	paste !{sample_gct} > $inFile
	width=$(head -1 $inFile | awk '{print NF}')
	echo $width
	cat $inFile | cut -f1 | sed 's/id_fragment/gene_id/g' > ${outFile}.gene
	cat $inFile | awk -v width="$width" 'BEGIN{OFS="\t"}{s="";for(i=2;i<=width;i=i+2){if (i!=width)s=s $i "\t"; if (i==width) s=s $i}; print s}' > ${outFile}.expr
	paste ${outFile}.gene ${outFile}.expr > ${outFile}
	rm ${inFile} ${outFile}.gene ${outFile}.expr
	'''
}
process MOMR {
	//cpus 20
	//memory '120GB'
	//time '8h'
	memory '6GB'
	cpus '1'
	time '12h'
	publishDir "${params.outdir}", mode: 'copy'
	container 'theoportlock/momr'
	//scratch true

	input:
	path(gct)

	output:
	path "msp.tsv"

	shell:
	'''
	downstream.r \
		!{gct} \
		!{params.reference}/!{params.mainref}/database/!{params.mainref}_lite_annotation \
		!{params.msp_dir}
	'''
}
workflow {
	ch_reads_trimming = Channel.fromFilePairs( params.input )
	TRIM(ch_reads_trimming)
	METEOR(TRIM.out)
	REPORT(METEOR.out.sample_counting_report.collect())
	GCT(METEOR.out.sample_gct.collect())
	MOMR(GCT.out)
}
