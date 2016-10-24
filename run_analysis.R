## Please change wd to ./UCI HAR Dataset

## clean workspace first
rm(list = ls())

## libraries used
install.packages("dplyr")
library("dplyr"); library("plyr");

## load training data
train.x <- read.table("./train/X_train.txt", header = FALSE)
train.y <- read.table("./train/y_train.txt", header = FALSE)
train.y_labels <- read.table("./activity_labels.txt", header = FALSE)
train.subj <- read.table("./train/subject_train.txt", header = FALSE)
train.head <- read.table("./features.txt", header = FALSE)
colnames(train.x) <- train.head$V2
colnames(train.subj) <- c("subject")
train.y <- merge(train.y,train.y_labels,by.x="V1",by.y="V1",all=TRUE)
train.full <- train.subj
train.full$activity <- train.y$V2
train.full <- cbind(train.full,train.x)

## load test data
test.x <- read.table("./test/X_test.txt", header = FALSE)
test.y <- read.table("./test/y_test.txt", header = FALSE)
test.y_labels <- read.table("./activity_labels.txt", header = FALSE)
test.subj <- read.table("./test/subject_test.txt", header = FALSE)
test.head <- read.table("./features.txt", header = FALSE)
colnames(test.x) <- test.head$V2
colnames(test.subj) <- c("subject")
test.y <- merge(test.y,test.y_labels,by.x="V1",by.y="V1",all=TRUE)
test.full <- test.subj
test.full$activity <- test.y$V2
test.full <- cbind(test.full,test.x)

## Combine training and test datasets
intersect(names(train.full),names(test.full)) ## verification
dataset.full <- rbind(train.full,test.full)
dataset.mean_std <- dataset.full[,grepl("subject|activity|-mean\\(\\)+(-[X-Z])?$|-std\\(\\)+(-[X-Z])?$",colnames(dataset.full))]
names(dataset.mean_std)

## function to perform mean in lapply
mean_this <- function(df) {
  if(length(df)>0) {
    lapply(df, FUN = mean)
  }
  else
    NA
}


## calculate mean of each subset
dataset.split <- split(select(dataset.mean_std,-(subject:activity)),list(dataset.mean_std$subject,dataset.mean_std$activity))
dataset.splitMean <- lapply(dataset.split, FUN = mean_this)

## function parse subsets back into data frame
parse_this <- function() {
  f1 <- names(dataset.splitMean)
  for(i in 1:length(f1)) {
    fac <- strsplit(f1[i],"\\.")
    subject <- as.data.frame(fac[[1]][1]); colnames(subject) <- "subject";
    activity <- as.data.frame(fac[[1]][2]); colnames(activity) <- "activity";
    
    if(complete.cases(dataset.splitMean[[f1[i]]])) { ## excludes NaN
      if(!exists("dataset.temp")) {
        dataset.temp <- cbind(subject=subject,activity=activity,dataset.splitMean[[f1[i]]] )
      }
      else {
        dataset.temp <- rbind(dataset.temp,cbind(subject=subject,activity=activity,dataset.splitMean[[f1[i]]]) )
      }
    }
  }
  dataset.temp
}

## generate final data set
dataset.final <- parse_this()
head(dataset.final,20) ## verification

## store the data set
fileName <- "./cleaned_dataset.txt"
write.table(dataset.final,file=fileName,row.names = FALSE)