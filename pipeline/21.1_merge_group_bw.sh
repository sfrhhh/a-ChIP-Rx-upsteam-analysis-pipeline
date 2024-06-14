#!/bin/bash
####################################################################################################
##########################################   merge_bw  #############################################
####################################################################################################

echo "Usage:"
echo "   21.1_merge_group_bw.sh file_path sampleinfo_file is_strand_specific"
echo '   file_path为bw文件的路径，即如果ls ${file_path}/*.bw，输出需要为所有bw文件的绝对路径'
echo '   sampleinfo_file为sampleinfo.txt的路径，这里的sampleinfo的第三列为平行组别'
echo '   这个脚本只考虑了chipseq的情况，链特异性的时候，还是重写一下吧,到时候可能需要加一个参数(加完了,t/f)'
echo ""

file_path=$1
if test -z $file_path
then
   echo "please input the absolute file_path"
   exit
fi

sampleinfo=$2
if test -z $sampleinfo
then
   echo "please input the absolute sampleinfo"
   exit
fi

is_strand_specific=$3
if test -z $is_strand_specific
then
   echo "please input the is_strand_specific(t/f)"
   exit
fi

mkdir -p ${file_path}/bw_merge_group

if [ $is_strand_specific == "f" ]
then
# source /share/home/suifengrui/miniconda3/bin/activate chip-seq_env
# 这是用我写的函数做的，有点慢
    cat $sampleinfo | cut -f 3 | sort | uniq | while read group;do
    if [ ! -s ${file_path}/bw_merge_group/${group}.bw ]
    then
      file_path_str=$(printf "%s," ${file_path}/*${group}*.bw | sed 's/,$//' | sed 's/"\r"//g')
      merge_bigwig.R --filepath ${file_path_str} --outpath ${file_path}/bw_merge_group/${group}.bw \
      > ${file_path}/bw_merge_group/${group}.mergeLog 2>&1
      date
    fi
      done

else
  cat $sampleinfo | cut -f 3 | uniq | while read group;do
  
    if [ ! -s ${file_path}/bw_merge_group/${group}_fwd.bw ]
    then
      file_path_str_fwd=$(printf "%s," ${file_path}/*${group}*fwd*.bw | sed 's/,$//' | sed 's/"\r"//g')
      merge_bigwig.R --filepath ${file_path_str_fwd} --outpath ${file_path}/bw_merge_group/${group}_fwd.bw \
      > ${file_path}/bw_merge_group/${group}_fwd.mergeLog 2>&1
      date
    fi
      
    if [ ! -s ${file_path}/bw_merge_group/${group}_rev.bw ]
    then
      file_path_str_rev=$(printf "%s," ${file_path}/*${group}*rev*.bw | sed 's/,$//' | sed 's/"\r"//g')
      merge_bigwig.R --filepath ${file_path_str_rev} --outpath ${file_path}/bw_merge_group/${group}_rev.bw \
      > ${file_path}/bw_merge_group/${group}_rev.mergeLog 2>&1
      date
    fi
  done

fi