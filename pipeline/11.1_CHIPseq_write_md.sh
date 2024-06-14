####################################################################################################
##################################   11.1_CHIPseq_write_md #########################################
####################################################################################################

echo "Usage:"
echo "   11.1_CHIPseq_write_md.sh file_path control_sample"
echo "   control_sample注意要在样本信息表第二列内"
echo "   下载时, 下载data1的记录文件夹内的东西,note中的plotpie目录和md文件"
echo "   上传网盘时, 上传data1的记录文件夹内的东西"
echo ""

file_path=$1
if test -z $file_path
then
   echo "please input the absolute file_path"
   exit
fi

control_sample=$2
if test -z $control_sample
then
   echo "please input the control_sample"
   exit
fi

source /share/home/suifengrui/miniconda3/bin/activate chip-seq_env

file_name=$(basename $file_path)
mkdir -p ${file_path}/note
note_path=${file_path}/note/${file_name}.md

if [ -s ${note_path} ]
then
    rm -rf ${note_path}
fi

touch ${note_path}

target_file_path=/data1/xulab/suifengrui/data_bulk/chip-seq/${file_name}
mkdir -p ${target_file_path}

cp -n -r ${file_path}/04_bw_fulllength ${target_file_path}
cp -n -r ${file_path}/05_peak ${target_file_path}
cp -n ${file_path}/01_rawfastqc/rawdata_multiqc.html ${target_file_path}
cp -n ${file_path}/02_trimmeddata_fastqc/trimmeddata_multiqc.html ${target_file_path}

# 输出文件头
echo "# ${file_name}" >> ${note_path}
echo "### 文件存放目录" >> ${note_path}
echo "rawdata_multiqc.html 是原始fastq文件质控结果" >> ${note_path}
echo "trimmeddata_multiqc.html 是去接头的fastq文件质控结果" >> ${note_path}
echo "04_bw_fulllength 是bigwig文件存放位置" >> ${note_path}
echo "05_peak 是narrowpeak文件存放位置" >> ${note_path}
echo "###### 服务器目录" >> ${note_path}
echo "${target_file_path}" >> ${note_path}
echo "" >> ${note_path}
echo "###### 百度网盘链接" >> ${note_path}
echo "本行替换为百度网盘链接" >> ${note_path}
echo "" >> ${note_path}

# 输出比对率
echo "### 比对率" >> ${note_path}
echo "参考基因组: hg19" >> ${note_path}
echo "" >> ${note_path}

echo "样本id | 样本处理 | hg19比对率 | mm10比对率 | 总比对率" >> ${note_path}
echo ':--:|:--:|:--:|:--:|:--:' >> ${note_path}

cat ${file_path}/sampleinfo.txt | while read sample_line;
do
    arr=($sample_line)
    sample_id=${arr[0]}
    sample_process=${arr[1]}

    hg19_percent_line=$(cat `ls ${file_path}/logs/align_hg19/* | grep ${sample_process}` | tail -1)
    hg19_percent=`echo $hg19_percent_line |cut -d " " -f 1 | cut -d "%" -f 1`

    mm10_percent_line=$(cat `ls ${file_path}/logs/align_mm10/* | grep ${sample_process}` | tail -1)
    mm10_percent=`echo $mm10_percent_line |cut -d " " -f 1 | cut -d "%" -f 1`

    total_percent=`echo ${mm10_percent} + ${hg19_percent} | bc`
    echo "${sample_id} | ${sample_process} | ${hg19_percent}% | ${mm10_percent}% | ${total_percent}% " >> ${note_path}
done

echo "" >> ${note_path}
echo "在此输入比对率评价" >> ${note_path}
echo "" >> ${note_path}

# 输出callpeak
echo "### callpeak" >> ${note_path}

all_sample=$(cat ${file_path}/sampleinfo.txt | cut -f 2 | grep -v Input | tr -s "\n" " " | sed "s/IP_//g" | sed "s/ /, /g")

peak_num=""
samples=$(cat ${file_path}/sampleinfo.txt | cut -f 2 | grep -v Input)

