# ![](docs/images/meteornflogo.png)

## Introduction
A nextflow wrapper for the automation and parallelisation of the METEOR pipeline and its downstream analysis.

modify workflow.ini and nextflow.params and run with:
```bash
nextflow run main.nf
```

## Quick Start

1. Install [`nextflow`](https://nf-co.re/usage/installation) (`>=20.07.1`)

2. Install any of [`Docker`](https://docs.docker.com/engine/installation/), [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/), [`Podman`](https://podman.io/), [`Shifter`](https://nersc.gitlab.io/development/shifter/how-to-use/) or [`Charliecloud`](https://hpc.github.io/charliecloud/) for full pipeline reproducibility _(please only use [`Conda`](https://conda.io/miniconda.html) as a last resort; see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles))_

3. Download the pipeline and test it on a minimal dataset with a single command:

    ```bash
    nextflow run main.nf -profile <docker/singularity/podman/shifter/charliecloud/conda/institute> --input '*_R{1,2}.fastq.gz'
    ```

    > Please check [nf-core/configs](https://github.com/nf-core/configs#documentation) to see if a custom config file to run nf-core pipelines already exists for your Institute. If so, you can simply use `-profile <institute>` in your command. This will enable either `docker` or `singularity` and set the appropriate execution settings for your local compute environment.

4. Once your run has completed successfully, clean up the intermediate files.

    ```bash
    nextflow clean -f -k

