###R 4.4.1
###liangweiting
###20241029
###drawing upset of protein gene in different part

#set
workdir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(workdir)
rm(list = ls())

#library
library(UpSetR)
library(dplyr)
library(tidyr)
library(ggplot2)

#data
df <- read.csv('human_samples_protein.csv', check.names = FALSE)

# Convert gene RPKM values to 0 and 1
# Assuming gene columns start from the third column
gene_columns <- colnames(df)[3:ncol(df)]
df[gene_columns] <- lapply(df[gene_columns], function(x) ifelse(x > 0, 1, 0))

# Group by site
grouped <- df %>% group_by(site)

# Create a long-format dataframe
long_df <- df %>%
  pivot_longer(cols = all_of(gene_columns), names_to = "gene", values_to = "presence") %>%
  filter(presence == 1) %>%
  select(-presence)

# Count the number of samples for each gene in each site
count_df <- long_df %>%
  group_by(site, gene) %>%
  summarise(sample_count = n(), .groups = 'drop')

# Create a wide-format dataframe for UpSet plot
wide_df <- count_df %>%
  pivot_wider(names_from = site, values_from = sample_count, values_fill = list(sample_count = 0))

write.csv(wide_df, 'protein_site_arise_count.csv')

# Convert the wide_df to a binary matrix format suitable for UpSetR
binary_df <- wide_df %>%
  mutate(across(-gene, ~ ifelse(. > 0, 1, 0)))

# Convert to a regular data frame and set gene as row names
binary_df <- as.data.frame(binary_df)
rownames(binary_df) <- binary_df$gene
binary_df <- binary_df[, -1]

# Plot the UpSet plot
p <- upset(binary_df, sets = colnames(binary_df), order.by = "freq")

pdf("fig_upset_plot.pdf", width = 10, height = 6)
print(p)
dev.off()


