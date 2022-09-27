process MOMR {
	clusterOptions "-A snic2022-5-334 -C mem256GB -p node"
	time '12h'
	publishDir "${params.outdir}", mode: 'copy'
	container 'theoportlock/momr'

	input:
	path(gct)

	output:
	path "*.csv"

	shell:
	'''
	downstream.r \
		!{gct} \
		!{params.reference}/!{params.mainref}/database/!{params.mainref}_lite_annotation \
		!{params.msp_dir}
	'''
}
