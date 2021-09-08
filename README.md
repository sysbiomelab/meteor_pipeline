# ![](docs/images/meteornflogo.png)

## Introduction
A nextflow wrapper for the automation and parallelisation of the METEOR pipeline and its downstream analysis. Release of the pipeline onto nf-core is under development. Uppmax and Rosalind HPC's are the only tested environments for the pipeline.

## Uppmax Quick Start

1. Load Nextflow according to the ["nf-core configuration"](https://github.com/nf-core/configs/blob/master/docs/uppmax.md) (`>=20.07.1`)

2. Download the pipeline and test it on a minimal dataset of paired end illumina reads by modifying the conf/upprun.config file.

3. Run on the uppmax HPC cluster with a single command:

```bash
nextflow run main.nf\
	-c configs/institutional/uppmax.config\
	-c configs/conf/upprun.config.config
```
