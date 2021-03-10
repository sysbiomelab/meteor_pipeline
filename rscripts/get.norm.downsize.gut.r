### taking inputs ###
args = commandArgs(trailingOnly=TRUE)

if (length(args) < 4) {
	stop("\n\n [usage] get.norm.downsize.r gene_count_file  prefix  gct_input_directory   output_directory \n\n", call.=F)
}



gctFile = args[1]
prefix = args[2]
gctInDir = args[3]
outDir = args[4]

gctFile = normalizePath(gctFile)
gctInDir = normalizePath(gctInDir)
outDir = normalizePath(outDir)


print(gctFile)
print(prefix)
print(gctInDir)
print(outDir)



### loading libraries and generating output files from prefix###

source("~/rscripts/2018_microbiome_ATLAS/convert.functions.r")
require(dplyr,lib.loc="/crex/proj/uppstore2019028/projects/metagenome/theo/Rpackages/")  
require(ggplot2,lib.loc="/crex/proj/uppstore2019028/projects/metagenome/theo/Rpackages/")
require(momr,lib.loc="/crex/proj/uppstore2019028/projects/metagenome/theo/Rpackages/")

#genesizeRData = "~/uppstore2019028/projects/metagenome/gut_catalog/hs_10_4_igc2.genesizes.RData"
#geneIdRData = "~/uppstore2019028/projects/metagenome/gut_catalog/hs_10_4_igc2.id.RData"
#gutMspData = "~/uppstore2019028/projects/metagenome/gut_catalog/hs_10.4_1992_MSP_freeze2_20180905.RData"

geneIdRData = "~/uppstore2019028/Oral_ref/hs_oral_8.4_id_size_name.RData"

gctRData = getRDataName(prefix)

sampleSumFile = getSampleSumWithDepthFile(prefix, "10M")


setwd(outDir)


analysisMode = T
if (analysisMode) {
### loading gene count table ###

setwd(gctInDir)

if (file.exists(gctRData)) {
  print("gct RData existing")
  load(gctRData)
  sampleSum = colSums(gctTab)
  print(min(sampleSum))
  print(quantile(sampleSum,0.25))
  print(quantile(sampleSum,0.75))
  print(max(sampleSum))

  save(sampleSum, file = sampleSumFile)
  setwd(outDir)
}
if (!file.exists(gctRData)) {
  setwd(outDir)
  gctTab = read.delim(gctFile, row.names=1, sep="\t", stringsAsFactors = F, header=T)
  sampleSum = colSums(gctTab)
  print(min(sampleSum))
  print(quantile(sampleSum,0.25))
  print(quantile(sampleSum,0.75))
  print(max(sampleSum))

  save(sampleSum, file = sampleSumFile)
  save(gctTab, file = gctRData)
}

print("gct loaded")

###downsizing
depth = 10000000
gctDown10m = downsizeMatrix(gctTab, level= depth, repetitions=1, silent=F)
rm(gctTab)
#load(genesizeRData)

load(geneIdRData)
sizeTab = hs_oral_8.4_id_size_name[,c("gene_id","gene_name","gene_size")]
geneSizes = sizeTab$gene_size
names(geneSizes) = sizeTab$gene_id


gctNorm10m = normFreqRPKM(dat=gctDown10m, cat=geneSizes)
save(gctNorm10m, file=getNormRDataName(prefix, "10M"))
rm(gctDown10m)

print("norm generated")

rm(list=ls())
}

rm(list=ls())


