#!/share/home/suifengrui/miniconda3/envs/r4.2.1-chip-seq_env/bin/Rscript

args <- commandArgs(trailingOnly = TRUE)

arg_list <- list()
for (i in seq(1, length(args), 2)) {
  arg_list[[args[[i]]]] <- args[[i + 1]]
}

file_path <- arg_list[["--filepath"]]
out_path <- arg_list[["--outpath"]]

file_path <- strsplit(file_path, ",")[[1]]

print(file_path)
print(out_path)

library(rtracklayer)
library(tidyverse)
library(data.table)
library(GenomicFeatures)
library(AnnotationDbi)
library(GenomicRanges)

merge_granges_list <- function(granges_list) {
  # 合并所有GRanges对象，并将score列设置为0
  combined <- do.call(c, granges_list)
  
  # 使用disjoin函数将所有GRanges对象分割为不重叠的区域
  disjoined <- disjoin(combined)
  disjoined$score <- 0
  
  # 遍历所有原始GRanges对象，找到与分割区域之间的重叠关系并更新score值
  for (gr in granges_list) {
    overlaps <- findOverlaps(disjoined, gr)
    disjoined[queryHits(overlaps)]$score <- disjoined[queryHits(overlaps)]$score + gr$score[subjectHits(overlaps)]
  }
  
  return(disjoined)
}

merge_bigwig_files <- function(input_filenames, output_filename) {
  # 将所有的bigwig文件导入为GRanges对象
  gr_list <- lapply(input_filenames, function(filename) {
    gr <- import(filename, format = "BigWig")
  })
  
  # 使用merge_granges_list函数合并所有的GRanges对象
  merged_granges <- merge_granges_list(gr_list)
  
  # 将合并的GRanges对象导出为BigWig文件
  export(merged_granges, con = output_filename, format = "BigWig")
}
{
  input_filenames <- file_path
  output_filename <- out_path
  merge_bigwig_files(input_filenames, output_filename)
}
