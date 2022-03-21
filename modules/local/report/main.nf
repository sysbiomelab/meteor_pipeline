process REPORT {
	cpus 1
	time '1m'
	publishDir "${params.outdir}", mode: 'copy'

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
