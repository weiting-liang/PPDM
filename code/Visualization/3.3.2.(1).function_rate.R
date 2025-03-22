### R 4.2.3
### liangweiting
### 20250308
### plot

# set
workdir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(workdir)
rm(list = ls())

library(ggplot2)
library(dplyr)
library(tidyr)
library(openxlsx)

# 读取Excel文件
data <- read.xlsx("plastic_func_count.xlsx", sheet = 1)

# 参数设置
group_by <- "phylum"  # 选择分类层级：phylum/genus/species
func_type <- "KO"     # 选择功能注释类型：KO/cazy/vf/rgiARO/AMP/DRAMP

# 根据选择的功能注释类型确定对应的列
if (func_type == "KO") {
  func_count <- "KO_count"
} else if (func_type == "cazy") {
  func_count <- "cazy_count"
} else if (func_type == "vf") {
  func_count <- "vf_count"
} else if (func_type == "rgiARO") {
  func_count <- "rgiARO_count"
} else if (func_type == "AMP") {
  func_count <- "AMP_family_count"
} else if (func_type == "DRAMP") {
  func_count <- "DRAMP_count"
} else {
  stop("Invalid func_type. Choose from: KO, cazy, vf, rgiARO, AMP, DRAMP")
}

# 计算known和unknown占比
data <- data %>%
  mutate(known = !!sym(func_count) / CDS_count,
         unknown = 1 - known) %>%
  group_by(!!sym(group_by)) %>%
  summarise(known = mean(known, na.rm = TRUE),
            unknown = mean(unknown, na.rm = TRUE)) %>%
  arrange(desc(known))  # 按known从大到小排序

# 将分类层级列转换为因子，并按known从小到大设置水平
data[[group_by]] <- factor(data[[group_by]], levels = data[[group_by]][order(data$known, decreasing = FALSE)])

# 将数据转换为长格式
data_long <- data %>%
  pivot_longer(cols = c(known, unknown), names_to = "type", values_to = "percentage")

# 调整type列的因子水平，确保unknown在上方，known在下方
data_long$type <- factor(data_long$type, levels = c("unknown", "known"))

# 定义对色盲友好的浅色调配色方案
color_palette <- c("unknown" = "#6BAED6",  # 浅蓝色
                   "known" = "#FD8D3C") # 浅橙色

# 绘制图形
p <- ggplot(data_long, aes(x = !!sym(group_by), y = percentage, fill = type)) +
  geom_bar(stat = "identity", position = "stack") +
  scale_y_continuous(labels = scales::percent_format(), limits = c(0, 1)) +
  scale_fill_manual(values = color_palette) +  # 使用自定义颜色
  coord_flip() +
  labs(x = group_by, y = "Percentage", fill = "Type",
       title = paste("Annotation Rate by", group_by, "for", func_type)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 0, hjust = 1),
        axis.text.y = element_text(angle = 0, hjust = 1))

# 输出文件名
output_file <- paste0("annotation_rate_", group_by, "_", func_type, ".pdf")
ggsave(output_file, plot = p, width = 5, height = 5)

# 打印保存路径
print(paste("Plot saved as:", output_file))

# 显示图形
print(p)