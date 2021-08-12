#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process Trim {
	scratch true
	cpus 1
	time '1h'
	scratch true
	
	input:
	tuple val(name), file(reads)

	output:
	path '*.{1,2}.fastq'
	val(name)

	shell:
	'''
	java -jar !{params.ALIEN_TRIMMER}/AlienTrimmer.jar\
		-k 10 -l 45 -m 5 -p 40 -q 20\
		-1 !{reads[0]}\
		-2 !{reads[1]}\
		-a !{params.trimFasta}\
		-o !{name}
	'''
}
process Import {
	scratch true
	cpus 1
	time '1h'

	input:
	tuple path(forward), path(reverse)
	val(name)

	output:
	path 'project'
	val(name)

	shell:
	'''
	mkdir -p project/!{params.catalog_type}/{sample,mapping,profiles}
	mv !{forward} !{reverse} project/!{params.catalog_type}/sample
	ruby !{params.meteor}/data_preparation_tools/MeteorImportFastq.rb \
		-i project/!{params.catalog_type}/sample \
		-p !{params.catalog_type} \
		-t !{params.seq_platform} \
		-m "!{name}*"

	'''
}
process Map_reads {
	scratch true
	cpus 10
	time '8h'

	input:
	path(project)
	val(name)

	output:
	path 'project'
	val(name)

	shell:
	'''
	ruby !{params.meteor}/meteor-pipeline/meteor.rb \
		-w !{params.ini_file} \
		-i !{project}/!{params.catalog_type}/sample/!{name} \
		-p !{project}/!{params.catalog_type} \
		-o mapping
	'''
}

process Quantify {
	cpus 1
	time '1h'
	publishDir "${params.outdir}", mode: 'copy'

	input:
	path(project)
	val(name)

	output:
	path "project/${params.catalog_type}/profiles"

	shell:
	'''
	!{params.meteor}/meteor-pipeline/src/build/meteor-profiler \
		-p !{project}/!{params.catalog_type} \
		-f !{project}/!{params.catalog_type}/profiles \
		-t smart_shared_reads \
		-w !{params.ini_file} \
		-o !{name} !{project}/!{params.catalog_type}/mapping/!{name}/!{name}_vs_*_gene_profile/census.dat
	'''
}

workflow {
	ch_reads_trimming = Channel.fromFilePairs( params.input )
	Trim(ch_reads_trimming)
	Import(Trim.out)
	Map_reads(Import.out)
	Quantify(Map_reads.out)
}
