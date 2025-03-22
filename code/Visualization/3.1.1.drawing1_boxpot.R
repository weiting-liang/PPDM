###R 4.4.1
###liangweiting
###20241024
###drawing boxpot of protein enzyme plastic

#set
workdir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(workdir)
rm(list = ls())

#library
library(ggplot2)
library(dplyr)

#data
data <- read.csv('human_samples_protein.csv', check.names = FALSE)


#pic1 RPKM of gene coded protein
data1 <- data

# Calculate the total number of genes (RPKM normalized) for each sample
data1$total_genes <- rowSums(data1[, 3:ncol(data1)])

# site mean 
result <- data1 %>%
  group_by(site) %>%
  summarise(
    mean = mean(total_genes, na.rm = TRUE),  
    sd = sd(total_genes, na.rm = TRUE)     
  ) %>%
  mutate(mean_sd = sprintf("%.2f ± %.2f", mean, sd)) 

# kw
kw_result1 <- kruskal.test(total_genes ~ site, data = data1)

# Define the desired order for the 'site' factor
site_order <- c("cheek", "nosewing", "nasal", "tongue", "saliva", "gut", "urine")
# Convert 'site' to a factor with the specified order
data1$site <- factor(data1$site, levels = site_order)

# Apply log transformation to the total_genes column
data1$total_genes_log <- log10(data1$total_genes + 1)  # Adding 1 to avoid log(0)

# Define custom colors for each site
custom_colors <- c("cheek" = "#1f77b4",  # Light blue
                   "nosewing" = "#4C72B0",  # Medium blue
                   "nasal" = "#08306B",  # Dark blue
                   "tongue" = "#9467bd",  # Light purple
                   "saliva" = "#6a3d9a",  # Dark purple
                   "gut" = "#8c564b",  # Brown
                   "urine" = "#DAA520")  # Goldenrod (brown-yellow)

# Plot the boxplot with log-transformed data
p1 <- ggplot(data1, aes(x = site, y = total_genes_log, fill = site)) +
  geom_boxplot() +
  scale_fill_manual(values = custom_colors) +
  labs(title = "Distribution of Total Genes (RPKM Normalized, Log) Across Different Sites",
       x = "Site",
       y = "Total Genes (RPKM Normalized, Log)") +
  theme_minimal()
ggsave('fig_gene_RPKM.pdf', p1, width=8, height=4)



#--------------------------------------------------------------------------------
#pic2 gene type count
data2 <- data
# Calculate the number of gene species (non-zero RPKM values) for each sample
data2$gene_type_count <- rowSums(data2[, 3:ncol(data2)] > 0)

# site mean 
result2 <- data2 %>%
  group_by(site) %>%
  summarise(
    mean = mean(gene_type_count, na.rm = TRUE),  
    sd = sd(gene_type_count, na.rm = TRUE)     
  ) %>%
  mutate(mean_sd = sprintf("%.2f ± %.2f", mean, sd))

# Define the desired order for the 'site' factor
site_order <- c("cheek", "nosewing", "nasal", "tongue", "saliva", "gut", "urine")

# Convert 'site' to a factor with the specified order
data2$site <- factor(data2$site, levels = site_order)

# Define custom colors for each site
custom_colors <- c("cheek" = "#1f77b4",  # Light blue
                   "nosewing" = "#4C72B0",  # Medium blue
                   "nasal" = "#08306B",  # Dark blue
                   "tongue" = "#9467bd",  # Light purple
                   "saliva" = "#6a3d9a",  # Dark purple
                   "gut" = "#8c564b",  # Brown
                   "urine" = "#DAA520")  # Goldenrod (brown-yellow)

# Plot the boxplot with gene species count
p2 <- ggplot(data2, aes(x = site, y = gene_type_count, fill = site)) +
  geom_boxplot() +
  scale_fill_manual(values = custom_colors) +
  labs(title = "Distribution of Gene Type Count Across Different Sites",
       x = "Site",
       y = "Gene Type Count") +
  theme_minimal()
ggsave('fig_gene_Type.pdf', p2, width=8, height=4)


#----------------------------------------------------------------
#pic3 plastic type count
data3 <- data

# Extract plastic types from gene IDs
extract_plastic_type <- function(gene_id) {
  # Use regular expression to extract the part after the last '||'
  match <- regexpr("\\|\\|[^|]+$", gene_id)
  if (match[1] != -1) {
    return(substring(gene_id, match[1] + 2))
  } else {
    return(NA)
  }
}
# Apply the function to extract plastic types
plastic_types <- sapply(colnames(data3)[3:ncol(data3)], extract_plastic_type)

# Calculate the number of unique plastic types for each sample
data3$plastic_type_count <- apply(data3[, 3:ncol(data3)], 1, function(row) {
  unique_plastic_types <- unique(plastic_types[row > 0])
  length(unique_plastic_types)
})

# Define the desired order for the 'site' factor
site_order <- c("cheek", "nosewing", "nasal", "tongue", "saliva", "gut", "urine")

# Convert 'site' to a factor with the specified order
data3$site <- factor(data3$site, levels = site_order)

# Define custom colors for each site
custom_colors <- c("cheek" = "#1f77b4",  # Light blue
                   "nosewing" = "#4C72B0",  # Medium blue
                   "nasal" = "#08306B",  # Dark blue
                   "tongue" = "#9467bd",  # Light purple
                   "saliva" = "#6a3d9a",  # Dark purple
                   "gut" = "#8c564b",  # Brown
                   "urine" = "#DAA520")  # Goldenrod (brown-yellow)

# Plot the boxplot with plastic type count
p3 <- ggplot(data3, aes(x = site, y = plastic_type_count, fill = site)) +
  geom_boxplot() +
  scale_fill_manual(values = custom_colors) +
  labs(title = "Distribution of Plastic Type Count Across Different Sites",
       x = "Site",
       y = "Plastic Type Count") +
  theme_minimal()
ggsave('fig_Plastic_Type.pdf', p3, width=8, height=4)




