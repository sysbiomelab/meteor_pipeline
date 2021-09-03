#!/usr/bin/Rscript
memory.limit(9999999999)
require(dplyr)  
require(momr)
#require(ff)

args = commandArgs(trailingOnly=TRUE)
gctFile = args[1]
#outDir = args[2]
indexedCatalog = args[2]
mspdownload = args[3]

## for testing only
#gctFile = "../neworalmerged/Downstream/gct.tsv"
#outDir = "../neworalmerged/Downstream"
#indexedCatalog = "/crex/proj/uppstore2019028/projects/metagenome/meteor_ref/oral_catalog/database/oral_catalog_lite_annotation"
#mspdownload = "/proj/uppstore2019028/projects/metagenome/oral_dataverse_files/oral.MSPs.tsv"

print("gct loading")
gctTab = read.delim(gctFile, row.names=1, sep="\t", stringsAsFactors=F, header=T)
# gctTab = read.delim.ffdf(gctFile, row.names=1, sep="\t", stringsAsFactors=F, header=T)
print("gct loaded")

print("gct info saving")
sampleSum = colSums(gctTab)
print(min(sampleSum))
print(quantile(sampleSum,0.25))
print(quantile(sampleSum,0.75))
print(max(sampleSum))
#write.csv(sampleSum, quote=F, file=gzfile(paste(outDir, "samplesum.csv.gz",sep='/')))
write.csv(sampleSum, quote=F, file="samplesum.csv")
rm(sampleSum)
gc()
print("gct info saved")

#print("downsizing begin")
#depth = 10000000
#gctdown10m = momr::downsizeMatrix(gctTab, level=depth, repetitions=1, silent=F)
#write.csv(gctdown10m, file=gzfile(paste(outDir, "down.csv.gz", sep='/')))
#rm(gctTab)
#gc()
#print("downsizing finished")
gctdown10m <- gctTab
#gctNorm10m <- gctdown10m

print("norm begin")
sizeTab = read.table(indexedCatalog, sep="\t", stringsAsFactors=F)
names(sizeTab) <- c('gene_id', 'gene_size')
genesizes = sizeTab$gene_size
names(genesizes) = sizeTab$gene_id
print('length of genesizes')
print(length(genesizes))
print('number of rows of gctdown10m')
print(nrow(gctdown10m))
gctNorm10m = momr::normFreqRPKM(dat=gctdown10m, cat=genesizes)
#write.csv(gctNorm10m, file=gzfile(paste(outDir, "norm.csv.gz", sep='/')))
write.csv(gctNorm10m, quote=F, file="norm.csv")
print("norm finished")

print("igc2 info loading")
MSP_data = read.csv(mspdownload, sep="\t", stringsAsFactors=F, header=T)
MSP_data[MSP_data==""] <- NA
MSP_data <- MSP_data[!(is.na(MSP_data$msp_name)),]
print("igc2 info loaded")

print("mgs generation begin")
MSP_id = split(MSP_data$gene_id, MSP_data$msp_name)
mgsList = MSP_id
mgsList_MG <- mgsList 
# only the first 50 genes - enough information with them
for(i in 1:length(mgsList_MG)){
	mgsList_MG[[i]] <- mgsList_MG[[i]][1:50]
}
mgsList = mgsList_MG
mgsGeneList = unique(do.call(c, mgsList))
genes_id <- sizeTab$gene_id[match(mgsGeneList, sizeTab$gene_id)]
id <- match(genes_id, rownames(gctNorm10m))
data <- gctNorm10m[id,]
rownames(data) <- mgsGeneList
data[is.na(data)] <- 0
genebag = rownames(data)
mgs <- momr::projectOntoMGS(genebag=genebag, list.mgs=mgsList)
length(genebag)
mgs.dat <- momr::extractProfiles(mgs, data)
mgs.med.vect <- momr::computeFilteredVectors(profile=mgs.dat, type="median")
mgs.med.vect <- mgs.med.vect[rowSums(mgs.med.vect)>0,]
#write.csv(mgs.med.vect, file=gzfile(paste(outDir, "mgs.csv.gz",sep='/')))
write.csv(mgs.med.vect, quote=F, file="msp.csv")
print("mgs generation done")
