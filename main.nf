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

println "$params"
