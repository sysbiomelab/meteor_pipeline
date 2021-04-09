#!/bin/bash -ue
params.v_project_dir="test/$params.sampleId"
params.v_workdir="${params.v_project_dir}/working"
// params.v_fastqgz1=$(readlink -f ${params.fastqgzs[0]})
// params.v_fastqgz2=$(readlink -f ${fastqgzs[1]})
// params.v_fastqgz1_unzip="${v_workdir}/$(basename $v_fastqgz1 .gz).unzipped"
// params.v_fastqgz2_unzip="${v_workdir}/$(basename $v_fastqgz2 .gz).unzipped"
// params.v_trimmedS="${v_workdir}/${sampleId}.trimmed.s.fastq"
// params.v_final1="${v_workdir}/${sampleId}_1.fastq"
// params.v_final2="${v_workdir}/${sampleId}_2.fastq"
// params.v_sampledir=${v_project_dir}/${catalog_type}/sample/${sampleId}
// params.v_downstream_dir="$v_project_dir/Downstream"
// vars=$(compgen -A variable | grep "^v_.*")
// for var in ${vars}; do echo "${var}=${!var}"; done
// for var in ${vars}; do if [[ -z "${!var}" ]]; then echo "missing argument ${var}" ; return 1 ; fi ; done
