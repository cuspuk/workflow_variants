rule mutect2__create_wgs_bed_file:
    input:
        fai=infer_reference_faidx,
    output:
        bed="results/variants/{reference}/regions.bed",
    log:
        "logs/variants_mutect2/create_wgs_bed_file/{reference}.log",
    localrule: True
    conda:
        "../../envs/awk_sed.yaml"
    shell:
        "(awk '{{print $1, 1, $2, $1}}' {input.fai} | sed 's/ /\t/g' > {output.bed}) 2> {log}"


rule mutect2__bed_to_interval_list:
    input:
        bed="results/variants/{reference}/regions.bed",
        dict=infer_reference_dict,
    output:
        intervals="results/variants/{reference}/regions.interval_list",
    log:
        "logs/variants_mutect2/bed_to_interval_list/{reference}.log",
    params:
        extra="--SORT true --UNIQUE true",
    resources:
        mem_mb=get_mem_mb_for_mutect2,
    wrapper:
        "v3.12.1/bio/picard/bedtointervallist"


rule mutect2__replace_read_groups:
    input:
        bam=infer_bam_for_sample_and_ref,
    output:
        temp("results/variants/{reference}/{sample}/mutect2_fixed.bam"),
    threads: get_threads_for_mutect2()
    resources:
        mem_mb=get_mem_mb_for_mutect2,
    log:
        "logs/variants_mutect2/replace_read_groups/{reference}/{sample}.log",
    params:
        extra="--RGLB lib1 --RGPL illumina --RGPU {sample} --RGSM {sample}",
    wrapper:
        "v3.12.1/bio/picard/addorreplacereadgroups"


rule mutect2__sambamba_index_bam:
    input:
        "results/variants/{reference}/{sample}/mutect2_fixed.bam",
    output:
        temp("results/variants/{reference}/{sample}/mutect2_fixed.bam.bai"),
    threads: get_threads_for_mutect2()
    log:
        "logs/variants_mutect2/sambamba_index_bam/{reference}/{sample}.log",
    params:
        extra="",
    wrapper:
        "v3.12.1/bio/sambamba/index"


rule mutect2_call:
    input:
        fasta=infer_reference_fasta,
        fasta_dict=infer_reference_dict,
        fasta_fai=infer_reference_faidx,
        map="results/variants/{reference}/{sample}/mutect2_fixed.bam",
        map_idx="results/variants/{reference}/{sample}/mutect2_fixed.bam.bai",
        intervals="results/variants/{reference}/regions.interval_list",
    output:
        vcf="results/variants/{reference}/{sample}/mutect2_all.vcf",
        tbi="results/variants/{reference}/{sample}/mutect2_all.vcf.idx",
        f1r2=temp("results/variants/{reference}/{sample}/mutect2_counts.f1r2.tar.gz"),
    threads: get_threads_for_mutect2()
    resources:
        mem_mb=get_mem_mb_for_mutect2,
    params:
        extra=parse_mutect2_call_params(),
    log:
        "logs/variants_mutect2/call/{reference}/{sample}.log",
    wrapper:
        "v3.12.1/bio/gatk/mutect"


rule mutect2__gatk_learn_read_orientation_model:
    input:
        f1r2="results/variants/{reference}/{sample}/mutect2_counts.f1r2.tar.gz",
    output:
        temp("results/variants/{reference}/{sample}/mutect2_artifacts_prior.tar.gz"),
    threads: get_threads_for_mutect2()
    resources:
        mem_mb=get_mem_mb_for_mutect2,
    params:
        extra="",
    log:
        "logs/variants_mutect2/gatk_learn_read_orientation_model/{reference}/{sample}.log",
    wrapper:
        "v3.12.1/bio/gatk/learnreadorientationmodel"


rule mutect2__filter_calls:
    input:
        vcf="results/variants/{reference}/{sample}/mutect2_all.vcf",
        ref=infer_reference_fasta,
        ref_dict=infer_reference_dict,
        ref_fai=infer_reference_faidx,
        bam="results/variants/{reference}/{sample}/mutect2_fixed.bam",
        bam_bai="results/variants/{reference}/{sample}/mutect2_fixed.bam.bai",
        f1r2="results/variants/{reference}/{sample}/mutect2_artifacts_prior.tar.gz",
    output:
        vcf=report(
            "results/variants/{reference}/{sample}/mutect2_filtered.vcf",
            category="Variants - {reference}",
            labels={
                "Sample": "{sample}",
                "Type": "GATK mutect2 - filtered",
            },
        ),
        stats="results/variants/{reference}/{sample}/mutect2_filtered.vcf.filteringStats.tsv",
    threads: get_threads_for_mutect2()
    resources:
        mem_mb=get_mem_mb_for_mutect2,
    log:
        "logs/variants_mutect2/filter_calls/{reference}/{sample}.log",
    params:
        extra=parse_mutect2_filter_params(),
        java_opts="",
    wrapper:
        "v3.12.1/bio/gatk/filtermutectcalls"