for sample in $samples; do
    peak_file=$(ls ${file_path}/05_peak/05.2_peak_compare/*.final.narrowPeak | grep ${sample})
    sample_peak_line=$(wc -l ${peak_file} | cut -d " " -f 1)
    peak_num="${peak_num} ${sample_peak_line},"
done

echo -n "${all_sample}" >> ${note_path}
echo -n "样本的peaks数目分别为" >> ${note_path}
echo "${peak_num}" >> ${note_path}
echo "在此输入根据peak数目得到的信息" >> ${note_path}
echo "" >> ${note_path}

echo -n "以下为所有peaks的注释结果，图中启动子区域定义为TSS上游100bp下游300bp" >> ${note_path}
echo -n "，按从上至下的顺序分别为" >> ${note_path}
echo "${all_sample}" >> ${note_path}
echo "在此输入根据注释结果得出的结论" >> ${note_path}

peak_compare_path=${file_path}/05_peak/05.2_peak_compare
01.3_peakanno.R --filepath ${peak_compare_path}

cp -r ${peak_compare_path}/peaks_annotation_plotpie ${file_path}/note

cat ${file_path}/sampleinfo.txt | cut -f 2 | grep -v Input | while read sample;
do
    plot_name=`ls ${file_path}/note/peaks_annotation_plotpie/* | grep ${sample}`
    name_md=`basename ${plot_name}`
    echo "@import \"./peaks_annotation_plotpie/${name_md}\"" >> ${note_path}
done
echo ""  >> ${note_path}

# plot_igv
# 这步有点复杂了，打算在本地画，就igv截个图就行
mkdir -p ${file_path}/note/igv

# igv可视化bw文件
echo "igv-bigwig截图(部分区域), spike_factor=1e6/mm10_qc_reads" >> ${note_path}
echo "此处输入图形得到的信息" >> ${note_path}
echo "@import \"./igv/bw.svg\"" >> ${note_path}
echo "" >> ${note_path}

# igv可视化peak文件
echo "igv-peak截图(相同区域)" >> ${note_path}
echo "此处输入图形得到的信息" >> ${note_path}
echo "@import \"./igv/peak.svg\"" >> ${note_path}
echo "" >> ${note_path}

echo "igv-peak截图(2号染色体)" >> ${note_path}
echo "此处输入图形得到的信息" >> ${note_path}
echo "@import \"./igv/peak_chr2.svg\"" >> ${note_path}
echo '<div STYLE="page-break-after: always;"></div>' >> ${note_path}
echo "" >> ${note_path}

# 下游
echo "### 下游分析" >> ${note_path}
echo "下游分析的固定流程包括: 1. 绘制TSS上下游5kb的信号图profile"
echo "                      2. 绘制TSS上下游5kb的信号图heatmap"
echo "                      3. 绘制TSS上下游5kb的信号图log2FC的heatmap"
echo "                      4. 绘制TSS-TES上游5k、下游10k的信号图profile"
echo "                      5. 绘制TSS-TES上游5k、下游10k的信号图heatmap"
echo "                      6. 绘制TSS-TES上游5k、下游10k的信号图log2FC的heatmap"

mkdir -p ${file_path}/06_plot_signal_TSS
mkdir -p ${file_path}/06_plot_signal_TSS2TES
bed_DLD1=/work/xulab/suifengrui/reference/annotation/ucsc/promoter/hg19_ucsc_refseq_transcript_fwd_and_rev_sense.bed

bw_path=${file_path}/04_bw_fulllength
control_bw=`ls ${bw_path}/*.bw | grep -v Input | grep ${control_sample}`
treat_sample=`cat $file_path/sampleinfo.txt | cut -f 2 | grep -v Input | grep -v ${control_sample} | tr -s "\n" " "| sed 's/IP_//g'`

treat_bw=""
for value in $treat_sample; do
    new_value="${file_path}/04_bw_fulllength/IP_${value}_fulllength.bw"
    treat_bw+="$new_value "
done

###### TSS
computeMatrix reference-point --referencePoint TSS -p 24 -b 5000 -a 5000 \
    -R ${bed_DLD1} \
    -S ${control_bw} ${treat_bw} \
    --binSize 100 --missingDataAsZero --skipZeros \
    -o ${file_path}/06_plot_signal_TSS/matrix_TSS.mat.gz > /dev/null 2>&1

plotHeatmap -m ${file_path}/06_plot_signal_TSS/matrix_TSS.mat.gz \
    -out ${file_path}/06_plot_signal_TSS/heatmap_TSS.svg \
    --colorMap 'Blues' \
    --outFileSortedRegions ${file_path}/06_plot_signal_TSS/heatmap_TSS.bed \
    --outFileNameMatrix ${file_path}/06_plot_signal_TSS/matrix_TSS_sort.mat.gz \
    --missingDataColor "white" \
    --refPointLabel TSS \
    --samplesLabel  ${control_sample/IP_/} ${treat_sample} \
    --sortUsingSamples 1 \
    --heatmapHeight 16 \
    --whatToShow "heatmap and colorbar" \
    --plotFileFormat svg --dpi 720

plotProfile -m ${file_path}/06_plot_signal_TSS/matrix_TSS.mat.gz \
    --perGroup \
    --refPointLabel TSS \
    --samplesLabel  ${control_sample/IP_/} ${treat_sample} \
    -out ${file_path}/06_plot_signal_TSS/profile_TSS.svg \
    --plotHeight 16  --plotWidth 20 \
    --plotFileFormat svg

mkdir -p ${file_path}/note/profile
mkdir -p ${file_path}/note/heatmap

cp -n ${file_path}/06_plot_signal_TSS/heatmap_TSS.svg ${file_path}/note/heatmap
cp -n ${file_path}/06_plot_signal_TSS/profile_TSS.svg ${file_path}/note/profile

###### TSS2TES
computeMatrix scale-regions -p 24 -b 5000 -a 10000 \
    -R ${bed_DLD1} \
    -S ${control_bw} ${treat_bw} \
    --regionBodyLength 15000 \
    --binSize 250 --missingDataAsZero --skipZeros \
    -o ${file_path}/06_plot_signal_TSS2TES/matrix_TSS2TES.mat.gz > /dev/null 2>&1

plotHeatmap -m ${file_path}/06_plot_signal_TSS2TES/matrix_TSS2TES.mat.gz \
    -out ${file_path}/06_plot_signal_TSS2TES/heatmap_TSS2TES.svg \
    --colorList 'white,#083772' \
    --outFileSortedRegions ${file_path}/06_plot_signal_TSS2TES/heatmap_TSS2TES.bed \
    --outFileNameMatrix ${file_path}/06_plot_signal_TSS2TES/matrix_TSS2TES_sort.mat.gz \
    --missingDataColor "white" \
    --refPointLabel TSS \
    --samplesLabel  ${control_sample/IP_/} ${treat_sample} \
    --sortUsingSamples 1 \
    --heatmapHeight 16 \
    --whatToShow "heatmap and colorbar" \
    --plotFileFormat svg --dpi 720

plotProfile -m ${file_path}/06_plot_signal_TSS2TES/matrix_TSS2TES.mat.gz \
    --perGroup \
    --refPointLabel TSS \
    --samplesLabel  ${control_sample/IP_/} ${treat_sample} \
    -out ${file_path}/06_plot_signal_TSS2TES/profile_TSS2TES.svg \
    --plotHeight 16  --plotWidth 20 \
    --plotFileFormat svg

cp -n ${file_path}/06_plot_signal_TSS2TES/heatmap_TSS2TES.svg ${file_path}/note/heatmap
cp -n ${file_path}/06_plot_signal_TSS2TES/profile_TSS2TES.svg ${file_path}/note/profile

###### log2FC
log2FC_path=${file_path}/06_plot_signal_log2FC

mkdir -p ${log2FC_path}
cp -n ${file_path}/06_plot_signal_TSS2TES/matrix_TSS2TES_sort.mat.gz ${log2FC_path}
cp -n ${file_path}/06_plot_signal_TSS/matrix_TSS_sort.mat.gz ${log2FC_path}

###### log2FC of TSS
zcat ${log2FC_path}/matrix_TSS_sort.mat.gz | cut -f 7- | sed '1d' > ${log2FC_path}/matrix_TSS_sort_col7-.mat
zcat ${log2FC_path}/matrix_TSS_sort.mat.gz | cut -f 1-6 | sed '1d' > ${log2FC_path}/matrix_TSS_sort_col1-6.mat
zcat ${log2FC_path}/matrix_TSS_sort.mat.gz | head -1 > ${log2FC_path}/matrix_TSS_sort_head.mat
###### log2FC of TSS2TES
zcat ${log2FC_path}/matrix_TSS2TES_sort.mat.gz | cut -f 7- | sed '1d' > ${log2FC_path}/matrix_TSS2TES_sort_col7-.mat
zcat ${log2FC_path}/matrix_TSS2TES_sort.mat.gz | cut -f 1-6 | sed '1d' > ${log2FC_path}/matrix_TSS2TES_sort_col1-6.mat
zcat ${log2FC_path}/matrix_TSS2TES_sort.mat.gz | head -1 > ${log2FC_path}/matrix_TSS2TES_sort_head.mat

###### compute matrix
01.4_plotLog2Heamap.R --filepath ${log2FC_path}

paste ${log2FC_path}/matrix_TSS_sort_col1-6.mat ${log2FC_path}/matrix_TSS_log2FC_sort_col7-.mat > ${log2FC_path}/matrix_TSS_log2FC_sort_nohead.mat
cat ${log2FC_path}/matrix_TSS_sort_head.mat ${log2FC_path}/matrix_TSS_log2FC_sort_nohead.mat > ${log2FC_path}/matrix_TSS_log2FC_sort.mat
gzip ${log2FC_path}/matrix_TSS_log2FC_sort.mat
rm -rf ${log2FC_path}/matrix_TSS_log2FC_sort_nohead.mat ${log2FC_path}/matrix_TSS_sort_col1-6.mat
rm -rf ${log2FC_path}/matrix_TSS_sort_col7-.mat
rm -rf ${log2FC_path}/matrix_TSS_sort_head.mat
rm -rf ${log2FC_path}/matrix_TSS_log2FC_sort_col7-.mat

paste ${log2FC_path}/matrix_TSS2TES_sort_col1-6.mat ${log2FC_path}/matrix_TSS2TES_log2FC_sort_col7-.mat > ${log2FC_path}/matrix_TSS2TES_log2FC_sort_nohead.mat
cat ${log2FC_path}/matrix_TSS2TES_sort_head.mat ${log2FC_path}/matrix_TSS2TES_log2FC_sort_nohead.mat > ${log2FC_path}/matrix_TSS2TES_log2FC_sort.mat
gzip ${log2FC_path}/matrix_TSS2TES_log2FC_sort.mat
rm -rf ${log2FC_path}/matrix_TSS2TES_log2FC_sort_nohead.mat ${log2FC_path}/matrix_TSS2TES_sort_col1-6.mat
rm -rf ${log2FC_path}/matrix_TSS2TES_sort_col7-.mat
rm -rf ${log2FC_path}/matrix_TSS2TES_sort_head.mat
rm -rf ${log2FC_path}/matrix_TSS2TES_log2FC_sort_col7-.mat

###### plot heatmap
plotHeatmap -m ${log2FC_path}/matrix_TSS_log2FC_sort.mat.gz \
    -out ${log2FC_path}/heatmap_TSS_log2FC_sort.svg \
    --colorList "#181b4b,#252876,#2d2f90,#2e2f90,#302f8d,#312e8d,#372c8d,#352d8d,#382c90,#3d3494,#4f48a3,#625fb2,#7e7bc1,#9894d0,#b7b5e0,#deddee,white,#f5c4c9,#f194a0,#ee7280,#ec5765,#e03c48,#e82f36,#eb2325,#e72522,#e72322,#e51e22,#d71d20,#c3171d,#b2151a,#9f121a,#8b0f18,#700c14" \
    --missingDataColor "white" \
    --refPointLabel TSS \
    --samplesLabel  ${control_sample/IP_/} ${treat_sample} \
    --sortUsingSamples 1 \
    --heatmapHeight 16 \
    --whatToShow "heatmap and colorbar" \
    --plotFileFormat svg --dpi 720 \
    --sortUsingSamples 1 \
    --sortRegions keep \
    --zMax 2 --zMin -2
    
plotHeatmap -m ${log2FC_path}/matrix_TSS2TES_log2FC_sort.mat.gz \
    -out ${log2FC_path}/heatmap_TSS2TES_log2FC_sort.svg \
    --colorList "#181b4b,#252876,#2d2f90,#2e2f90,#302f8d,#312e8d,#372c8d,#352d8d,#382c90,#3d3494,#4f48a3,#625fb2,#7e7bc1,#9894d0,#b7b5e0,#deddee,white,#f5c4c9,#f194a0,#ee7280,#ec5765,#e03c48,#e82f36,#eb2325,#e72522,#e72322,#e51e22,#d71d20,#c3171d,#b2151a,#9f121a,#8b0f18,#700c14" \
    --missingDataColor "white" \
    --refPointLabel TSS \
    --samplesLabel  ${control_sample/IP_/} ${treat_sample} \
    --sortUsingSamples 1 \
    --heatmapHeight 16 \
    --whatToShow "heatmap and colorbar" \
    --plotFileFormat svg --dpi 720 \
    --sortUsingSamples 1 \
    --sortRegions keep \
    --zMax 2 --zMin -2 

mkdir -p ${file_path}/note/log2FC
cp -n ${log2FC_path}/heatmap_TSS_log2FC_sort.svg ${file_path}/note/log2FC/
cp -n ${log2FC_path}/heatmap_TSS2TES_log2FC_sort.svg ${file_path}/note/log2FC/

## plotProfile_TSS
echo "###### profile TSS plot" >> ${note_path}
echo "在此输入profile_TSS图的分析" >> ${note_path}
echo "@import \"./profile/profile_TSS.svg\"" >> ${note_path}
echo '<div STYLE="page-break-after: always;"></div>' >> ${note_path}
echo "" >> ${note_path}

## plotHeatmap_TSS
echo "###### heatmap TSS plot" >> ${note_path}
echo "在此输入heatmap_TSS图的分析" >> ${note_path}
echo "@import \"./heatmap/heatmap_TSS.svg\"" >> ${note_path}
echo '<div STYLE="page-break-after: always;"></div>' >> ${note_path}
echo "" >> ${note_path}

## plotHeatmap_TSS_log2FC
echo "###### Heatmap_TSS_log2FC plot" >> ${note_path}
echo "在此输入heatmap_TSS_log2FC图的分析" >> ${note_path}
echo "@import \"./log2FC/heatmap_TSS_log2FC_sort.svg\"" >> ${note_path}
echo '<div STYLE="page-break-after: always;"></div>' >> ${note_path}
echo "" >> ${note_path}

## plotProfile_TSS2TES
echo "###### profile TSS2TES plot" >> ${note_path}
echo "在此输入profile_TSS2TES图的分析" >> ${note_path}
echo "@import \"./profile/profile_TSS2TES.svg\"" >> ${note_path}
echo '<div STYLE="page-break-after: always;"></div>' >> ${note_path}
echo "" >> ${note_path}

## plotHeatmap_TSS2TES
echo "###### heatmap TSS2TES plot" >> ${note_path}
echo "在此输入heatmap_TSS2TES图的分析" >> ${note_path}
echo "@import \"./heatmap/heatmap_TSS2TES.svg\"" >> ${note_path}
echo '<div STYLE="page-break-after: always;"></div>' >> ${note_path}
echo "" >> ${note_path}

## plotHeatmap_TSS2TES_log2FC
echo "###### heatmap_TSS2TES_log2FC plot" >> ${note_path}
echo "在此输入heatmap_TSS2TES_log2FC图的分析" >> ${note_path}
echo "@import \"./log2FC/heatmap_TSS2TES_log2FC_sort.svg\"" >> ${note_path}
echo "" >> ${note_path}

# 总结
echo "### 总结" >> ${note_path}
echo "在此输入总结" >> ${note_path}

# 结束
echo "finish write md"