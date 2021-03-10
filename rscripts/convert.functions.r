getMgsMeanVect_10_cutoff <- function(norm_data, genes_id, mgsList) {
  id <- match(genes_id,rownames(norm_data)) # id from the catalog of the genes present in our data
  data <- norm_data[id,] # get data only from the genes we have
  rownames(data) <- mgsGeneList
  data[is.na(data)] <- 0
  genebag = rownames(data)
  mgs <- projectOntoMGS(genebag=genebag, list.mgs=mgsList)
  length(genebag)
  mgs.dat <- extractProfiles(mgs, data)
  mgs.mean.vect <- computeFilteredVectors(profile=mgs.dat, type="mean", filt=10)
  mgs.mean.vect <- mgs.mean.vect[rowSums(mgs.mean.vect)>0,]
  return(mgs.mean.vect)
  
}
getMgsMedVect <- function(norm_data, genes_id, mgsList) {
  id <- match(genes_id,rownames(norm_data)) # id from the catalog of the genes present in our data
  data <- norm_data[id,] # get data only from the genes we have
  rownames(data) <- mgsGeneList
  data[is.na(data)] <- 0
  genebag = rownames(data)
  mgs <- projectOntoMGS(genebag=genebag, list.mgs=mgsList)
  length(genebag)
  mgs.dat <- extractProfiles(mgs, data)
  mgs.med.vect <- computeFilteredVectors(profile=mgs.dat, type="median")
  mgs.med.vect <- mgs.med.vect[rowSums(mgs.med.vect)>0,]
  return(mgs.med.vect)
}

getMgsDat <- function(norm_data, genes_id, mgsList) {
  id <- match(genes_id,rownames(norm_data)) # id from the catalog of the genes present in our data
  data <- norm_data[id,] # get data only from the genes we have
  rownames(data) <- mgsGeneList
  data[is.na(data)] <- 0
  genebag = rownames(data)
  mgs <- projectOntoMGS(genebag=genebag, list.mgs=mgsList)
  length(genebag)
  mgs.dat <- extractProfiles(mgs, data)
  return(mgs.dat)
}

getPhyla <- function(mgs_med_vec, taxo) {
  phyla = taxo[match(rownames(mgs_med_vec), rownames(taxo)),"phylum"]
  return(phyla)
}

getSpecies <- function(mgs_med_vec, taxo) {
  species = taxo[match(rownames(mgs_med_vec), rownames(taxo)),"species"]
  return(species)
}

getFileName <- function(prefix) {paste(prefix, ".tsv", sep = "")}
getNormRDataName <- function(prefix, depth) {paste(prefix, ".norm.", depth,  ".RData", sep = "")}
getRDataName <- function(prefix) {paste(prefix, ".RData", sep = "")}
getMGSFile <- function(prefix) {paste(prefix, ".mgs.med.vec.RData", sep = "")}
getMGSDatFile <- function(prefix) {paste(prefix, ".mgs.dat.RData", sep = "")}
getSampleSumWithDepthFile <- function(prefix, depth) {paste(prefix, ".sample.sum.", depth, ".RData", sep = "")}
getMGSWithDepthFile <- function(prefix, depth) {paste(prefix, ".mgs.med.vec.", depth, ".RData", sep = "")}
getMGSmeanWithDepthFile <- function(prefix, depth) {paste(prefix, ".mgs.mean.vec.", depth, ".RData", sep = "")}
