process GCT {
	cpus 1
	time '8h'
	publishDir "${params.outdir}", mode: 'copy'

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
