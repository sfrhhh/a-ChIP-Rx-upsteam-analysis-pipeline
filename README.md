# a ChIP-Rx upsteam analysis pipeline

## Introduction

With the advancement of sequencing technologies, chromatin immunoprecipitation followed by high-throughput sequencing (ChIP-Seq) has become increasingly popular for studying genome-wide protein-DNA interactions. To address the need for a comprehensive and efficient ChIP-Rx analysis pipeline, we present our ChIP-Rx pipeline, which provides a robust framework for processing, analyzing, and visualizing ChIP-Seq data. This pipeline consists of five main scripts, each performing essential functions to ensure accurate and reliable results.

## Visualize files
**This is a tree of files.**
```
.
├── ChIP_conda_env.yaml
├── pipeline
│   ├── 01.1_CHIPseq.sh
│   ├── 01.4_plotLog2Heamap.R
│   ├── 01_process-before-map.sh
│   ├── 11.1_CHIPseq_write_md.sh
│   ├── 21.1_merge_group_bw.sh
│   └── merge_bigwig.R
├── README.md
└── test
```
## How to use?
1. First, configure your conda environment
You should install conda through official website(https://www.anaconda.com/products/distribution).
Once your conda environment is configured successfully, you can create your conda env by
```
conda env create -f ChIP_conda_env.yaml
```
Then you can use your new env by
```
conda activate chip-seq_env
```

2. Generate a sampleinfo for data
There are several test files in /test/data_unchanged, for analysis test files, generate a file called sampleinfo.txt
```
IP_H3K27ac_DMSO_rep1	IP_H3K27ac_DMSO_rep1	IP_H3K27ac_DMSO
IP_H3K27ac_DMSO_rep2	IP_H3K27ac_DMSO_rep2	IP_H3K27ac_DMSO
IP_input_DMSO_rep1	IP_input_DMSO_rep1	IP_input_DMSO
IP_input_DMSO_rep2	IP_input_DMSO_rep2	IP_input_DMSO

```
The first, second column is sample name. The third column is sample group. Use '\t' to sep.

3. Cut adapters
cd to you work dir(where sampleinfo.txt is), and run code(choose test dir as example)
```
../pipeline/01_process-before-map.sh `pwd`
```
This will generate qc files and fastq files after cut adapters.

4. Run aligning, bamCoverage and call peak
The pipeline use bowtie2 to align to reference.
```
../pipeline/01.1_CHIPseq.sh `pwd`
```

5. Combine bigwig files of same group
Experiments need to be repeated. If your data has 
```
../pipeline/21.1_merge_group_bw.sh `pwd`/04_bw_fulllength `pwd`/sampleinfo.txt f
```

6. Downstream analysis
For exploring, there is a part of downstream analysis code.
```
../pipeline/11.1_CHIPseq_write_md.sh `pwd` $control_sample
```

## A test of data analysis
In test dir, there are some files which are pipeline generate.
**This is a tree of test.**
```
.
├── 00_rawdata
│   ├── IP_H3K27ac_DMSO_rep1_R1.fastq.gz -> ../data_unchanged/IP_H3K27ac_DMSO_rep1_R1.fastq.gz
│   ├── IP_H3K27ac_DMSO_rep1_R2.fastq.gz -> ../data_unchanged/IP_H3K27ac_DMSO_rep1_R2.fastq.gz
│   ├── IP_H3K27ac_DMSO_rep2_R1.fastq.gz -> ../data_unchanged/IP_H3K27ac_DMSO_rep2_R1.fastq.gz
│   ├── IP_H3K27ac_DMSO_rep2_R2.fastq.gz -> ../data_unchanged/IP_H3K27ac_DMSO_rep2_R2.fastq.gz
│   ├── IP_input_DMSO_rep1_R1.fastq.gz -> ../data_unchanged/IP_input_DMSO_rep1_R1.fastq.gz
│   ├── IP_input_DMSO_rep1_R2.fastq.gz -> ../data_unchanged/IP_input_DMSO_rep1_R2.fastq.gz
│   ├── IP_input_DMSO_rep2_R1.fastq.gz -> ../data_unchanged/IP_input_DMSO_rep2_R1.fastq.gz
│   └── IP_input_DMSO_rep2_R2.fastq.gz -> ../data_unchanged/IP_input_DMSO_rep2_R2.fastq.gz
├── 01.1_CHIPseq.log
├── 01_process-before-map.log
├── 01_rawfastqc
│   ├── IP_H3K27ac_DMSO_rep1_R1_fastqc.html
│   ├── IP_H3K27ac_DMSO_rep1_R1_fastqc.zip
│   ├── IP_H3K27ac_DMSO_rep1_R2_fastqc.html
│   ├── IP_H3K27ac_DMSO_rep1_R2_fastqc.zip
│   ├── IP_H3K27ac_DMSO_rep2_R1_fastqc.html
│   ├── IP_H3K27ac_DMSO_rep2_R1_fastqc.zip
│   ├── IP_H3K27ac_DMSO_rep2_R2_fastqc.html
│   ├── IP_H3K27ac_DMSO_rep2_R2_fastqc.zip
│   ├── IP_input_DMSO_rep1_R1_fastqc.html
│   ├── IP_input_DMSO_rep1_R1_fastqc.zip
│   ├── IP_input_DMSO_rep1_R2_fastqc.html
│   ├── IP_input_DMSO_rep1_R2_fastqc.zip
│   ├── IP_input_DMSO_rep2_R1_fastqc.html
│   ├── IP_input_DMSO_rep2_R1_fastqc.zip
│   ├── IP_input_DMSO_rep2_R2_fastqc.html
│   ├── IP_input_DMSO_rep2_R2_fastqc.zip
│   ├── rawdata_multiqc_data
│   │   ├── multiqc_citations.txt
│   │   ├── multiqc_data.json
│   │   ├── multiqc_fastqc.txt
│   │   ├── multiqc_general_stats.txt
│   │   ├── multiqc.log
│   │   └── multiqc_sources.txt
│   └── rawdata_multiqc.html
├── 02_trimmeddata
│   ├── IP_H3K27ac_DMSO_rep1_R1.fastq.gz_trimming_report.txt
│   ├── IP_H3K27ac_DMSO_rep1_R2.fastq.gz_trimming_report.txt
│   ├── IP_H3K27ac_DMSO_rep1_trimmed_R1.fq.gz
│   ├── IP_H3K27ac_DMSO_rep1_trimmed_R2.fq.gz
│   ├── IP_H3K27ac_DMSO_rep2_R1.fastq.gz_trimming_report.txt
│   ├── IP_H3K27ac_DMSO_rep2_R2.fastq.gz_trimming_report.txt
│   ├── IP_H3K27ac_DMSO_rep2_trimmed_R1.fq.gz
│   ├── IP_H3K27ac_DMSO_rep2_trimmed_R2.fq.gz
│   ├── IP_input_DMSO_rep1_R1.fastq.gz_trimming_report.txt
│   ├── IP_input_DMSO_rep1_R2.fastq.gz_trimming_report.txt
│   ├── IP_input_DMSO_rep1_trimmed_R1.fq.gz
│   ├── IP_input_DMSO_rep1_trimmed_R2.fq.gz
│   ├── IP_input_DMSO_rep2_R1.fastq.gz_trimming_report.txt
│   ├── IP_input_DMSO_rep2_R2.fastq.gz_trimming_report.txt
│   ├── IP_input_DMSO_rep2_trimmed_R1.fq.gz
│   └── IP_input_DMSO_rep2_trimmed_R2.fq.gz
├── 02_trimmeddata_fastqc
│   ├── IP_H3K27ac_DMSO_rep1_trimmed_R1_fastqc.html
│   ├── IP_H3K27ac_DMSO_rep1_trimmed_R1_fastqc.zip
│   ├── IP_H3K27ac_DMSO_rep1_trimmed_R2_fastqc.html
│   ├── IP_H3K27ac_DMSO_rep1_trimmed_R2_fastqc.zip
│   ├── IP_H3K27ac_DMSO_rep2_trimmed_R1_fastqc.html
│   ├── IP_H3K27ac_DMSO_rep2_trimmed_R1_fastqc.zip
│   ├── IP_H3K27ac_DMSO_rep2_trimmed_R2_fastqc.html
│   ├── IP_H3K27ac_DMSO_rep2_trimmed_R2_fastqc.zip
│   ├── IP_input_DMSO_rep1_trimmed_R1_fastqc.html
│   ├── IP_input_DMSO_rep1_trimmed_R1_fastqc.zip
│   ├── IP_input_DMSO_rep1_trimmed_R2_fastqc.html
│   ├── IP_input_DMSO_rep1_trimmed_R2_fastqc.zip
│   ├── IP_input_DMSO_rep2_trimmed_R1_fastqc.html
│   ├── IP_input_DMSO_rep2_trimmed_R1_fastqc.zip
│   ├── IP_input_DMSO_rep2_trimmed_R2_fastqc.html
│   ├── IP_input_DMSO_rep2_trimmed_R2_fastqc.zip
│   ├── trimmeddata_multiqc_data
│   │   ├── multiqc_citations.txt
│   │   ├── multiqc_data.json
│   │   ├── multiqc_fastqc.txt
│   │   ├── multiqc_general_stats.txt
│   │   ├── multiqc.log
│   │   └── multiqc_sources.txt
│   └── trimmeddata_multiqc.html
├── 03_bam_hg19
│   ├── IP_H3K27ac_DMSO_rep1_hg19.bam
│   ├── IP_H3K27ac_DMSO_rep1_hg19.bam.bai
│   ├── IP_H3K27ac_DMSO_rep2_hg19.bam
│   ├── IP_H3K27ac_DMSO_rep2_hg19.bam.bai
│   ├── IP_input_DMSO_rep1_hg19.bam
│   ├── IP_input_DMSO_rep1_hg19.bam.bai
│   ├── IP_input_DMSO_rep2_hg19.bam
│   └── IP_input_DMSO_rep2_hg19.bam.bai
├── 03_bam_hg19_rmdup
│   ├── IP_H3K27ac_DMSO_rep1_hg19.rmdup.bam
│   ├── IP_H3K27ac_DMSO_rep1_hg19.rmdup.bam.bai
│   ├── IP_H3K27ac_DMSO_rep1_hg19.rmdup.metrics
│   ├── IP_H3K27ac_DMSO_rep2_hg19.rmdup.bam
│   ├── IP_H3K27ac_DMSO_rep2_hg19.rmdup.bam.bai
│   ├── IP_H3K27ac_DMSO_rep2_hg19.rmdup.metrics
│   ├── IP_input_DMSO_rep1_hg19.rmdup.bam
│   ├── IP_input_DMSO_rep1_hg19.rmdup.bam.bai
│   ├── IP_input_DMSO_rep1_hg19.rmdup.metrics
│   ├── IP_input_DMSO_rep2_hg19.rmdup.bam
│   ├── IP_input_DMSO_rep2_hg19.rmdup.bam.bai
│   └── IP_input_DMSO_rep2_hg19.rmdup.metrics
├── 03_spikebam_mm10
│   ├── IP_H3K27ac_DMSO_rep1_onlymm10.bam
│   ├── IP_H3K27ac_DMSO_rep1_onlymm10.bam.bai
│   ├── IP_H3K27ac_DMSO_rep2_onlymm10.bam
│   ├── IP_H3K27ac_DMSO_rep2_onlymm10.bam.bai
│   ├── IP_input_DMSO_rep1_onlymm10.bam
│   ├── IP_input_DMSO_rep1_onlymm10.bam.bai
│   ├── IP_input_DMSO_rep2_onlymm10.bam
│   └── IP_input_DMSO_rep2_onlymm10.bam.bai
├── 03_spikebam_mm10_rmdup
│   ├── IP_H3K27ac_DMSO_rep1_onlymm10.rmdup.bam
│   ├── IP_H3K27ac_DMSO_rep1_onlymm10.rmdup.bam.bai
│   ├── IP_H3K27ac_DMSO_rep1_onlymm10.rmdup.metrics
│   ├── IP_H3K27ac_DMSO_rep2_onlymm10.rmdup.bam
│   ├── IP_H3K27ac_DMSO_rep2_onlymm10.rmdup.bam.bai
│   ├── IP_H3K27ac_DMSO_rep2_onlymm10.rmdup.metrics
│   ├── IP_input_DMSO_rep1_onlymm10.rmdup.bam
│   ├── IP_input_DMSO_rep1_onlymm10.rmdup.bam.bai
│   ├── IP_input_DMSO_rep1_onlymm10.rmdup.metrics
│   ├── IP_input_DMSO_rep2_onlymm10.rmdup.bam
│   ├── IP_input_DMSO_rep2_onlymm10.rmdup.bam.bai
│   └── IP_input_DMSO_rep2_onlymm10.rmdup.metrics
├── 04_bw_fulllength
│   ├── IP_H3K27ac_DMSO_rep1_fulllength.bw
│   ├── IP_H3K27ac_DMSO_rep1.log
│   ├── IP_H3K27ac_DMSO_rep2_fulllength.bw
│   ├── IP_H3K27ac_DMSO_rep2.log
│   ├── IP_input_DMSO_rep1_fulllength.bw
│   ├── IP_input_DMSO_rep1.log
│   ├── IP_input_DMSO_rep2_fulllength.bw
│   └── IP_input_DMSO_rep2.log
├── 05_peak
│   ├── 05.1_peak_alone
│   │   ├── IP_H3K27ac_DMSO_rep1_alone_peaks.final.narrowPeak
│   │   ├── IP_H3K27ac_DMSO_rep1_alone_peaks.narrowPeak
│   │   ├── IP_H3K27ac_DMSO_rep1_alone_peaks.xls
│   │   ├── IP_H3K27ac_DMSO_rep1_alone_summits.bed
│   │   ├── IP_H3K27ac_DMSO_rep2_alone_peaks.final.narrowPeak
│   │   ├── IP_H3K27ac_DMSO_rep2_alone_peaks.narrowPeak
│   │   ├── IP_H3K27ac_DMSO_rep2_alone_peaks.xls
│   │   ├── IP_H3K27ac_DMSO_rep2_alone_summits.bed
│   │   ├── IP_input_DMSO_rep1_alone_peaks.final.narrowPeak
│   │   ├── IP_input_DMSO_rep1_alone_peaks.narrowPeak
│   │   ├── IP_input_DMSO_rep1_alone_peaks.xls
│   │   ├── IP_input_DMSO_rep1_alone_summits.bed
│   │   ├── IP_input_DMSO_rep2_alone_peaks.final.narrowPeak
│   │   ├── IP_input_DMSO_rep2_alone_peaks.narrowPeak
│   │   ├── IP_input_DMSO_rep2_alone_peaks.xls
│   │   └── IP_input_DMSO_rep2_alone_summits.bed
│   └── 05.2_peak_compare
│       ├── IP_H3K27ac_DMSO_rep1_compare_peaks.final.narrowPeak
│       ├── IP_H3K27ac_DMSO_rep1_compare_peaks.narrowPeak
│       ├── IP_H3K27ac_DMSO_rep1_compare_peaks.xls
│       ├── IP_H3K27ac_DMSO_rep1_compare_summits.bed
│       ├── IP_H3K27ac_DMSO_rep2_compare_peaks.final.narrowPeak
│       ├── IP_H3K27ac_DMSO_rep2_compare_peaks.narrowPeak
│       ├── IP_H3K27ac_DMSO_rep2_compare_peaks.xls
│       ├── IP_H3K27ac_DMSO_rep2_compare_summits.bed
│       ├── IP_input_DMSO_rep1_compare_peaks.final.narrowPeak
│       └── IP_input_DMSO_rep2_compare_peaks.final.narrowPeak
├── cmdList
├── data_unchanged
│   ├── IP_H3K27ac_DMSO_rep1_R1.fastq.gz
│   ├── IP_H3K27ac_DMSO_rep1_R2.fastq.gz
│   ├── IP_H3K27ac_DMSO_rep2_R1.fastq.gz
│   ├── IP_H3K27ac_DMSO_rep2_R2.fastq.gz
│   ├── IP_input_DMSO_rep1_R1.fastq.gz
│   ├── IP_input_DMSO_rep1_R2.fastq.gz
│   ├── IP_input_DMSO_rep2_R1.fastq.gz
│   └── IP_input_DMSO_rep2_R2.fastq.gz
├── logs
│   ├── align_hg19
│   │   ├── IP_H3K27ac_DMSO_rep1_align.log
│   │   ├── IP_H3K27ac_DMSO_rep2_align.log
│   │   ├── IP_input_DMSO_rep1_align.log
│   │   └── IP_input_DMSO_rep2_align.log
│   ├── align_mm10
│   │   ├── IP_H3K27ac_DMSO_rep1_spikealign.log
│   │   ├── IP_H3K27ac_DMSO_rep2_spikealign.log
│   │   ├── IP_input_DMSO_rep1_spikealign.log
│   │   └── IP_input_DMSO_rep2_spikealign.log
│   ├── callpeak
│   │   ├── IP_H3K27ac_DMSO_rep1_alone.log
│   │   ├── IP_H3K27ac_DMSO_rep1_compare.log
│   │   ├── IP_H3K27ac_DMSO_rep2_alone.log
│   │   ├── IP_H3K27ac_DMSO_rep2_compare.log
│   │   ├── IP_input_DMSO_rep1_alone.log
│   │   └── IP_input_DMSO_rep2_alone.log
│   ├── rmdup_state_hg19
│   │   ├── IP_H3K27ac_DMSO_rep1_hg19.rmdup.stat
│   │   ├── IP_H3K27ac_DMSO_rep2_hg19.rmdup.stat
│   │   ├── IP_input_DMSO_rep1_hg19.rmdup.stat
│   │   └── IP_input_DMSO_rep2_hg19.rmdup.stat
│   ├── rmdup_state_mm10
│   │   ├── IP_H3K27ac_DMSO_rep1_onlymm10.rmdup.stat
│   │   ├── IP_H3K27ac_DMSO_rep2_onlymm10.rmdup.stat
│   │   ├── IP_input_DMSO_rep1_onlymm10.rmdup.stat
│   │   └── IP_input_DMSO_rep2_onlymm10.rmdup.stat
│   ├── scalefactor.txt
│   ├── spike-input.txt
│   └── trimmeddata
│       ├── IP_H3K27ac_DMSO_rep1_trimmed.log
│       ├── IP_H3K27ac_DMSO_rep2_trimmed.log
│       ├── IP_input_DMSO_rep1_trimmed.log
│       └── IP_input_DMSO_rep2_trimmed.log
├── Sampleinfo
│   ├── input.txt
│   ├── IP_DMSO_rep1.txt
│   ├── IP_DMSO_rep2.txt
│   └── sample_use.txt
└── sampleinfo.txt

24 directories, 188 files
```
There are many files, which are all generated by pipeline. Feel free to explore them! By integrating cutting-edge tools and techniques, the ChIP-Rx pipeline offers a robust solution for the analysis of ChIP-Seq data, ensuring accurate identification of protein-DNA interactions and providing valuable insights into genomic regulation mechanisms.