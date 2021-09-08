#!/bin/bash
nextflow run\
	~/meteor_pipeline/main.nf\
	-with-tower\
	-c ~/meteor_pipeline/configs/institutional/rosalind.config\
	-c ~/meteor_pipeline/configs/conf/rosrun.config\
	-bg\
	-resume
