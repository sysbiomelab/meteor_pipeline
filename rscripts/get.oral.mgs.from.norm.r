
### taking inputs ###
args = commandArgs(trailingOnly=TRUE)

if (length(args) < 4) {
	stop("\n\n [usage] get.mgs.from.norm.r norm_count_file  prefix  norm_input_directory   output_directory \n\n", call.=F)
}



normFile = args[1]
prefix = args[2]
normInDir = args[3]
outDir = args[4]

normFile = normalizePath(normFile)
normInDir = normalizePath(normInDir)
outDir = normalizePath(outDir)


print(normFile)
print(prefix)
print(normInDir)
print(outDir)



### loading libraries and generating output files from prefix###

source("~/rscripts/2018_microbiome_ATLAS/convert.functions.r")
require(dplyr)  	
require(ggplot2)
require(momr)

#genesizeRData = "~/uppstore2019028/projects/metagenome/gut_catalog/hs_10_4_igc2.genesizes.RData"
geneIdRData = "~/uppstore2019028/Oral_ref/hs_oral_8.4_id_size_name.RData"
oralMspData = "~/uppstore2019028/Oral_ref/hs_8.4_oral_853_msp_table_freeze5.RData" 
gctRData = getRDataName(prefix)
normRData = getNormRDataName(prefix, "10M")
sampleSumFile = getSampleSumWithDepthFile(prefix, "10M")


setwd(outDir)


analysisMode = T
if (analysisMode) {
### loading gene count table ###

setwd(normInDir)

if (file.exists(normRData)) {
  print("norm RData existing")
  load(normRData)
  setwd(outDir)
}
if (!file.exists(normRData)) {
  setwd(outDir)
  load(gctRData)
  depth = 10000000
  gctDown10m = downsizeMatrix(gctTab, level= depth, repetitions=1, silent=F)
  rm(gctTab)

  load(oralMspData)
  load(geneIdRData)
  sizeTab = hs_oral_8.4_id_size_name[,c("gene_id","gene_name","gene_size")]
  geneSizes = sizeTab$gene_size
  names(geneSizes) = sizeTab$gene_id



  #load(genesizeRData)
  gctNorm10m = normFreqRPKM(dat=gctDown10m, cat=geneSizes)
  save(gctNorm10m, file=getNormRDataName(prefix, "10M"))
  rm(gctDown10m)

}

print("norm loaded")

load(oralMspData)
load(geneIdRData)
sizeTab = hs_oral_8.4_id_size_name[,c("gene_id","gene_name","gene_size")]
geneSizes = sizeTab$gene_size
names(geneSizes) = sizeTab$gene_id




print("oral_catalogue info loaded")

prepare = T
if (prepare) {

  MSP_id = split(MSP_data$gene_id, MSP_data$msp_name)
  mgsList = MSP_id
  mgsList_MG <- mgsList 
  for(i in 1:length(mgsList_MG)){
    mgsList_MG[[i]] <- mgsList_MG[[i]][1:50] # only the first 50 genes (enough information with them)
  }
  mgsList = mgsList_MG
  
  mgsGeneList = unique(do.call(c, mgsList))
  genes_id <- sizeTab$gene_id[match(mgsGeneList, sizeTab$gene_id)]
  
}

mgs_med_vec_10m = getMgsMedVect(gctNorm10m, genes_id, mgsList)
save(mgs_med_vec_10m,file=getMGSWithDepthFile(prefix, "10M"))
    

print("mgs generated")


rm(list=ls())
}

rm(list=ls())


