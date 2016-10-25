## Author: Mark Huang
## Please change wd to ./UCI HAR Dataset

## clean workspace first
rm(list = ls())

## libraries used
install.packages("dplyr")
library("dplyr"); library("plyr");

## download the necessary files and unzip first
fileUrl <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
download.file(fileUrl,destfile="./getdata_projectfiles_UCI HAR Dataset.zip")
unzip(zipfile="./getdata_projectfiles_UCI HAR Dataset.zip",exdir=".")


## Step 1 - load training data
train.x <- read.table("./UCI HAR Dataset/train/X_train.txt", header = FALSE)
train.y <- read.table("./UCI HAR Dataset/train/y_train.txt", header = FALSE)
train.y_labels <- read.table("./UCI HAR Dataset/activity_labels.txt", header = FALSE)
train.subj <- read.table("./UCI HAR Dataset/train/subject_train.txt", header = FALSE)
train.head <- read.table("./UCI HAR Dataset/features.txt", header = FALSE)
colnames(train.x) <- train.head$V2
colnames(train.subj) <- c("subject")
train.y <- merge(train.y,train.y_labels,by.x="V1",by.y="V1",all=TRUE)
train.full <- train.subj
train.full$activity <- train.y$V2
train.full <- cbind(train.full,train.x)

## Step 2 - load test data
test.x <- read.table("./UCI HAR Dataset/test/X_test.txt", header = FALSE)
test.y <- read.table("./UCI HAR Dataset/test/y_test.txt", header = FALSE)
test.y_labels <- read.table("./UCI HAR Dataset/activity_labels.txt", header = FALSE)
test.subj <- read.table("./UCI HAR Dataset/test/subject_test.txt", header = FALSE)
test.head <- read.table("./UCI HAR Dataset/features.txt", header = FALSE)
colnames(test.x) <- test.head$V2
colnames(test.subj) <- c("subject")
test.y <- merge(test.y,test.y_labels,by.x="V1",by.y="V1",all=TRUE)
test.full <- test.subj
test.full$activity <- test.y$V2
test.full <- cbind(test.full,test.x)

## Step 3 - Combine training and test datasets
intersect(names(train.full),names(test.full)) ## verification
dataset.full <- rbind(train.full,test.full)

## Step 3.1 - strip out columns other than subject, activity, mean(), std()
dataset.mean_std <- dataset.full[,grepl("subject|activity|-mean\\(\\)+(-[X-Z])?$|-std\\(\\)+(-[X-Z])?$",colnames(dataset.full))]
names(dataset.mean_std)

## Step 4 - function to perform mean in lapply
mean_this <- function(df) {
  if(length(df)>0) {
    lapply(df, FUN = mean)
  }
  else
    NA
}

## Step 4.1 - calculate mean of each subset
dataset.split <- split(select(dataset.mean_std,-(subject:activity)),list(dataset.mean_std$subject,dataset.mean_std$activity))
dataset.splitMean <- lapply(dataset.split, FUN = mean_this) ## possible to use ddply too

## Step 5 - function parse subsets back into data frame
parse_this <- function() {
  f1 <- names(dataset.splitMean)
  for(i in 1:length(f1)) {
    fac <- strsplit(f1[i],"\\.")
    subject <- as.data.frame(as.integer(fac[[1]][1])); colnames(subject) <- "subject";
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

## Step 5.1 - generate final data set and sort it by subject, activity
dataset.final <- parse_this() %>% arrange(subject,activity)
head(dataset.final,10) ## sanity check

## Step 6 - write cleansed dataset into output txt file cleaned_dataset.txt
fileName <- "./cleaned_dataset.txt"
write.table(dataset.final,file=fileName,row.names = FALSE)