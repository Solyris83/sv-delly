process DELLY_CALL {
    tag "$meta"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/delly:1.2.6--hb7e2ac5_0' :
        'biocontainers/delly:1.2.6--hb7e2ac5_0' }"

    input:
    tuple val(meta), path(input), path(input_index)
    path fasta
    path fai

    output:
    tuple val(meta), path("*.{bcf,vcf.gz}")  , emit: bcf
    tuple val(meta), path("*.{csi,tbi}")     , emit: csi
    path "versions.yml"                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    def suffix = task.ext.suffix ?: "bcf"

    //def exclude = exclude_bed ? "--exclude ${exclude_bed}" : ""

    def bcf_output = suffix == "bcf" ? "--outfile ${prefix}.bcf" : ""
    def vcf_output = suffix == "vcf" ? "| bgzip ${args2} --threads ${task.cpus} --stdout > ${prefix}.vcf.gz && tabix ${prefix}.vcf.gz" : ""

    """
    delly \\
        call \\
        ${args} \\
        ${bcf_output} \\
        --genome ${fasta} \\
        ${input} \\
        ${vcf_output}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        delly: \$( echo \$(delly --version 2>&1) | sed 's/^.*Delly version: v//; s/ using.*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta}"
    def suffix = task.ext.suffix ?: "bcf"

    def bcf_output = suffix == "bcf" ? "touch ${prefix}.bcf && touch ${prefix}.bcf.csi" : ""
    def vcf_output = suffix == "vcf" ? "touch ${prefix}.vcf.gz && touch ${prefix}.vcf.gz.tbi" : ""

    """
    ${bcf_output}
    ${vcf_output}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        delly: \$( echo \$(delly --version 2>&1) | sed 's/^.*Delly version: v//; s/ using.*\$//')
    END_VERSIONS
    """
}
