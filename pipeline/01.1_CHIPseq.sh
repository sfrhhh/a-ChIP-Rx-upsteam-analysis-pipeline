#!/bin/bash
####################################################################################################
#########################   ChIP-seq analysis pipeline  with spike-in     ##########################
####################################################################################################

echo "Usage:"
echo "   01.1_CHIPseq.sh file_path"
echo ""

file_path=$1
if test -z $file_path
then
   echo "please input the absolute file_path"
   exit
fi
# server:10.184.163.1 
### activate conda environment
# source /share/home/suifengrui/miniconda3/bin/activate chip-seq_env


###file_path
logs_dir=${file_path}/logs

trimmedFastq_dir=${file_path}/02_trimmeddata

align_exp_dir=${file_path}/03_bam_hg19
alignexp_log_dir=${file_path}/logs/align_hg19

align_spike_dir=${file_path}/03_spikebam_mm10
alignspike_log_dir=${file_path}/logs/align_mm10

exp_bam_rmdup=${file_path}/03_bam_hg19_rmdup
rmdup_exp_log=${file_path}/logs/rmdup_state_hg19

spike_bam_rmdup=${file_path}/03_spikebam_mm10_rmdup
rmdup_spike_log=${file_path}/logs/rmdup_state_mm10


bw_fulllength_dir=${file_path}/04_bw_fulllength

peak_dir=${file_path}/05_peak
peak_log_dir=${file_path}/logs/callpeak

peak_alone_dir=${file_path}/05_peak/05.1_peak_alone
peak_compare_dir=${file_path}/05_peak/05.2_peak_compare

sampleinfo=${file_path}/sampleinfo.txt 
# 该文件需要事先构建好，上传到工作目录，第一列为原始数据的命名，第二列为样本名，制表符分割
# 样本名命名规则 IP_antibody_control/treated_otherinfo_cellline_spikecellline_id

sampledir=${file_path}/Sampleinfo

#reference genome
GENOME_EXP="/work/xulab/suifengrui/reference/index/bowtie2/bowtie2_download/hg19_ucsc/hg19"
GENOME_SPIKE="/work/xulab/suifengrui/reference/index/bowtie2/bowtie2_download/mm10/mm10"
blacklist="/work/xulab/suifengrui/reference/annotation/encode/blacklist/hg19-blacklist.v2.bed" # 这块一会去找一下在哪下载


###create  sampleinfo

mkdir -p ${sampledir}
cat $sampleinfo |cut -f 2 > ${sampledir}/sample_use.txt

