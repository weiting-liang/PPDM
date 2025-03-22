### R 4.2.3
### liangweiting
### 20250308
### plot

# set
workdir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(workdir)
rm(list = ls())

# 安装和加载所需的包
library(openxlsx)
library(ggplot2)
library(dplyr)
library(tidyr)
library(viridis) 

# 加载数据
plastic_KO_module <- read.table("plastic_KO_module.tsv", header = FALSE, sep = "\t", 
                                stringsAsFactors = FALSE) %>%
  setNames(c("file_id", "type", "KO"))

mag_body <- read.xlsx("mag_body.xlsx", sheet = 1) %>%
  setNames(c("file_id", "from"))

plastic_KO_annotation <- read.xlsx("plastic_KO_annotation2.xlsx", sheet = "module") %>%
  setNames(c("code", "type_annotate"))

# 计算菌株总数
strain_counts <- mag_body %>%
  group_by(from) %>%
  summarise(total_strains = n_distinct(file_id), .groups = 'drop')

# 数据预处理
enrichment_data <- plastic_KO_module %>%
  left_join(mag_body, by = "file_id") %>%
  filter(!is.na(from)) %>%
  mutate(type = strsplit(as.character(type), "")) %>%
  unnest(type) %>%
  left_join(plastic_KO_annotation, by = c("type" = "code")) %>%
  filter(!is.na(type_annotate)) %>%
  group_by(from, type_annotate) %>%
  summarise(count = n(), .groups = 'drop') %>%
  left_join(strain_counts, by = "from") %>%
  mutate(KOs_enrichment = count / total_strains) %>%
  select(from, type_annotate, KOs_enrichment)

# 移除可能的无穷大值
enrichment_data <- enrichment_data %>%
  filter(is.finite(KOs_enrichment))

# 保存标准化数据
write.csv(enrichment_data, 'enrichment_data_normalized.csv', row.names = FALSE)


# 修改后的可视化 ----------------------------------------------------------
ggplot(enrichment_data, aes(x = from, y = type_annotate, 
                            size = KOs_enrichment, 
                            color = from)) +
  geom_point(alpha = 0.7) +
  scale_size_continuous(
    name = "Normalized Enrichment",
    range = c(2, 10),  # 直接指定大小范围
    breaks = seq(floor(min(enrichment_data$KOs_enrichment)),
                 ceiling(max(enrichment_data$KOs_enrichment)),
                 length.out = 5)
  ) +
  labs(x = "Body Site", y = "KEGG Module Category") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),
    legend.position = "right",
    panel.grid.major = element_line(colour = "gray90")
  ) +
  guides(color = guide_legend(override.aes = list(size=5)))  # 手动指定图例气泡尺寸

# 保存图表
ggsave("normalized_bubble_plot.pdf", width = 8, height = 8, dpi = 300)