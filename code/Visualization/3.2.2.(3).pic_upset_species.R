###R 4.2.3
###liangweiting
###20250227
###drawing upset of protential plactis spcies in different part

#set
workdir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(workdir)
rm(list = ls())

#library
library(UpSetR)
library(dplyr)
library(tidyr)
library(ggplot2)
library(openxlsx)

#data
# 读取Excel文件
data <- read.xlsx("species.xlsx", sheet = 1)

# Count the number of samples for each mag in each site
count_df <- data %>%
  group_by(body_part, qseqid_species) %>%
  summarise(sample_count = n(), .groups = 'drop')

# Create a wide-format dataframe for UpSet plot
wide_df <- count_df %>%
  pivot_wider(names_from = body_part, values_from = sample_count, values_fill = list(sample_count = 0))

write.csv(wide_df, 'site_arise_count.csv')

# Convert the wide_df to a binary matrix format suitable for UpSetR
binary_df <- wide_df %>%
  mutate(across(-qseqid_species, ~ ifelse(. > 0, 1, 0)))

# Convert to a regular data frame and set gene as row names
binary_df <- as.data.frame(binary_df)
rownames(binary_df) <- binary_df$gene
binary_df <- binary_df[, -1]

# Plot the UpSet plot
p <- upset(binary_df, sets = colnames(binary_df), order.by = "freq")

pdf("fig_upset_plot.pdf", width = 5, height = 5)
print(p)
dev.off()







