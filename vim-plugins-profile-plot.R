require(ggplot2)
dat <- read.csv("profile.csv", header = FALSE)
png("profile.png", width = 1366, height = 768)
qplot(V4, V3, data = dat, stat = "summary", fun.y = "sum", geom = "bar") + coord_flip() + xlab("Installed Plugins") + ylab("Startup Time (ms)")
dev.off()

dat.n <- aggregate(V3 ~ V4, data = dat, "sum")
dat.n <- dat.n[order(dat.n$V3, decreasing = TRUE),]
dat.n <- dat.n[,2:1]
write.table(dat.n, "results.csv", sep = "\t", col.names = FALSE, row.names = FALSE)
