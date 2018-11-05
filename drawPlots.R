library("reshape2")
library("ggplot2")
library("directlabels")
require(plyr)

args = commandArgs(trailingOnly=TRUE)
#setwd("/home/steph/perl/4sq/ggplot2")
data<-read.csv(args[1], sep="\t")
colnames(data)[1]<-"year"
df<-as.data.frame(data)

test_data_long <- melt(df, id="year")


DF.t <- ddply(test_data_long, .(variable), transform, cumulVal = cumsum(value))

thisYear <- as.numeric(strsplit(as.character(Sys.Date()), "-")[[1]][1])

png(file="plot1.png", width = 1200, height = 900, units = "px",)
ggplot(data=DF.t,
       aes(x=year, y=cumulVal, colour=variable)) +
    geom_line(size=1.5) + geom_point() + geom_dl(aes(label = chartr(".", " ", variable)), method = list(cex=1.7, dl.trans(x = x + 0.2), list("last.points")))  + ylab("Check-ins") + theme(legend.position="none", axis.title = element_text(size = rel(2)), axis.text.x = element_text(size = rel(2))) + scale_x_continuous(breaks = df$year, limits = c(min(df$year), thisYear+0.8))
dev.off()

png(file="plot2.png", width = 1200, height = 900, units = "px",)
ggplot(data=DF.t,
       aes(x=year, y=cumulVal, colour=variable)) +
    geom_line(size=1.5) + geom_point() + ylim(0, 600) + geom_dl(aes(label = chartr(".", " ", variable)), method = list(cex=1.8, dl.trans(x = x + 0.2), list("last.points","bumpup")))  + ylab("Check-ins") + theme(legend.position="none", axis.title = element_text(size = rel(2)), axis.text.x = element_text(size = rel(2))) + scale_x_continuous(breaks = df$year, limits = c(min(df$year), thisYear+0.8))
dev.off()



for (examinedYear in c((min(df$year)+1):(max(df$year)+1))) {
	thisDF <- DF.t[DF.t$year<examinedYear,]
	thisFileName<-paste0("plot2_", examinedYear, ".png")

	png(file=thisFileName, width = 1200, height = 900, units = "px",)

	print(ggplot(data=thisDF, aes(x=year, y=cumulVal, colour=variable)) +
    geom_line(size=1.5) + geom_point() + ylim(0, 600) + geom_dl(aes(label = chartr(".", " ", variable)), method = list(cex=1.8, dl.trans(x = x + 0.2), list("last.points","bumpup")))  + ylab("Check-ins") + theme(legend.position="none", axis.title = element_text(size = rel(2)), axis.text.x = element_text(size = rel(2))) + scale_x_continuous(breaks = df$year, limits = c(min(df$year), thisYear+0.8)))

	dev.off()

}


for (examinedYear in c((min(df$year)+1):(max(df$year)+1))) {
	thisDF <- DF.t[DF.t$year<examinedYear,]
	thisFileName<-paste0("plot1_", examinedYear, ".png")

	png(file=thisFileName, width = 1200, height = 900, units = "px",)

	print(ggplot(data=thisDF, aes(x=year, y=cumulVal, colour=variable)) +
    geom_line(size=1.5) + geom_point() + geom_dl(aes(label = chartr(".", " ", variable)), method = list(cex=1.8, dl.trans(x = x + 0.2), list("last.points","bumpup")))  + ylab("Check-ins") + theme(legend.position="none", axis.title = element_text(size = rel(2)), axis.text.x = element_text(size = rel(2))) + scale_x_continuous(breaks = df$year, limits = c(min(df$year), thisYear+0.8)))

	dev.off()

}

