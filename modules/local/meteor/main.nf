process METEOR {
	//errorStrategy 'ignore'
	errorStrategy 'retry'
	    maxRetries 3
	cpus 10
	memory '60GB'
	//time '24h'
	time { 24.hour * task.attempt }
	container 'theoportlock/meteor'

	input:
	tuple val(meta), path(trimmedReads)

	output:
	path 'project/*/profiles/*.tsv', emit: sample_gct
	path 'project/*/profiles/*_counting_report.csv', emit: sample_counting_report

	shell:
	'''
	mkdir -p project/!{params.catalog_type}/{sample,mapping,profiles}
	mv !{trimmedReads} project/!{params.catalog_type}/sample
	echo "!{params.inifile}" > workflow.ini
	MeteorImportFastq.rb \
		-i project/!{params.catalog_type}/sample \
		-p !{params.catalog_type} \
		-t !{params.seq_platform} \
		-m "!{meta.id}*"
	meteor.rb \
		-w workflow.ini \
		-i project/!{params.catalog_type}/sample/!{meta.id} \
		-p project/!{params.catalog_type} \
		-o mapping
	meteor-profiler \
		-p project/!{params.catalog_type} \
		-f project/!{params.catalog_type}/profiles \
		-t smart_shared_reads \
		-w workflow.ini \
		-o !{meta.id} project/!{params.catalog_type}/mapping/!{meta.id}/!{meta.id}_vs_*_gene_profile/census.dat
	'''
}
