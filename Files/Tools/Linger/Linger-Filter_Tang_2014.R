####################################################################
#  Linger-Filter (Part of ``Linger Toolkit'' by Kevin Tang)
####################################################################
#  Function:                                                       
#  This script allows the user to filter a variable, called it VarX (e.g. RT or Correct) by a subset of two or more variables
#  For instance, one might want to filter RT by-subject, by-condition, by region. The "grouping variables" here would be subject, condition and region.
#
#  The filtering strategy is as followed:
#  1) The mean and standard deviation of  VarX are calculated for each unique
#  combination of the grouping variables.
#  2) VarX above or below n times the standard deviation from the mean are filtered
#                                                             
#  Author: Kevin Tang                                             
#  Latest revision: 9 January 2015
#  Email: kevin.tang.10@ucl.ac.uk
#  http://tang-kevin.github.io
#  Twitter: http://twitter.com/tang_kevin
#
#  Please cite:
#  Tang, K. (2014). Linger Toolkit. http://tang-kevin.github.io/Tools.html. 
#
#  Tested with 
#  R version 3.0.2 (2013-09-25)
#  Platform: x86_64-pc-linux-gnu (64-bit)
# 
#  locale:
#  [1] LC_CTYPE=en_GB.UTF-8       LC_NUMERIC=C              
#  [3] LC_TIME=en_GB.UTF-8        LC_COLLATE=en_GB.UTF-8    
#  [5] LC_MONETARY=en_GB.UTF-8    LC_MESSAGES=en_GB.UTF-8   
#  [7] LC_PAPER=en_GB.UTF-8       LC_NAME=C                 
#  [9] LC_ADDRESS=C               LC_TELEPHONE=C            
#  [11] LC_MEASUREMENT=en_GB.UTF-8 LC_IDENTIFICATION=C 
# 
#  attached base packages:
#  [1] stats     graphics  grDevices utils     datasets  methods   base  
# 
#  other attached packages:
#  [1] reshape2_1.4
# 
#  loaded via a namespace (and not attached):
#  [1] plyr_1.8.1    Rcpp_0.11.2   stringr_0.6.2 tools_3.0.2
#
#  
#
#  Input: 
#  A text file with headers. A summarised linger file, with headers such as subject, condition, and region.
#
#  Output:
#  A filtered version of the input file
#
#  Instructions:
#  1) Complete the User specifications section, Save the script
#  2) Run the whole script
#
#  ## Version control ## 
#  - Version 1.0: 19 December 2014. First release
#  - Version 1.1: 8 January 2015. If any of the columns in col.names.grouping and 
#  col.name.VarX, contain NA (i.e. empty cells), then these rows
#  will not be filtered.
#  - Version 1.2: 9 January 2015. Avoid warnings() due to calculating means and sds
#  non-numeric cells (although no relevant) by creating "data.relevant" for computation
#  - Version 1.3: 9 January 2015. Writing out outliers to a file as well.
####################################################################

version = '1.3'
print("=====================")
print("Welcome to Linger-Filter (Part of ``Linger Toolkit'' by Kevin Tang)")
print(paste('Version:',version, sep=' '))
# Store the variables in memory before the script was executed, these
# will be restored when the script is completed
save(list=ls(), file="temp.variables")
# Clear all
rm(list=ls()) 

# load library, if not exist, then install automatically
packages <- c("reshape2")
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}

library(reshape2)



####################################################################
## User specifications 

# What is your working directory
wd.path = "/media/MyWork/Linger/"

# What is the name of the summary text file?
input.txt.name = "summary.csv"

# What is the delimiter of the summary text file? (Default: "\t")
input.txt.sep = '\t'

# What is the name of the output text file?
output.txt.name = "summary.filtered.csv"

# What is your threshold of the fitler? (Default: 2.5)
filter.threshold = 2.5 # e.g. 2.5 std above or below the mean

# The column names of the variables that you want to group by
col.names.grouping = c("Subj","Condition","Tag")

# The column name of your variable of interest (VarX), e.g. logRT, 
col.name.VarX = "logRT"

print("=====================")
print("==Input parameters===")
print("=====================")
print(paste('Working directory:',wd.path, sep=' '))
print("-----------------------")      
print(paste('Name of the input text file:',input.txt.name, sep=' '))
print("-----------------------")      
print(paste('Name of the output text file:',output.txt.name, sep=' '))
print("-----------------------")      
print(paste('Filtering threshold (How many std above or below mean): ', filter.threshold, sep=' '))
print("-----------------------")                  
print(paste('Grouping variable(s): ', paste0(col.names.grouping, collapse = ', '), sep=' '))
print("-----------------------")              
print(paste('Filtering variable: ', col.name.VarX, sep=' '))

print("=====================")
print("==Begin processing===")
print("=====================")

## User specifications - End
####################################################################

# Set working directory
print("Setting working directory")
setwd(wd.path)
print("======Done=======")

# Read summary file
print(paste("Read text file:",input.txt.name, sep =' '))
data = read.table(input.txt.name,sep=input.txt.sep,header=TRUE)

