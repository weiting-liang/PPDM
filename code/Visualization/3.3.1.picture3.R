###R 4.2.3
###liangweiting
###20250307
###plot

#set
workdir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(workdir)
rm(list = ls())

# 加载必要的包
library(ggplot2)
library(dplyr)
library(tidyr)
library(readxl)
library(stringr)
library(scales)
library(patchwork)  # 用于拼图
library(ggrepel)    # 用于绘制连线

# 自定义参数：输出前多少个酶和物种
top_n_enzymes <- 30  # 可以修改为任意需要的数值
#top_n_species_per_body_part <- 10  # 每个部位展示最多的前 n 个物种
# 自定义酶列表
enzyme_list <- c("Laccase", "PVA_dehydrogenase", "Alkane_hydroxylase", "3HV_dehydrogenase", 
                 "PHA_depolymerase", "Polyesterase", "Lipase", "MHETase", 
                 "nitrobenzylesterase", "Hydrolase", "Polyurethanase_A")

# 读取第一个表 fpkm_corrected.csv
fpkm_data <- read.csv("fpkm_corrected.csv", check.names = FALSE)

# 读取第二个表 mag_body_enzyme_taxo.xlsx
enzyme_taxo_data <- read_excel("mag_body_enzyme_taxo.xlsx")

# 数据预处理
# 1. 提取酶名称
fpkm_long <- fpkm_data %>%
  pivot_longer(cols = -c(sample, body_part), names_to = "enzyme_info", values_to = "RPKM") %>%
  mutate(enzyme = str_split(enzyme_info, "\\|\\|", simplify = TRUE)[, 2]) %>%
  group_by(body_part, enzyme) %>%
  summarise(mean_RPKM = mean(RPKM, na.rm = TRUE)) %>%
  ungroup()

# 过滤掉 mean_RPKM 为0的数据点
fpkm_long <- fpkm_long %>% filter(mean_RPKM > 0)

# 2. 统计前 top_n_enzymes 个酶
top_enzymes <- fpkm_long %>%
  group_by(enzyme) %>%
  summarise(total_RPKM = sum(mean_RPKM)) %>%
  arrange(desc(total_RPKM)) %>%
  head(top_n_enzymes) %>%
  pull(enzyme)

# 过滤出前 top_n_enzymes 个酶的数据
fpkm_long_filtered <- fpkm_long %>%
  filter(enzyme %in% top_enzymes)

# 3. 根据自定义酶列表筛选物种
enzyme_taxo_filtered <- enzyme_taxo_data %>%
  filter(enzyme %in% enzyme_list)

# 获取所有筛选后的物种
top_species <- enzyme_taxo_filtered %>%
  pull(species) %>%
  unique()

# 4. 统计第二个表中的物种和最高 Potential_value
enzyme_potential_summary <- enzyme_taxo_filtered %>%
  group_by(from, species) %>%
  summarise(max_potential = max(Potential_value, na.rm = TRUE), .groups = 'drop') %>%  # 使用最高潜力值
  ungroup()

# 5. 统计每个部位中物种的出现次数
enzyme_taxo_summary <- enzyme_taxo_filtered %>%
  group_by(from, species) %>%
  summarise(
    total_gene = n(),  # 统计每个组的总行数
    total_genomes = n_distinct(genome),  # 统计每个组中 genome 列的非重复值个数
    .groups = 'drop'
  ) %>%
  ungroup()

# 合并气泡图数据
combined_bubble_data <- enzyme_taxo_summary %>%
  left_join(enzyme_potential_summary, by = c("from", "species"))

#删掉环境的样本
combined_bubble_data <- combined_bubble_data[which(combined_bubble_data$from != 'environment'), ]
# 减少呈现的物种数目，只展示某个部位最大潜力值能大于等于特定值的物种
species2 <- unlist(unique(combined_bubble_data[which(combined_bubble_data$max_potential >= 70), 'species']))
combined_bubble_data2 <- combined_bubble_data[combined_bubble_data$species %in% species2, ]

write(species2,'species_choose.csv')

# 6. 创建酶和物种的对应关系（用于连线）
enzyme_species_link <- enzyme_taxo_filtered %>%
  filter(species %in% top_species & enzyme %in% top_enzymes) %>%
  select(enzyme, species) %>%
  distinct()

write.csv(enzyme_species_link, 'enzyme_species_link_mat_picture.csv')

# 可视化
# 第一张图：气泡图
p1 <- ggplot(fpkm_long_filtered, aes(x = body_part, y = enzyme, size = mean_RPKM, color = mean_RPKM)) +
  geom_point(alpha = 0.7) +
  scale_size_continuous(range = c(1, 10)) +
  scale_color_viridis_c() +
  labs(x = "Body Part", y = "Enzyme", size = "Mean RPKM", color = "Mean RPKM") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# 输出为PDF
pdf("bubble_p1_plot.pdf", width = 6, height = 6)  # 设置PDF的宽度和高度
print(p1)  # 输出拼图
dev.off()  # 关闭PDF设备

# 第二张图和第三张图合并为气泡图
p2 <- ggplot(combined_bubble_data2, aes(x = from, y = species, size = total_genomes, color = max_potential)) +
  geom_point(alpha = 0.7) +
  scale_size_continuous(range = c(1, 5)) +
  scale_color_viridis_c() +
  labs(x = "Body Part", y = "species", size = "Total Genomes", color = "MAX Potential Value") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# 输出为PDF
pdf("bubble_p2_plot.pdf", width = 6, height = 9)  # 设置PDF的宽度和高度
print(p2)  # 输出拼图
dev.off()  # 关闭PDF设备

# 拼图
# 使用 patchwork 包将两张图拼接在一起
#combined_plot <- p1 + 
#  p2 + 
#  plot_layout(ncol = 2, widths = c(1, 1), heights = c(3, 1))  

# 输出为PDF
#pdf("combined_plot.pdf", width = 18, height = 6)  # 设置PDF的宽度和高度
#print(combined_plot)  # 输出拼图
#dev.off()  # 关闭PDF设备