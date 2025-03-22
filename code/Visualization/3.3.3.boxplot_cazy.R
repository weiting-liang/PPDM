### R 4.2.3
### liangweiting
### 20250308
### plot

# set
workdir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(workdir)
rm(list = ls())

# 加载必要的包
library(openxlsx)
library(ggplot2)
library(dplyr)

# 读取Excel文件
data <- read.xlsx("plastic_CAZY_MAG2.xlsx", sheet=1)

# 计算每个MAG2对应的cazy_type的个数
data_summary <- data %>%
  group_by(MAG2, cazy_type) %>%
  summarise(count = n(), .groups = 'drop')

# 绘制箱线图
ggplot(data_summary, aes(x = cazy_type, y = count, fill = cazy_type)) +
  geom_boxplot() +
  labs(x = "CAZy Type", y = "Count per MAG", title = "Boxplot of CAZy Type Counts per MAG") +
  theme_minimal()
# 保存图表为PDF或PNG格式
ggsave("box_plot.pdf", width = 5, height = 5)


