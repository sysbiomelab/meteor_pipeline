process ALIENTRIMMER {
	errorStrategy 'ignore'
	memory '6GB'
	cpus '1'
	time '12h'
	container 'theoportlock/alientrimmer'
	
	input:
	tuple val(meta), path(reads)

	output:
	tuple val(meta), path("*.fastq")

	shell:
	if (params.single_end) {
		'''
		alientrimmer\
			-k 10 -l 45 -m 5 -p 40 -q 20\
			-i !{reads}\
			-a !{params.trimFasta}\
			-o !{meta.id}
		'''
	} else {
		'''
		alientrimmer\
			-k 10 -l 45 -m 5 -p 40 -q 20\
			-1 !{reads[0]}\
			-2 !{reads[1]}\
			-a !{params.trimFasta}\
			-o !{meta.id}
		rm -f !{meta.id}.S.fastq
		'''
	}
}
