###########################
###### RANDOM FOREST ######
###########################

library(ggplot2)
library(viridis)
library(RColorBrewer)
library(scales)
library(PerformanceAnalytics)
library(reshape2)
library(hrbrthemes)
library(dplyr) # for select, filter, summarize, etc.
library(plotly) # for fancy plots
library(corrplot) # for correlation plots
library(DataExplorer)
library(purrr)
library(kedd)
library(rpart)
library(rpart.plot)
library(MASS)
library(caret)
library(randomForest)

###### IMPORT DATA ######
setwd("C:/Users/Carlos Farinha/Desktop/IST/4� Ano/2� Semestre/MEDM/dengue-mosquito-spreading")

train <- read.table("train_without_na.csv", sep = ",", header = TRUE)
train_labels <- read.table("Train_Set_Labels.csv", sep = ",", header = TRUE)
test <- read.table("Test_Set.csv", sep = ",", header = TRUE)

summary(train)

# Selecting only San Juan city
train_labels <- train_labels %>% filter(city == 'sj')
test <- test %>% filter(city == 'sj')

# Remove identification of the X because it isn't required
train$X <- NULL
train_labels$city <- NULL
train_labels$year <- NULL
train_labels$weekofyear <- NULL
train$week_start_date <- NULL

summary(train)
summary(train_labels)

# Summary of dataset
cat("Dimensions of the training set: ", dim(train), "\n")
cat("Dimensions of the training_label set: ", dim(train_labels), "\n")
summary(train)
summary(train_labels)

# Define classes
class_funct <- function(x) {
  if(x <= 8) { # first quantile without oultiers
    return(1)
  } else if(x <= 17) { # first quantile without oultiers
    return(2)
  } else if(x <= 31) { # median without oultiers
    return(3)
  } else if(x <= 79) { # third quantile without oultiers
    return(4)
  }
  return(5) # outliers
}

train_labels <- train_labels %>% mutate(class = map_dbl(total_cases, class_funct))
train_labels$class <- as.factor(train_labels$class)
summary(train_labels)
summary(train_labels$class) # number of observations per class

# Apply log to precipitation covariates
train_log <- update_columns(train, c("precipitation_amt_mm","reanalysis_precip_amt_kg_per_m2","station_precip_mm"),
                            function(x) log(x + 1))
summary(train_log)

which(colnames(train_log)=="precipitation_amt_mm") # 7
which(colnames(train_log)=="reanalysis_precip_amt_kg_per_m2") # 13
which(colnames(train_log)=="station_precip_mm") # 22

summary(train_log)

# Define datasets to analyse
which(colnames(train_log)=="year") # 1
which(colnames(train_log)=="weekofyear") # 2
which(colnames(train_log)=="ndvi_ne") # 3
which(colnames(train_log)=="ndvi_nw") # 4
which(colnames(train_log)=="ndvi_se") # 5
which(colnames(train_log)=="ndvi_sw") # 6
which(colnames(train_log)=="reanalysis_avg_temp_k") # 9
which(colnames(train_log)=="reanalysis_dew_point_temp_k") # 10
which(colnames(train_log)=="reanalysis_max_air_temp_k") # 11
which(colnames(train_log)=="reanalysis_min_air_temp_k") # 12
which(colnames(train_log)=="reanalysis_tdtr_k") # 17

# Create 3 different datasets
train_precip <- train_log[,c(1,2,3,4,5,6,7,9,10,11,12,17)]
train_precip <- cbind(train_precip, train_labels$class)
colnames(train_precip)[13] <- "class"
summary(train_precip)

train_reanalysis <- train_log[,c(1,2,3,4,5,6,9,10,11,12,13,17)]
train_reanalysis <- cbind(train_reanalysis, train_labels$class)
colnames(train_reanalysis)[13] <- "class"
summary(train_reanalysis)

train_station <- train_log[,c(1,2,3,4,5,6,9,10,11,12,17,22)]
train_station <- cbind(train_station, train_labels$class)
colnames(train_station)[13] <- "class"
summary(train_station)

####################################################################################################################

### Random Forest for PRECIPITATION_AMT_MM
rf_precip <- randomForest(class ~. , data = train_precip, importance = TRUE)
rf_precip$predicted
rf_precip$mtry
rf_precip$ntree
rf_precip

rf_precip_update <- randomForest(class ~. , data = train_precip, ntree = 500, mtry = 12, importance = TRUE)
rf_precip_update
plot(rf_precip_update)
rfcv(train_precip[,c(1:12)], train_precip$class, cv.fold = 5, mtry=function(p) max(1, floor(sqrt(p))))

train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.rf_precip <- train(train_precip[,c(1:12)],train_precip$class, method = "rf",
                              trControl  = train.control,  metric = "Accuracy")
print(pred.rf_precip) # 0.536


### Decision Tree for REANALYSIS_PRECIP_AMT_KG_PER_M2
rf_reanalysis <- randomForest(class ~. , data = train_reanalysis, importance = TRUE)
rf_reanalysis$predicted
rf_reanalysis$mtry
rf_reanalysis$ntree
rf_reanalysis

rf_reanalysis_update <- randomForest(class ~. , data = train_reanalysis, ntree = 500, mtry = 12, importance = TRUE)
rf_reanalysis_update
plot(rf_reanalysis_update)
rfcv(train_reanalysis[,c(1:12)], train_reanalysis$class, cv.fold = 5, mtry=function(p) max(1, floor(sqrt(p))))

train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)
set.seed(2020)
pred.rf_reanalysis <- train(train_reanalysis[,c(1:12)],train_reanalysis$class, method = "rf",
                                  trControl  = train.control,  metric = "Accuracy")
print(pred.rf_reanalysis) # 0.537


### Decision Tree for STATION_PRECIP_MM
rf_station <- randomForest(class ~. , data = train_station, importance = TRUE)
rf_station$predicted
rf_station$mtry
rf_station$ntree
rf_station

rf_station_update <- randomForest(class ~. , data = train_station, ntree = 500, mtry = 12, importance = TRUE)
rf_station_update
plot(rf_station_update)
rfcv(train_station[,c(1:12)], train_station$class, cv.fold = 5, mtry=function(p) max(1, floor(sqrt(p))))

train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)
set.seed(2020)
pred.rf_station <- train(train_station[,c(1:12)],train_station$class, method = "rf",
                               trControl  = train.control,  metric = "Accuracy")
print(pred.rf_station) # 0.551
