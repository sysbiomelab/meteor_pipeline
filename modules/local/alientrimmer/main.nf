process ALIENTRIMMER {
	errorStrategy 'ignore'
	memory '6GB'
	cpus '1'
	time '12h'
	container 'theoportlock/alientrimmer'
	
	input:
	tuple val(name), path(reads)

	output:
	//path '*.{1,2}.fastq'
	path '*.fastq'
	val(name)

	shell:
	'''
	alientrimmer\
		-k 10 -l 45 -m 5 -p 40 -q 20\
		-i !{reads}\
		-a !{params.trimFasta}\
		-o !{name.id}
	'''
}
