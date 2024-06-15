checkpoint samtools__index_reference:
    input:
        reference=infer_reference_fasta,
    output:
        "results/consensus/{reference}/segments.fai",
    log:
        "logs/samtools/index_reference/{reference}.log",
    localrule: True
    wrapper:
        "v3.12.1/bio/samtools/faidx"


rule ivar__consensus_per_segment:
    input:
        bam=infer_bam_for_sample_and_ref,
        bai=infer_bai_for_sample_and_ref,
    output:
        consensus="results/consensus/{reference}/{sample}/segments/ivar_{segment}.fa",
        qual=temp("results/consensus/{reference}/{sample}/segments/ivar_{segment}.qual.txt"),
    params:
        name=lambda wildcards: f"{wildcards.sample}_{wildcards.segment}",
        samtools_params=lambda wildcards: f"--region {wildcards.segment} {parse_samtools_mpileup_for_ivar('consensus')}",
        ivar_params=parse_ivar_params_for_consensus(),
    log:
        "logs/ivar/consensus_per_segment/{sample}/{reference}/{segment}.log",
    wrapper:
        "https://github.com/cuspuk/workflow_wrappers/raw/v1.13.4/wrappers/ivar/consensus"


rule concat__consensus_from_segments:
    input:
        consensuses=infer_segment_consensuses,
    output:
        report(
            "results/consensus/{reference}/{sample}/ivar.fa",
            category="Consensus - {reference}",
            labels={
                "Sample": "{sample}",
                "Type": "ivar",
            },
        ),
    log:
        "logs/concat/consensus_from_segments/{sample}/{reference}_ivar.log",
    localrule: True
    conda:
        "../../envs/awk_sed.yaml"
    shell:
        "cat {input.consensuses} 1> {output} 2> {log}"
