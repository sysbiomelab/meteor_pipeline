source("/proj/uppstore2019028/projects/metagenome/theo/newscripts/meteor/rscripts/convert.functions.r")
require(dplyr)  
require(ggplot2)
require(momr)

args = commandArgs(trailingOnly=TRUE)
if (length(args) < 3) {
	print(length(args))
	print(args)
	stop("\n\n [usage] save.gct.r gene_count_file  prefix  output_directory \n\n", call.=F)
}

gctFile = args[1]
prefix = args[2]
outDir = args[3]
gctFile = normalizePath(gctFile)
outDir = normalizePath(outDir)
print(gctFile)
print(prefix)
print(outDir)
print(class(gctFile))
print(class(prefix))
print(class(outDir))

gctRData = getRDataName(prefix)
mgsRData = getMGSFile(prefix)
mgsDatRData = getMGSDatFile(prefix)
sampleSumFile = getSampleSumWithDepthFile(prefix, "10M")

setwd(outDir)

analysisMode = T
if (analysisMode) {
gctTab = read.delim(gctFile, row.names=1, sep="\t", stringsAsFactors = F, header=T)
sampleSum = colSums(gctTab)
print(min(sampleSum))
print(quantile(sampleSum,0.25))
print(quantile(sampleSum,0.75))
print(max(sampleSum))

save(sampleSum, file = sampleSumFile)
save(gctTab, file = gctRData)

rm(list=ls())
}
