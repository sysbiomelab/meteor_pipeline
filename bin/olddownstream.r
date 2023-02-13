#!/usr/bin/Rscript
#memory.limit(9999999999)
require('dplyr')  
require('momr')

args = commandArgs(trailingOnly=TRUE)
gctFile = args[1]
indexedCatalog = args[2]
mspdownload = args[3]
#name = args[4]

## for testing only
##gctFile = "/proj/uppstore2019028/projects/metagenome/theo/newscripts/neworalmerged/Downstream/gct.tsv"
#gctFile = '/proj/uppstore2019028/nobackup/personal/theo/nmdsmeteor/gct.tsv'
#mspdownload = "/proj/uppstore2019028/projects/metagenome/dataverse_files/IGC2.1990MSPs.tsv"
#indexedCatalog = "/crex/proj/uppstore2019028/projects/metagenome/meteor_ref/oral_catalog/database/oral_catalog_lite_annotation"
#gctFile = "/home/theop/downstream_data/norm.csv"
#gctFile = "/crex/proj/snic2020-6-153/nobackup/private/gutnftest/work/6b/282d8e4afa311a83cdc89655f62e52/gct.tsv"
#mspdownload = "/proj/uppstore2019028/projects/metagenome/dataverse_files/IGC2.1990MSPs.tsv"
#indexedCatalog = "/crex/proj/uppstore2019028/projects/metagenome/meteor_ref/hs_10_4_igc2/database/hs_10_4_igc2_lite_annotation"
#name = 'test'

print("gct loading")
gctTab = read.delim(gctFile, row.names=1, sep="\t", stringsAsFactors=F, header=T)
#gctNorm10m = read.csv(gctFile, row.names=1, stringsAsFactors=F, header=T)
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
#rm(gctTab)
#gc()
#print("downsizing finished")
gctdown10m <- gctTab

print("norm begin")
sizeTab = read.table(indexedCatalog, sep="\t", stringsAsFactors=F)
names(sizeTab) <- c('gene_id', 'gene_size')
genesizes = sizeTab$gene_size
names(genesizes) = sizeTab$gene_id
#print('length of genesizes')
#print(length(genesizes))
#print('number of rows of gctdown10m')
#print(nrow(gctdown10m))
gctNorm10m = momr::normFreqRPKM(dat=gctdown10m, cat=genesizes)
#write.csv(gctNorm10m, quote=F, file="norm.csv")
print("norm finished")

print("catalog info loading")
MSP_data = read.csv(mspdownload, sep="\t", stringsAsFactors=F, header=T)
MSP_data[MSP_data==""] <- NA
MSP_data <- MSP_data[!(is.na(MSP_data$msp_name)),]
print("catalog info loaded")

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
write.csv(mgs.med.vect, quote=F, file="msp.csv")
print("mgs generation done")
