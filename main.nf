#!/usr/bin/env nextflow
include { INPUT_CHECK } from './subworkflows/local/input_check'
include { ALIENTRIMMER } from './modules/local/alientrimmer/main'
include { METEOR } from './modules/local/meteor/main'
include { REPORT } from './modules/local/report/main'
include { GCT } from './modules/local/gct/main'
include { MOMR } from './modules/local/momr/main'
nextflow.enable.dsl=2

workflow {
	//INPUT_CHECK()
	ch_reads_trimming = Channel.fromFilePairs( params.input )
	//ch_reads_trimming = INPUT_CHECK.out.raw_short_reads
	ALIENTRIMMER(ch_reads_trimming)
	METEOR(ALIENTRIMMER.out)
	REPORT(METEOR.out.sample_counting_report.collect())
	GCT(METEOR.out.sample_gct.collect())
	MOMR(GCT.out)
}
