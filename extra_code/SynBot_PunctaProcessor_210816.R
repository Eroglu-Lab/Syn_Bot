#author Justin Savage
#js664@duke.edu
#Version 1.0
#8/16/21

#This script is for combining the data from the coloc_results file output of the 
# Syn_Bot ImageJ Macro. You should be able to simply select the entire script (Ctrl/Cmnd + A)
# and click the Run button in the top right corner. You will then select the same folder
# that was selected for the Syn_Bot run. This will read in the data and write a 
# summary.csv file similar to the one that is made by Syn_Bot itself.

#Further analysis can be performed on the data from individual images using similar 
# techniques to those shown here. Those unfamiliar with R are encouraged to learn 
# more about it at https://r4ds.had.co.nz/

#loaded RStudioAPI to use for selecting working directory
if("rstudioapi" %in% rownames(installed.packages()) == FALSE) 
{install.packages("rstudioapi")}
library(rstudioapi)
if("xlsx" %in% rownames(installed.packages()) == FALSE) 
{install.packages("xlsx")}
library(xlsx)
if("reshape" %in% rownames(installed.packages()) == FALSE) 
{install.packages("reshape")}
library(reshape)
if("data.table" %in% rownames(installed.packages()) == FALSE) 
{install.packages("data.table")}
library(data.table)
if("stringi" %in% rownames(installed.packages()) == FALSE) 
{install.packages("stringi")}
library(stringi)
if("tidyverse" %in% rownames(installed.packages()) == FALSE) 
{install.packages("tidyverse")}
library(tidyverse)

dataFile <- selectDirectory(
  caption = "Select Directory",
  label = "Select",
  path = getActiveProject()
)
setwd(dataFile)


allFiles <- dir()
imageIndices <- 0

for (i in 1:length(allFiles)){
  currentFile <- allFiles[i]
    imageIndices <- append(imageIndices, i)
}


for(i in 2:length(imageIndices)){
  if(i == 2){
    imageFiles <- allFiles[imageIndices[i]]
  }
  if(i != 2){
    imageFiles <- append(imageFiles, allFiles[imageIndices[i]])
  }
}

#imageFiles is all folders that aren't the key
for(i in 1:length(imageFiles)) {
  currentFile <- imageFiles[i]
  pathOutput <- paste(currentFile, 'Output', sep = "/")
  if (i == 1) {
    fileList <- dir(pathOutput)
    for(j in 1:length(fileList)){
      fileList[j] <- paste(pathOutput, fileList[j], sep = "/")
    }
  }
  if (i != 1) {
    newFiles <- dir(pathOutput)
    for(j in 1:length(newFiles)){
      newFiles[j] <- paste(pathOutput, newFiles[j], sep = "/")
    }
    fileList <- append(fileList, newFiles)
  }
}

#redFiles and greenFiles stores the names of images
redFiles <- str_subset(fileList, pattern = 'redResults')
greenFiles <- str_subset(fileList, pattern = 'greenResults')
colocFiles <- str_subset(fileList, pattern = 'colocResults')
redDataIn <- lapply(redFiles, read.csv)
greenDataIn <- lapply(greenFiles, read.csv)
colocDataIn <- lapply(colocFiles, read.csv)


for (i in 1:length(redDataIn)){
  currentData <- redDataIn[[i]]
  #Removes all columns but puncta number, Area, X, Y
  redDataIn[[i]] <- currentData[,c(2,3,6,7)]
  redDataIn[[i]]$Image <- i
  setorder(redDataIn[[i]],Image,X)
}

for (i in 1:length(greenDataIn)){
  currentData <- greenDataIn[[i]]
  #Removes all columns but puncta number, Area, X, Y
  greenDataIn[[i]] <- currentData[,c(2,3,6,7)]
  greenDataIn[[i]]$Image <- i
  setorder(greenDataIn[[i]],Image,X)
}

for (i in 1:length(colocDataIn)){
  currentData <- colocDataIn[i]
  colocDataIn[[i]]$Image <- i
  setorder(colocDataIn[[i]],Image,colocX)
}

for (i in 1:length(redDataIn)) {
  currentColocData <- colocDataIn[[i]]
  colocTot <- length(currentColocData$colocX)
  if (i == 1){
    colocVector <- c(colocTot)
  }
  if (i != 1){
    colocVector <- append(colocVector, colocTot)
  }
}

colocData <- tibble(
  Image = redFiles,
  ColocCount = colocVector
)

#also count red puncta 

for (i in 1:length(redDataIn)) {
  currentRedData <- redDataIn[[i]]
  redTot <- length(currentRedData$X)
  if (i == 1){
    redVector <- c(redTot)
  }
  if (i != 1){
    redVector <- append(redVector, redTot)
  }
}

colocData <- colocData %>% add_column(RedCount = redVector)
colocData$RedCount = redVector


#also count green puncta

for (i in 1:length(greenDataIn)) {
  currentGreenData <- greenDataIn[[i]]
  greenTot <- length(currentGreenData$X)
  if (i == 1){
    greenVector <- c(greenTot)
  }
  if (i != 1){
    greenVector <- append(greenVector, greenTot)
  }
}

colocData <- colocData %>% add_column(GreenCount = greenVector)
colocData$GreenCount = greenVector
#write.csv(colocData, file="summary.csv")