cat ${sampledir}/sample_use.txt|grep -i "input"|while read id;
do
    input_sample=${id/*nput_/} 
    echo $id > ${sampledir}/IP_${input_sample}.txt
    grep ${input_sample} ${sampledir}/sample_use.txt | grep -v -i "input" >> ${sampledir}/IP_${input_sample}.txt
done

head -n 1 ${sampledir}/IP*txt | grep -i "input" > ${sampledir}/input.txt # ^代表行首，意为行首紧跟IP



#step 3.1
###Aligning to experimental genome#####
echo -e "\n***************************\nalign of experimental genome begins at $(date +%Y"-"%m"-"%d" "%H":"%M":"%S)\n***************************"

mkdir -p ${align_exp_dir}
mkdir -p ${alignexp_log_dir}
mkdir -p ${exp_bam_rmdup}
mkdir -p ${rmdup_exp_log}


for fq1 in `ls ${trimmedFastq_dir}/*R1.fq.gz`
do 
    fq2=${fq1/R1.fq.gz/R2.fq.gz}
    sample="$(basename ${fq1/_trimmed_R1.fq.gz/})"
    if [ ! -s ${exp_bam_rmdup}/${sample}_hg19.rmdup.bam ]
    then
        (bowtie2  -p 25   -x  ${GENOME_EXP} -N 1  -1 $fq1 -2 $fq2 \
        2> ${alignexp_log_dir}/${sample}_align.log) \
        |samtools view -bS -F 3844 -f 2 -q 30 \
        |samtools sort  -O bam  -@ 25 -o ${align_exp_dir}/${sample}_hg19.bam 
        samtools index ${align_exp_dir}/${sample}_hg19.bam
        # -x 参考基因组 格式hg19_Bowtie2Index/genome
        # samtools -b 输出bam, -S 输入sam, -F 保留flag值为3844外的所有序列?
        # -f 保留flag值为2的所有序列，-q 比对的最低质量值

        # picard 这段去pcr的重复

        picard MarkDuplicates -REMOVE_DUPLICATES True \
            -I ${align_exp_dir}/${sample}_hg19.bam \
            -O ${exp_bam_rmdup}/${sample}_hg19.rmdup.bam \
            -M ${exp_bam_rmdup}/${sample}_hg19.rmdup.metrics
        # 重复的数据写到-M选项指定的文件里
        samtools index  ${exp_bam_rmdup}/${sample}_hg19.rmdup.bam
        samtools flagstat ${exp_bam_rmdup}/${sample}_hg19.rmdup.bam > ${rmdup_exp_log}/${sample}_hg19.rmdup.stat
        # 统计输入文件的相关数据并将这些数据输出至屏幕显示。
        # 每一项统计数据都由两部分组成，分别是QC pass和QC failed，表示通过QC的reads数据量和未通过QC的reads数量。
        # 以“PASS + FAILED”格式显示。还可以根据samtools的标志位显示相应的内容，但是这里不做讨论
    fi
done 


#step 3.2
###Aligning to spike-in genome#####
echo -e "\n***************************\nalign of spike-in genome begins at $(date +%Y"-"%m"-"%d" "%H":"%M":"%S)\n***************************"

mkdir -p ${align_spike_dir}
mkdir -p ${alignspike_log_dir}
mkdir -p ${spike_bam_rmdup}
mkdir -p ${rmdup_spike_log}


for fq1 in `ls ${trimmedFastq_dir}/*R1.fq.gz`
do 
fq2=${fq1/R1.fq.gz/R2.fq.gz}
sample="$(basename ${fq1/_trimmed_R1.fq.gz/})"
if [ ! -s ${spike_bam_rmdup}/${sample}_onlymm10.rmdup.bam ]
then
    (bowtie2  -p 25   -x  ${GENOME_SPIKE} -N 1  -1 $fq1 -2 $fq2 \
    2> ${alignspike_log_dir}/${sample}_spikealign.log) \
    |samtools view -bS -F 3844 -f 2 -q 30 \
    |samtools sort  -O bam  -@ 25 -o ${align_spike_dir}/${sample}_onlymm10.bam 
    samtools index ${align_spike_dir}/${sample}_onlymm10.bam
     
    # picard

    picard MarkDuplicates -REMOVE_DUPLICATES True \
        -I ${align_spike_dir}/${sample}_onlymm10.bam \
        -O ${spike_bam_rmdup}/${sample}_onlymm10.rmdup.bam \
        -M ${spike_bam_rmdup}/${sample}_onlymm10.rmdup.metrics
    samtools index  ${spike_bam_rmdup}/${sample}_onlymm10.rmdup.bam
    samtools flagstat ${spike_bam_rmdup}/${sample}_onlymm10.rmdup.bam > ${rmdup_spike_log}/${sample}_onlymm10.rmdup.stat
    
fi
done 





#step 3.3
### calculate normalization factors ###
echo -e "\n***************************\nCalculating normalization factors at $(date +%Y"-"%m"-"%d" "%H":"%M":"%S)\n***************************"


hg19_path=${rmdup_exp_log}
mm10_path=${rmdup_spike_log}
align_path=${alignexp_log_dir}

if [ -s "${logs_dir}/scalefactor.txt" ] 
then
    rm  ${logs_dir}/scalefactor.txt
fi

touch ${logs_dir}/scalefactor.txt

if [ -s "${logs_dir}/spike-input.txt" ] 
then
    rm  ${logs_dir}/spike-input.txt
fi

touch ${logs_dir}/spike-input.txt

# input file
input_file=${sampledir}/input.txt
spike_sample=`head -n 1 ${input_file}`

spike_hgRatio=$(cat $hg19_path/$spike_sample"_hg19.rmdup.stat" | grep "total (QC-passed reads"|cut -d " " -f 1)
spike_mmRatio=$(cat $mm10_path/$spike_sample"_onlymm10.rmdup.stat" | grep "total (QC-passed reads"|cut -d " " -f 1)
spike_product=$(echo $spike_hgRatio/$spike_mmRatio | bc -l)

cat $input_file | while read sample;do
    total_log=${align_path}/${sample}_align.log
    mm10_log=${mm10_path}/${sample}_onlymm10.rmdup.stat
    hg19_log=${hg19_path}/${sample}_hg19.rmdup.stat

    ALLREADS=$(cat ${total_log}|grep "were paired; of these:$"|cut -d "(" -f 1|awk '{print $1*2}')
    hg19_READS=$(cat ${total_log}| sed 's/%//g' | awk '{printf $0"\t"}'  |cut -f 4,5,8,13,14 | \
    sed 's/\t/\n/g' | awk '{print $1}' | awk '{printf $0"\t"}'|awk '{print 2*($1+$2+$3)+$4+$5}')
    hg19_RATIO=$(cat ${total_log}|grep "overall alignment rate"|cut -d "%" -f 1)

    hg19_qc_READS=$(cat ${hg19_log}|grep "total (QC-passed reads"|cut -d " " -f 1)
    hg19_qc_RATIO=$(echo "${hg19_qc_READS}/${ALLREADS}"|bc -l)

    MM10_qc_READS=$(cat ${mm10_log}|grep "total (QC-passed reads"|cut -d " " -f 1)
    QC_reads=$(echo "${MM10_qc_READS}+${hg19_qc_READS}"|bc )
    MM10_qc_RATIO_intotal=$(echo "${MM10_qc_READS}/${ALLREADS}"|bc -l)
    MM10_qc_RATIO_inqc=$(echo "${MM10_qc_READS}/${QC_reads}"|bc -l)
    spike_factor=$(echo "($hg19_qc_READS/$MM10_qc_READS)/$spike_product"|bc -l)

    echo -e $sample"\t"$ALLREADS"\t"$hg19_READS"\t"$hg19_RATIO"\t"$hg19_qc_READS"\t"$hg19_qc_RATIO"\t"$MM10_qc_READS"\t"$QC_reads"\t"$MM10_qc_RATIO_intotal"\t"$MM10_qc_RATIO_inqc"\t"$spike_factor  >> ${logs_dir}/spike-input.txt
done


for file in ${sampledir}/IP*txt;
do
    input=`head -n 1 $file`
    spike_factor=$(grep $input ${logs_dir}/spike-input.txt | cut -f 11)
    cat $file|while read sample;do

    total_log=${align_path}/${sample}_align.log
    mm10_log=${mm10_path}/${sample}_onlymm10.rmdup.stat
    hg19_log=${hg19_path}/${sample}_hg19.rmdup.stat

    ALLREADS=$(cat ${total_log}|grep "were paired; of these:$"|cut -d "(" -f 1|awk '{print $1*2}')
    hg19_READS=$(cat ${total_log}| sed 's/%//g' | awk '{printf $0"\t"}'  |cut -f 4,5,8,13,14 | \
    sed 's/\t/\n/g' | awk '{print $1}' | awk '{printf $0"\t"}'|awk '{print 2*($1+$2+$3)+$4+$5}')
    hg19_RATIO=$(cat ${total_log}|grep "overall alignment rate"|cut -d "%" -f 1)

    hg19_qc_READS=$(cat ${hg19_log}|grep "total (QC-passed reads"|cut -d " " -f 1)
    hg19_qc_RATIO=$(echo "${hg19_qc_READS}/${ALLREADS}"|bc -l)

    MM10_qc_READS=$(cat ${mm10_log}|grep "total (QC-passed reads"|cut -d " " -f 1)
    QC_reads=$(echo "${MM10_qc_READS}+${hg19_qc_READS}"|bc )
    MM10_qc_RATIO_intotal=$(echo "${MM10_qc_READS}/${ALLREADS}"|bc -l)
    MM10_qc_RATIO_inqc=$(echo "${MM10_qc_READS}/${QC_reads}"|bc -l)
    SCALEFACTOR=$(echo "1/((${MM10_qc_READS}/1000000)*$spike_factor)" | bc -l )

    echo -e $sample"\t"$ALLREADS"\t"$hg19_READS"\t"$hg19_RATIO"\t"$hg19_qc_READS"\t"$hg19_qc_RATIO"\t"$MM10_qc_READS"\t"$QC_reads"\t"$MM10_qc_RATIO_intotal"\t"$MM10_qc_RATIO_inqc"\t"$SCALEFACTOR >> ${logs_dir}/scalefactor.txt
    done
done



wait


#step 4.1
### Making RPKM-normalized bigWig files with full-length reads without spike-in ###
echo -e "\n***************************\ntracks need to be done....\n***************************"

mkdir -p ${bw_fulllength_dir}

cat  ${logs_dir}/scalefactor.txt | while read id;
do
arr=($id)
sample=${arr[0]}
scalefactor=${arr[10]}
bam_file=${exp_bam_rmdup}/${sample}_hg19.rmdup.bam

    if [ ! -s "${bw_fulllength_dir}/${sample}_fulllength.bw" ]
    then
        bamCoverage -b ${bam_file} \
        --binSize 1 \
        --blackListFileName  ${blacklist} \
        --normalizeUsing None \
        --scaleFactor  $scalefactor \
        --numberOfProcessors 23 \
        -o ${bw_fulllength_dir}/${sample}_fulllength.bw 2>${bw_fulllength_dir}/${sample}.log
    fi
done


      
#step 5.1
###call peak
echo -e "\n***************************\ncall-peak begins at $(date +%Y"-"%m"-"%d" "%H":"%M":"%S); control-IP-peak need to be done....\n***************************"

mkdir -p ${peak_log_dir}
mkdir -p ${peak_alone_dir}
mkdir -p ${peak_compare_dir}

####without input
nohup_number=0
cat  ${logs_dir}/scalefactor.txt | while read id;
do
arr=($id)
sample=${arr[0]}
scalefactor=${arr[10]}
bam_file=${exp_bam_rmdup}/${sample}_hg19.rmdup.bam
if [ ! -s ${peak_alone_dir}/${sample}_alone_peaks.narrowPeak ]
then
    macs2 callpeak -t $bam_file -f BAMPE -n ${sample}_alone -g hs --keep-dup all --outdir ${peak_alone_dir} \
    2> ${peak_log_dir}/${sample}_alone.log

    nohup_number=`echo $nohup_number+1 | bc`
        fi

    
    if [[ $nohup_number -eq 2 ]]
    then
        wait
        echo "waiting..."
        nohup_number=0
    fi

done

wait

nohup_number=0
cat  ${logs_dir}/scalefactor.txt | while read id;
do
arr=($id)
sample=${arr[0]}
if [ ! -s ${peak_alone_dir}/${sample}_alone_peaks.final.narrowPeak ]
then
    bedtools intersect -a ${peak_alone_dir}/${sample}_alone_peaks.narrowPeak \
    -b $blacklist \
    -f 0.25 -v > ${peak_alone_dir}/${sample}_alone_peaks.final.narrowPeak


    nohup_number=`echo $nohup_number+1 | bc`
fi

    if [[ $nohup_number -eq 27 ]]
    then
        wait
        echo "waiting..."
        nohup_number=0
    fi

done

wait



#### with input as control
nohup_number=0
for file in ${sampledir}/IP*txt;
do
    input=`head -n 1 $file`
    input_bam=${exp_bam_rmdup}/${input}_hg19.rmdup.bam
    sed 1d $file|cat |while read sample ;
    do
        if [ ! -s ${peak_compare_dir}/${sample}_compare_peaks.narrowPeak ]
        then 
            IP_bam=${exp_bam_rmdup}/${sample}_hg19.rmdup.bam 
            macs2 callpeak -c $input_bam \
                           -t $IP_bam \
                           -f BAMPE -n ${sample}_compare -g hs --keep-dup all --outdir ${peak_compare_dir} \
                           2> ${peak_log_dir}/${sample}_compare.log

            nohup_number=`echo $nohup_number+1 | bc`
        fi

    
    if [[ $nohup_number -eq 2 ]]
    then
        wait
        echo "waiting..."
        nohup_number=0
    fi
  done
done

wait

# 由于input没有对比，这里input的样本会报错，不过不影响结果
nohup_number=0
cat  ${logs_dir}/scalefactor.txt | while read id;
do
arr=($id)
sample=${arr[0]}
if [ ! -s ${peak_compare_dir}/${sample}_compare_peaks.final.narrowPeak ]
then
    bedtools intersect -a ${peak_compare_dir}/${sample}_compare_peaks.narrowPeak \
    -b $blacklist \
    -f 0.25 -v > ${peak_compare_dir}/${sample}_compare_peaks.final.narrowPeak
    nohup_number=`echo $nohup_number+1 | bc`
fi


    if [[ $nohup_number -eq 27 ]]
    then
        wait
        echo "waiting..."
        nohup_number=0
    fi

done

wait

input_peak=`ls ${peak_compare_dir}/*Input*.final.narrowPeak`
rm -rf ${input_peak}