###R 4.4.1
###liangweiting
###20241025
###drawing PCOA of different site from protein RPKM

#set
workdir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(workdir)
rm(list = ls())

#library
library(vegan)
library(ggplot2)
library(ggforce)
library(MASS)

#data
data <- read.csv('human_samples_protein.csv', check.names = FALSE)

# Extract sample IDs and group information
samples <- data[, 1]
sites <- data[, 2]

# Extract gene expression data
gene_data <- data[, -c(1, 2)]

# Add a small constant to all values, avoid the influence of 0 value. original min non-zero is 0.001214829
small_constant <- 1e-5
gene_data_adjusted <- gene_data + small_constant

# Calculate Bray-Curtis distance matrix
distance_matrix <- vegdist(gene_data_adjusted, method = "bray")

# Perform Principal Coordinates Analysis (PCOA)
pcoa_results <- cmdscale(distance_matrix, eig = TRUE, k = 2)

# Calculate the percentage of variance explained
eig_values <- pcoa_results$eig
variance_explained <- eig_values / sum(eig_values) * 100
x_label <- paste0("PC1 (", round(variance_explained[1], 2), "%)")
y_label <- paste0("PC2 (", round(variance_explained[2], 2), "%)")

# Create a DataFrame for PCOA results
pcoa_df <- data.frame(PC1 = pcoa_results$points[, 1], PC2 = pcoa_results$points[, 2], Site = sites)

# Plot the PCOA results with ellipses and convex hulls
p1 <- ggplot(pcoa_df, aes(x = PC1, y = PC2, color = Site)) +
  geom_point(size = 1) +
  stat_ellipse(type = "norm", level = 0.8, alpha = 0.5) +  # Add confidence ellipses
  labs(title = "PCOA Plastic Degradation Genes", x = x_label, y = y_label) +
  theme_minimal()
ggsave('fig_POCA_site.pdf', p1, width=6, height=5)



#combine site frome 7 to 3
# Map sites to regions
site_to_region <- function(site) {
  if (site %in% c("cheek", "nosewing", "nasal")) {
    return("Facial Region")
  } else if (site %in% c("tongue", "saliva", "gut")) {
    return("Oral and Gastrointestinal Region")
  } else if (site == "urine") {
    return("Urinary System Region")
  } else {
    return(NA)
  }
}

pcoa_df$Region <- sapply(pcoa_df$Site, site_to_region)

# Plot the new PCOA results with grouped regions, ellipses, and convex hulls
p2 <- ggplot(pcoa_df, aes(x = PC1, y = PC2, color = Region)) +
  geom_point(size = 1) +
  stat_ellipse(type = "norm", level = 0.8, alpha = 0.5) +  # Add confidence ellipses
  labs(title = "PCOA Plastic Degradation Genes by Region", x = x_label, y = y_label) +
  theme_minimal()
ggsave('fig_POCA_region.pdf', p2, width=8, height=5)

