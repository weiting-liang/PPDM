#liangweiting
#20250227
#pic hist for genus plastic enzymes count
#R 4.2.3

#set
workdir <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(workdir)
rm(list = ls())

# 加载所需的包
library(openxlsx)
library(ggplot2)

# 读取Excel文件
data <- read.xlsx("genus_species.xlsx", sheet = 1)

#enzyme and genome
tmp <- as.data.frame(table(data[, c('genome','species')]))
tmp <- tmp[which(tmp$Freq >0),]

# 计算每个species下的MAG平均基因个数
#先统计每个基因组的降解基因数
gene <- data[, c('CDS', 'genome', 'species')]
gene <- unique(gene)
# 每个基因的值就是1，所以直接统计每个基因组的CDS个数
gene$degrading_gene_count <- ifelse(gene$CDS == "", 0, 1)  # 如果酶列为空，则为0，否则为1

# 计算每个species的总降解基因数和MAG数
species_summary <- aggregate(degrading_gene_count ~ species + genome, gene, sum)  # 按genus和species分组，计算每个物种的酶数
species_avg_gene <- aggregate(degrading_gene_count ~ species, species_summary, function(x) sum(x) / length(x))  # 计算每个genus的物种平均酶数

# 计算每个物种的总基因组数目
species_genome_count <- aggregate(genome ~ species, species_summary, function(x) length(unique(x)))

# 将总基因组数目合并到 species_avg_gene 数据框中
species_avg_gene <- merge(species_avg_gene, species_genome_count, by = "species")

# 只展示基因组平均降解基因数大于5的。
species_avg_gene <- species_avg_gene[which(species_avg_gene$degrading_gene_count >= 5), ]

# 对species_avg_gene按degrading_gene_count升序排序（Xy轴颠倒，排序也要颠倒）
species_avg_gene <- species_avg_gene[order(species_avg_gene$degrading_gene_count), ]

# 将genus列转换为因子，并按排序后的顺序设置因子水平
species_avg_gene$species <- factor(species_avg_gene$species, levels = species_avg_gene$species)

# 创建一个新的列，用于显示物种名称和总基因组数目
species_avg_gene$species_label <- paste0(species_avg_gene$species, " / ", species_avg_gene$genome)

# 绘制genus下的物种平均酶个数的柱状图
p1 <- ggplot(species_avg_gene, aes(x = species, y = degrading_gene_count)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  scale_x_discrete(labels = species_avg_gene$species_label) +  # 修改x轴标签
  labs(x = "Species / Total Genome Count", y = "Average Number of Degrading Gene per Genome") +
  theme_minimal() +
  coord_flip() +
  theme(axis.title = element_text(size = 9))

# 保存为PDF文件
ggsave("species_avg_gene.pdf", plot = p1, width = 6, height = 6)


# 计算每个基因组的degrading_plastic_types的种类数
mag_plastic_type <- as.data.frame(table(data[, c('genome','degrading_plastic_types')]))
mag_plastic_type <- mag_plastic_type[which(mag_plastic_type$Freq >0),]
#统计频数
mag_plastic_count <- as.data.frame(table(mag_plastic_type[,'genome']))
Freq <- as.data.frame(table(mag_plastic_count['Freq']))
colnames(Freq) <- c('plastic_type_count', 'Freq')

# 打开 PDF 设备
pdf("barplot.pdf", width = 4, height = 4) 
# hist
barplot(
  table(mag_plastic_count['Freq']), 
  xlab = "Num.degradable plastic types per Genome",       # X轴标签
  ylab = "Count"    # Y轴标签
)
# 关闭 PDF 设备
dev.off()



