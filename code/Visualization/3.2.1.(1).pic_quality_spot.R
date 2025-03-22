###R 4.2.3
###liangweiting
###20250303
###plot

#set
workdir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(workdir)
rm(list = ls())

#Rtools
Sys.setenv(PATH = paste("C:/software/R_and_RSdituo/R-4.2.3/rtools42/usr/bin;", "C:/software/R_and_RSdituo/R-4.2.3/rtools42/mingw64/bin;", Sys.getenv("PATH"), sep = ""))


# 加载必要的包
library(ggplot2)
library(ggExtra)
library(openxlsx)
library(dplyr)

# 读取Excel文件
data <- read.xlsx("potential_genome_quality.xlsx", sheet = 1)

# site mean 
result <- data[which(data$quality == 'isolate'), ] %>%
  summarise(
    mean = mean(Completeness, na.rm = TRUE),  
    sd = sd(Completeness, na.rm = TRUE)     
  ) %>%
  mutate(mean_sd = sprintf("%.2f ± %.2f", mean, sd)) 
result2 <- data[which(data$quality == 'isolate'), ] %>%
  summarise(
    mean = mean(Contamination, na.rm = TRUE),  
    sd = sd(Contamination, na.rm = TRUE)     
  ) %>%
  mutate(mean_sd = sprintf("%.2f ± %.2f", mean, sd)) 

# 绘制散点图
p <- ggplot(data, aes(x = Completeness, y = Contamination, color = quality)) +
  geom_point(size = 1.5, alpha = 0.7) +
  theme_minimal() +
  labs(x = "Completeness (%)", y = "Contamination (%)", color = "Quality") +
  scale_color_manual(values = c("high-quality" = "green", "near-complete" = "blue", "medium-quality" = "orange", "isolate" = "pink"))

# 添加边际柱状图
# 自定义边际柱状图的分组颜色
p <- ggMarginal(
  p,
  type = "histogram",
  groupColour = TRUE,  # 使用分组颜色
  groupFill = TRUE,    # 使用分组填充颜色
  alpha = 0.5          # 设置透明度
)

# 保存为PDF文件
ggsave("quality.pdf", plot = p, width = 6, height = 4)

















