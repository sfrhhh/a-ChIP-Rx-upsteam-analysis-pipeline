#!/bin/bash

echo "Usage:"
echo "   01_process-before-map.sh file_path"
echo ""

file_path=$1
if test -z $file_path
then
   echo "please input the absolute file_path"
   exit
fi

# contains fastqc of rawdata, trim_galore of rawdata and fastqc of data trimmed

# log on compute-mode, should process on command line
# ssh cpu001
# password: proc%10460

# activate environment, use chip-seq anlysis is enough
# conda activate chip-seq_env

file_path=${file_path}
logs_dir=${file_path}/logs

#step 1.2
####fastqc of raw data ####
raw_dir=${file_path}/00_rawdata
fastqc_dir=${file_path}/01_rawfastqc

mkdir -p ${fastqc_dir}

in_path=${raw_dir}
out_path=${fastqc_dir}

nohup_number=0
for file in `ls ${in_path}/*R1.fastq.gz`
do
    ID=$(basename $file) # 无论输入是什么路径，最终保留文件名字
    fq1=${file}
    fq2=${file/R1/R2}
    if [ ! -s ${out_path}/"${ID/.fastq.gz/_fastqc.zip}" ] # 条件测试，文件存在且不为0为真
    then
        echo "Generating file: $path/00-1_rawFastqc/"${ID}_R1_fastqc.zip"..."
        fastqc $fq1 -t 1  -o ${out_path}/  &
        fastqc $fq2 -t 1  -o ${out_path}/  &
        nohup_number=`echo $nohup_number+2 | bc` 
    fi
    
    if [[ $nohup_number -eq 28 ]] 
    then
        wait
        echo "waiting..."
        nohup_number=0
    fi
done

wait

#step 1.3
### merge reports of fastqc
multiqc ${fastqc_dir}/ -n rawdata_multiqc -o ${fastqc_dir}/ # -n参数为报告文件名，multiqc是整合质控结果的工具


#step 2.1
### Trimming adapters  (trim_galore)
trimmedFastq_dir=${file_path}/02_trimmeddata
trimmedFastq_log_dir=${file_path}/logs/trimmeddata

mkdir -p ${trimmedFastq_dir}
mkdir -p ${trimmedFastq_log_dir}

nohup_number=0
for fq1 in `ls ${raw_dir}/*R1.fastq.gz`
do
    fq2=${fq1/R1.fastq.gz/R2.fastq.gz}
    if [ ! -s ${trimmedFastq_dir}/"$(basename ${fq1/R1.fastq.gz/trimmed_R1.fq.gz})" ]
    then
        trim_galore -q 25 --phred33 --length 36 -e 0.1 --stringency 4 --paired -o ${trimmedFastq_dir} $fq1 $fq2 \
        --clip_R1 34 --clip_R2 10 -a CTGTCTCTTATACAC -a2 CTGTCTCTTATACAC \
        > ${trimmedFastq_log_dir}/"$(basename ${fq1/_R1.fastq.gz/_trimmed.log})" 2>&1 &

        nohup_number=`echo $nohup_number+1 | bc`
    fi

   
    if [[ $nohup_number -eq 28 ]]
    then
        wait
        echo "waiting..."
        nohup_number=0
    fi
done

wait

#step 2.2
### Cleaning up filenames in trimmedFastq (bowtie automatically names PE --un output)

for FILE in ${trimmedFastq_dir}/*1.fq.gz
do
    if [ ! -s ${FILE/R1_val_1.fq.gz/trimmed_R1.fq.gz} ]
    then
        mv "$FILE" ${FILE/R1_val_1.fq.gz/trimmed_R1.fq.gz}
    fi
done

for FILE in ${trimmedFastq_dir}/*2.fq.gz
do 
    if [ ! -s ${FILE/R2_val_2.fq.gz/trimmed_R2.fq.gz} ]
    then
        mv "$FILE" ${FILE/R2_val_2.fq.gz/trimmed_R2.fq.gz}
    fi
done

#step 2.3
#####qc for trimmed data####
trimmeddata_fastqc_dir=${file_path}/02_trimmeddata_fastqc

mkdir -p ${trimmeddata_fastqc_dir}

nohup_number=0
for file in `ls ${trimmedFastq_dir}/*R1.fq.gz`
do
    ID=$(basename $file)
    fq1=${file}
    fq2=${file/R1/R2}
    if [ ! -s ${trimmeddata_fastqc_dir}/"${ID/.fq.gz/_fastqc.html}" ]
    then
    echo "Generating file: ${trimmeddata_fastqc_dir}/"${ID/.fq.gz/_fastqc.html}"..."
    fastqc $fq1 -t 1  -o ${trimmeddata_fastqc_dir}/  &
    fastqc $fq2 -t 1  -o ${trimmeddata_fastqc_dir}/  &

     nohup_number=`echo $nohup_number+2 | bc`
    fi
   
    if [[ $nohup_number -eq 28 ]]
    then
        wait
        echo "waiting..."
        nohup_number=0
    fi
done



wait

### merge reports of fastqc
multiqc ${trimmeddata_fastqc_dir}/ -n trimmeddata_multiqc -o ${trimmeddata_fastqc_dir}/


