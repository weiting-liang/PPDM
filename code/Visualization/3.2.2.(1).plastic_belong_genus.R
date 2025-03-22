###R 4.2.3
###liangweiting
###20250303
###plot

#set
workdir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(workdir)
rm(list = ls())

#加载
library(openxlsx)
library(dplyr)
library(ggplot2)


# 读取Excel文件
data <- read.xlsx("plastic_genomes_genus_species.xlsx", sheet = 1)
tmp <- as.data.frame(table(data[, 'genus']))

# 过滤掉 genus 为 g__ 的行
data_filtered <- data %>% filter(genus != "g__")
# 过滤掉环境的
#data_filtered <- data_filtered %>% filter(from != "environment")

# 去掉 genus 列中的 g__ 前缀
data_filtered <- data_filtered %>% mutate(genus = gsub("g__", "", genus))

# 计算每个 genus 的出现频数
genus_count <- data_filtered %>% group_by(genus) %>% summarise(count = n())

# 过滤出频数大于 10 的 genus
genus_filtered <- genus_count %>% filter(count >= 10)

# 合并过滤后的 genus 数据
data_filtered <- data_filtered %>% filter(genus %in% genus_filtered$genus)


# 计算每个 genus 的总频数（按 from 分组）
genus_total_count <- data_filtered %>%
  group_by(genus) %>%
  summarise(total_count = n()) %>%
  arrange(desc(total_count))

# 将 genus 列转换为因子，并按总频数从高到低排序
data_filtered <- data_filtered %>%
  mutate(genus = factor(genus, levels = genus_total_count$genus))

# 绘制柱状堆叠图
p <- ggplot(data_filtered, aes(x = genus, fill = from)) +
  geom_bar(position = "stack") +
  labs(x = "Genus", y = "MAGs number", title = "Genus Count by Source") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))+
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1), # 旋转 X 轴标签
    plot.margin = margin(1, 1, 1, 2, "cm") # 增加画布边界
  )


ggsave('genus_plastic_genome_number.pdf', p, width=8, height=5)




