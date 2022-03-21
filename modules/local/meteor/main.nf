process METEOR {
	cpus 10
	memory '60GB'
	time '120h'
	container 'theoportlock/meteor'

	input:
	//tuple path(forward), path(reverse)
	path(trimmedReads)
	val(name)

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
		-m "!{name.id}*"
	meteor.rb \
		-w workflow.ini \
		-i project/!{params.catalog_type}/sample/!{name.id} \
		-p project/!{params.catalog_type} \
		-o mapping
	meteor-profiler \
		-p project/!{params.catalog_type} \
		-f project/!{params.catalog_type}/profiles \
		-t smart_shared_reads \
		-w workflow.ini \
		-o !{name.id} project/!{params.catalog_type}/mapping/!{name.id}/!{name.id}_vs_*_gene_profile/census.dat
	'''
}