data.original.header = names(data)
print("======Done=======")
print("Check if all grouping variables are found in the text file")
# Catch if grouping variables are not found in the headers of the text files
if (all(col.names.grouping %in% data.original.header) == FALSE) {
  stop(paste("Script terminates here. Cause: Not all of your grouping variables can be found in your text file.\n\n",
             "Variables in the text file:", paste0(data.original.header, collapse = ', '), "\n", "Grouping variables:",
             paste0(col.names.grouping, collapse = ', '),sep=' '))
}
print("======Done=======")


print("Check if the filtering variable can be found in the text file")
if (all(col.name.VarX %in% data.original.header) == FALSE) {
  stop(paste("Script terminates here. Cause: Your filtering variable can not be found in your text file.\n\n",
             "Variables in the text file:", paste0(data.original.header, collapse = ', '), "\n", "Grouping variables:",
             col.name.VarX,sep=' '))
}
print("======Done=======")

# calculate the number of grouping variables
group.num = length(col.names.grouping)

print("Calculate mean and std by grouping variables")

# calculate mean and std by grouping variables
group.data = data[data.original.header %in% col.names.grouping]
data.relevant = data[data.original.header %in% c(col.names.grouping, col.name.VarX)]
groupinglist= as.list(group.data)

data.mean <-aggregate(data.relevant, by=groupinglist, FUN=mean, na.rm=FALSE)
data.sd <-aggregate(data.relevant, by=groupinglist,FUN=sd, na.rm=FALSE)

data.mean.VarX = data.mean[names(data.mean) == col.name.VarX[1]]
data.sd.VarX = data.sd[names(data.sd) == col.name.VarX[1]]
# Data.sd.VarX can contain NA because you cannot calculate sd on one number,
# and some grouping can have only one number
# We set NA to 0
data.sd.VarX[is.na(data.sd.VarX)] <- 0

print("======Done=======")

print("Calculate upper and lower filtering limits")
# calculate upper limit: filter.threshold std above mean
data.upper = filter.threshold * data.sd.VarX + data.mean.VarX

# calculate lower limit: filter.threshold std blow mean
data.lower = data.mean.VarX - filter.threshold * data.sd.VarX 
print("======Done=======")

# for loop on data:
filter = NULL
upper.lim = NULL
lower.lim = NULL

#eval.idx <- function(group.data, data.mean, i, group.num) {
#index.bool = NULL
#for (ii in 1:nrow(data.mean)) {

#  index.bool[ii] = all(group.data[i,] == data.mean[ii,1:group.num])
#}
#return(index.bool)
#}


# vector of VarX
data.VarX = data[names(data) == col.name.VarX[1]]

# concate grouping values for fasting look up
if (group.num == 1) {
  groupings.values = data.mean[,1:group.num]
} else { 
  groupings.values = do.call(paste0, data.mean[,1:group.num])
}
group.data.values = do.call(paste0,group.data)

total <- nrow(data)
# create progress bar
pb <- txtProgressBar(min = 0, max = total, style = 3)


print("Filtering the text file")
for (i in 1:nrow(data)) {
  
  idx = match(group.data.values[i],groupings.values)
  if (!is.na(idx)) {
    VarX.temp = data.VarX[i,]
    upper = data.upper[idx,]
    lower = data.lower[idx,]
    filter.temp = 0
    if (VarX.temp > upper) {
      filter.temp = 1
    }
    if (VarX.temp < lower) {
      filter.temp = 1
    }
    filter[i] = filter.temp
    upper.lim[i] = upper
    lower.lim[i] = lower
  } else {
    filter[i] = 0 # 0 being not filter
    upper.lim[i] = NA
    lower.lim[i] = NA
  }
  # update progress bar
  setTxtProgressBar(pb, i)
}
close(pb)
print("======Done=======")

# these three lines are for debugging
data$upper.lim = upper.lim
data$lower.lim = lower.lim
data$filter.lgtk = filter

# Filter
data.filtered = subset(data, filter.lgtk == 0)
data.outliers = subset(data, filter.lgtk == 1)
#data.filtered = data

# Keep only the original columns
data.filtered = subset(data.filtered, select = data.original.header)
data.outliers = subset(data.outliers, select = data.original.header)

print(paste("Write filtered data to a new file:",output.txt.name,sep=' '))
write.table(data.filtered, output.txt.name,
            sep=input.txt.sep,
            row.names=FALSE,
            col.names=TRUE,
            quote = FALSE)

print(paste("Write outliers data to a new file:",output.outliers.txt.name,sep=' '))
write.table(data.outliers, output.outliers.txt.name,
            sep=input.txt.sep,
            row.names=FALSE,
            col.names=TRUE,
            quote = FALSE)

print("======Done=======")

# Restore variables before the script was executed
load("temp.variables")
file.remove("temp.variables")
print("=====================")
print("====End processing===")
print("=====================")
print("Thank you for using Linger-Filter (Part of ``Linger Toolkit'' by Kevin Tang)")
print("Please cite: Tang, K. (2014). Linger Toolkit. http://tang-kevin.github.io/Tools.html.")
