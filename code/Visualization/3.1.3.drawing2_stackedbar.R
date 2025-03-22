###R 4.4.1
###liangweiting
###20241025
###drawing stacked bar of plastic RPKM

#set
workdir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(workdir)
rm(list = ls())

#library
library(ggplot2)
library(dplyr)
library(tidyr)

#data
data <- read.csv('human_samples_protein.csv', check.names = FALSE)

# Function to extract plastic types from gene IDs
extract_plastic_type <- function(gene_id) {
  # Use regular expression to extract the part after the last '||'
  match <- regexpr("\\|\\|[^|]+$", gene_id)
  if (match[1] != -1) {
    return(substring(gene_id, match[1] + 2))
  } else {
    return(NA)
  }
}

# Extract plastic types for each gene ID in the column names
plastic_types <- sapply(names(data)[-c(1, 2)], extract_plastic_type)

# Create a new data frame to store the results
results <- data.frame(Site = data$site)

# Sum the counts for each plastic type
for (plastic in unique(plastic_types)) {
  plastic_columns <- which(plastic_types == plastic) + 2
  if (length(plastic_columns) > 1) {
    results[[plastic]] <- rowSums(data[, plastic_columns], na.rm = TRUE)
  } else {
    results[[plastic]] <- data[, plastic_columns]
  }
}

# Combine values with the same plastic source
data_combined <- results %>%
  group_by(Site) %>%
  summarise(across(everything(), ~sum(.x, na.rm = TRUE)))

# Identify the plastic type with the highest abundance for each site
#data_combined$MaxPlastic <- apply(data_combined[,-1], 1, function(row) {
#  colnames(data_combined)[-1][which.max(row)]
#})

#choose, show PE,PET,PBAT,PHBV_PHA_PLA_PCL_PES,PU,PS
# 1. Data processing
data_processed <- data_combined %>%
  mutate(Others = rowSums(select(., -Site, -PE, -PET, -PBAT, -PHBV_PHA_PLA_PCL_PES, -PU, -PS), na.rm = TRUE)) %>%
  select(Site, PE, PET, PBAT, PHBV_PHA_PLA_PCL_PES, PU, PS, Others)

# 2. Calculate percentages
data_percent <- data_processed %>%
  pivot_longer(cols = -Site, names_to = "Plastic", values_to = "Abundance") %>%
  group_by(Site) %>%
  mutate(Percentage = Abundance / sum(Abundance) * 100) %>%
  ungroup()

# 3. Plot stacked bar chart
# Define the order of sites
site_order <- c("cheek", "nosewing", "nasal", "tongue", "saliva", "gut", "urine")
# Convert Site to a factor with the specified order
data_percent$Site <- factor(data_percent$Site, levels = site_order)

# Define custom colors for each plastic type
custom_colors <- c(
  "PE" = "#1f77b4",       # Blue
  "PET" = "#ff7f0e",      # Orange
  "PBAT" = "#2ca02c",     # Green
  "PHBV_PHA_PLA_PCL_PES" = "#d62728", # Red
  "PU" = "#9467bd",       # Purple
  "PS" = "#8c564b",       # Brown
  "Others" = "#7f7f7f"    # Grey
)

write.csv(data_percent, 'data_stackedbar.csv')

p <- ggplot(data_percent, aes(x = Site, y = Percentage, fill = Plastic)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = custom_colors) +
  labs(x = "Site", y = "Abundance Percentage", fill = "Plastic Type") +
  theme_minimal()

ggsave('fig_stackedbar.pdf', p, width=7, height=6)



# 4. Plot stacked bar chart with actual values
# Convert Site to a factor with the specified order
data_processed$Site <- factor(data_processed$Site, levels = site_order)

# Add a small constant to avoid log(0) issues
data_processed_log <- data_processed %>%
  mutate(across(-Site, ~ . + 1))  # Adding 1 to all abundance values

p_values <- ggplot(data_processed_log %>%
                     pivot_longer(cols = -Site, names_to = "Plastic", values_to = "Abundance"),
                   aes(x = Site, y = Abundance, fill = Plastic)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = custom_colors) +
  labs(x = "Site", y = "Abundance (log scale, RPKM)", fill = "Plastic Type", 
       title = "Gene Counts for Degrading Different Plastic Types (RPKM Corrected)") +
  theme_minimal() +
  scale_y_continuous(trans = 'log10')  # Apply log10 transformation to y-axis

# Save the plot
ggsave('fig_stackedbar_values_log.pdf', p_values, width=7, height=6)






