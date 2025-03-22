###R 4.2.3
###liangweiting
###20250303
###plot plastic type

#set
workdir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(workdir)
rm(list = ls())

#加载
library(openxlsx)
library(ggplot2)
library(dplyr)

# 读取Excel文件
data <- read.xlsx("plastic_type_mag.xlsx", sheet = 1)

# 计算每个body_part和plastic_type组合中MAG的数目
mag_count <- data %>%
  group_by(body_part, plastic_type) %>%
  summarise(MAG_count = n(), .groups = 'drop')

# 根据MAG_count设置梯度
mag_count <- mag_count %>%
  mutate(MAG_gradient = case_when(
    MAG_count <= 10 ~ "0-10",
    MAG_count > 10 & MAG_count <= 50 ~ "10-50",
    MAG_count > 50 & MAG_count <= 100 ~ "50-100",
    MAG_count > 100 ~ "100+"
  ))

# 绘制气泡图
p <- ggplot(mag_count, aes(x = body_part, y = plastic_type, size = MAG_gradient, color = MAG_gradient)) +
  geom_point(alpha = 0.7) +
  scale_size_manual(values = c("0-10" = 3, "10-50" = 5, "50-100" = 7, "100+" = 9)) +
  scale_color_manual(values = c("0-10" = "blue", "10-50" = "green", "50-100" = "orange", "100+" = "red")) +
  labs(title = "Bubble Plot: MAG Count by Body Part and Plastic Type",
       x = "Body Part",
       y = "Plastic Type",
       size = "MAG Count",
       color = "MAG Count") +
  theme_minimal()

ggsave("bubble_plot_mag_count.pdf", p, width = 10, height = 8)





# 计算每个body_part和plastic_type组合中Potential_value的众数
#Potential_value_mode <- data %>%
#  group_by(body_part, plastic_type) %>%
#  summarise(Potential_value_mode = as.numeric(names(sort(table(Potential_value), decreasing = TRUE)[1])), .groups = 'drop')

# 计算最高值
Potential_value_max <- data %>%
  group_by(body_part, plastic_type) %>%
  summarise(Potential_value_max = max(Potential_value),.groups = 'drop')

# 根据Potential_value_mode设置梯度
Potential_value_max <- Potential_value_max %>%
  mutate(Potential_value_gradient = case_when(
    Potential_value_max <= 70 ~ "50-70",
    Potential_value_max > 70 & Potential_value_max <= 80 ~ "70-80",
    Potential_value_max > 80 & Potential_value_max <= 90 ~ "80-90",
    Potential_value_max > 90 ~ "90-100"
  ))

# 绘制气泡图
p <- ggplot(Potential_value_max, aes(x = body_part, y = plastic_type, size = Potential_value_gradient, color = Potential_value_gradient)) +
  geom_point(alpha = 0.7) +
  scale_size_manual(values = c("50-70" = 3, "70-80" = 5, "80-90" = 7, "90-100" = 8)) +
  scale_color_manual(values = c("50-70" = "blue", "70-80" = "green", "80-90" = "orange", "90-100" = "red")) +
  labs(title = "Bubble Plot: Potential_value Mode by Body Part and Plastic Type",
       x = "Body Part",
       y = "Plastic Type",
       size = "Potential_value Mode",
       color = "Potential_value Mode") +
  theme_minimal()

ggsave("bubble_plot_Potential_value_max.pdf", p, width = 10, height = 8)
