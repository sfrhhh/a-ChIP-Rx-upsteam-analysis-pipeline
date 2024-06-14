#!/share/home/suifengrui/miniconda3/envs/r4.2.1-chip-seq_env/bin/Rscript
#parse parameter
library(argparser,quietly = TRUE)
#Creat a parser
p <- arg_parser("run log2FC")
#Add command line argumnets

p<-add_argument(p,"--filepath",help="input: mat file path",type="character")

argv<-parse_args(p)
file_path <- argv$filepath

TSS_log2 <- paste0(file_path, "/matrix_TSS_sort_col7-.mat")
TSS2TES_log2 <- paste0(file_path, "/matrix_TSS2TES_sort_col7-.mat")

library(data.table)
library(tidyverse)

TSS_log2_data <- fread(TSS_log2) %>% as.matrix()
TSS2TES_log2_data <- fread(TSS2TES_log2) %>% as.matrix()

split_matrix <- function(mat, n_cols) {
  n_splits <- ceiling(ncol(mat) / n_cols)
  split_list <- vector("list", n_splits)
  
  for (i in 1:n_splits) {
    start_col <- (i - 1) * n_cols + 1
    end_col <- min(i * n_cols, ncol(mat))
    split_list[[i]] <- mat[, start_col:end_col]
  }
  
  return(split_list)
}

# TSS-分割矩阵
# 使用函数将矩阵mat分割成每100列的子矩阵
TSS_mat_splits <- split_matrix(TSS_log2_data, 100)
# 将分割后的子矩阵分配给变量
for (i in 1:length(TSS_mat_splits)) {
  assign(paste0("TSS_log2_data", i), TSS_mat_splits[[i]])
}

# 假设您有n个矩阵，我们需要将这些矩阵存储在一个列表中
# 这里我们创建一些示例数据
n <- length(TSS_mat_splits)
TSS_mat_list <- list()
for (i in 1:n) {
  TSS_mat_list[[i]] <- get(paste0("TSS_log2_data", i))
}

# 初始化一个空矩阵，用于存储合并后的差值矩阵
TSS_merged_diff_mat <- matrix(nrow = nrow(TSS_mat_list[[1]]), ncol = 0)

# 计算差值矩阵并合并
for (i in 1:length(TSS_mat_list)) {
  TSS_diff_mat <- log2((TSS_mat_list[[i]]+1)/(TSS_mat_list[[1]]+1))
  TSS_merged_diff_mat <- cbind(TSS_merged_diff_mat, TSS_diff_mat)
}
TSS_merged_diff_mat <- TSS_merged_diff_mat %>% as.data.table()

fwrite(TSS_merged_diff_mat, paste0(file_path, "/matrix_TSS_log2FC_sort_col7-.mat"),
       col.names = FALSE, sep = "\t")

# TES-分割矩阵
# 使用函数将矩阵mat分割成每100列的子矩阵
TSS2TES_mat_splits <- split_matrix(TSS2TES_log2_data, 120)
# 将分割后的子矩阵分配给变量
for (i in 1:length(TSS2TES_mat_splits)) {
  assign(paste0("TSS2TES_log2_data", i), TSS2TES_mat_splits[[i]])
}

# 假设您有n个矩阵，我们需要将这些矩阵存储在一个列表中
# 这里我们创建一些示例数据
n <- length(TSS2TES_mat_splits)
TSS2TES_mat_list <- list()
for (i in 1:n) {
  TSS2TES_mat_list[[i]] <- get(paste0("TSS2TES_log2_data", i))
}

# 初始化一个空矩阵，用于存储合并后的差值矩阵
TSS2TES_merged_diff_mat <- matrix(nrow = nrow(TSS2TES_mat_list[[1]]), ncol = 0)

# 计算差值矩阵并合并
for (i in 1:length(TSS2TES_mat_list)) {
  TSS2TES_diff_mat <- log2((TSS2TES_mat_list[[i]]+1)/(TSS2TES_mat_list[[1]]+1))
  TSS2TES_merged_diff_mat <- cbind(TSS2TES_merged_diff_mat, TSS2TES_diff_mat)
}
TSS2TES_merged_diff_mat <- TSS2TES_merged_diff_mat %>% as.data.table()

fwrite(TSS2TES_merged_diff_mat, paste0(file_path, "/matrix_TSS2TES_log2FC_sort_col7-.mat"),
       col.names = FALSE, sep = "\t")
