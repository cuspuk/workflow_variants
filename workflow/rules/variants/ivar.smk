rule ivar__get_variants:
    input:
        bam=infer_bam_for_sample_and_ref,
        bai=infer_bai_for_sample_and_ref,
        ref=infer_reference_fasta,
    output:
        tsv=temp("results/variants/{reference}/{sample}/ivar_all.tsv"),
    params:
        samtools_params=parse_samtools_mpileup_for_ivar("variants"),
        ivar_params=parse_ivar_params_for_variants(),
    log:
        "logs/variants_ivar/get_variants/{reference}/{sample}.log",
    wrapper:
        "https://github.com/cuspuk/workflow_wrappers/raw/v1.13.4/wrappers/ivar/variants"


rule ivar__tsv_to_vcf:
    input:
        "results/variants/{reference}/{sample}/ivar_{step}.tsv",
    output:
        all="results/variants/{reference}/{sample}/ivar_{step}.vcf",
        filtered="results/variants/{reference}/{sample}/ivar_{step}_passed_only.vcf",
    log:
        "logs/variants_ivar/tsv_to_vcf_{step}/{reference}/{sample}.log",
    wrapper:
        "https://github.com/cuspuk/workflow_wrappers/raw/v1.13.4/wrappers/ivar/vcf_convert"


rule ivar__filter_variants:
    input:
        "results/variants/{reference}/{sample}/ivar_all.tsv",
    output:
        mixed_positions="results/variants/{reference}/{sample}/ivar_filtered.tsv",
        readcount=temp("results/variants/{reference}/{sample}/ivar_filtered.count"),
    params:
        alt_depth=config["variants__ivar"]["postfilter"]["min_alt_depth"],
        min_alt_freq=config["variants__ivar"]["postfilter"]["min_alt_freq"],
        max_alt_freq=config["variants__ivar"]["postfilter"]["max_alt_freq"],
        total_depth=config["variants__ivar"]["postfilter"]["min_total_depth"],
    log:
        "logs/variants_ivar/filter_variants/{reference}/{sample}.log",
    wrapper:
        "https://github.com/cuspuk/workflow_wrappers/raw/v1.13.4/wrappers/ivar/mixed_positions"


rule ivar__convert_to_html:
    input:
        "results/variants/{reference}/{sample}/ivar_{step}.tsv",
    output:
        report(
            "results/variants/{reference}/{sample}/ivar_{step}.html",
            category="Variants - {reference}",
            labels={
                "Sample": "{sample}",
                "Type": "Ivar - {step}",
            },
        ),
    log:
        "logs/variants_ivar/convert_to_html_{step}/{reference}/{sample}.log",
    wrapper:
        "https://github.com/cuspuk/workflow_wrappers/raw/v1.13.4/wrappers/ivar/html_convert"
