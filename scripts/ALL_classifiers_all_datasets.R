#########################################
###### CLASSIFIERS ON ALL DATASETS ######
#########################################

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
library(MASS)
library(caret)

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

colnames(train_log)[7] <- "log(precipitation_amt_mm + 1)"
colnames(train_log)[13] <- "log(reanalysis_precip_amt_kg_per_m2 + 1)"
colnames(train_log)[22] <- "log(station_precip_mm + 1)"

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

# PRECIPITATION_AMT_MM

### KNN
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)
set.seed(2020)
pred.knn_precip <- train(class~.,
                                method     = "knn",
                                tuneGrid   = expand.grid(k = 1:20),
                                trControl  = train.control,
                                metric     = "Accuracy",
                                data       = train_precip)
# Summarize the results
print(pred.knn_precip) # 0.3613605

### Naive Bayes
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)
set.seed(2020)
pred.nb_precip <- train(class~.,
                               method     = "nb",
                               #tuneGrid   = expand.grid(k = 1:20),
                               trControl  = train.control,
                               metric     = "Accuracy",
                               data       = train_precip)
# Summarize the results
print(pred.nb_precip) # 0.3774900

### LDA
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.lda_precip <- train(class ~., method = "lda", trControl = train.control,  metric = "Accuracy",
                                data = train_precip)
print(pred.lda_precip) # 0.3225644

### LINDA (Robust LDA)
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.rlda_precip <- train(class ~., method = "Linda", trControl = train.control,  metric = "Accuracy",
                                 data = train_precip)
print(pred.rlda_precip) #  0.3579469

### QDA
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.qda_precip <- train(class ~., method = "qda", trControl = train.control,  metric = "Accuracy",
                                data = train_precip)
print(pred.qda_precip) # 0.327552

### QdaCov (Robust QDA)
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.rqda_precip <- train(class ~., method = "QdaCov", trControl = train.control,  metric = "Accuracy",
                                 data = train_precip)
print(pred.rqda_precip) # 0.3444858

### Indicator Matrix
ntrain <- dim(train_precip)[1]
k<-5
set.seed(2020)

# we shuffle the data and partition it in 5 folds
train_precip <- train_precip[sample(ntrain),]

set1.1 <- train_precip[c(1:174),]
set1.2 <- train_precip[c(174:348),]
set1.3 <- train_precip[c(349:521),]
set1.4 <- train_precip[c(522:694),]
set1.5 <- train_precip[c(695:867),]


# we have to do 5 iterations changing the test set to do k fold cv
train1 <- rbind(set1.1, set1.2, set1.5, set1.4)
ntrain1 <- dim(train1)[1]
Y<-matrix(rep(0,ntrain1*k),nrow=ntrain1)
test1 <- set1.3

for (i in 1:ntrain1) {
  Y[i,train1$class[i]]<-1
  # for dataset 1
  regfits <- lm(Y~.,data=train1)}

ntest1<-dim(test1)[1]
yhattest <- numeric(ntest1)
yfitstest <- matrix(rep(0,ntest1*k),nrow=ntest1)
for (i in 1:ntest1) {
  yfitstest[i,] <- as.matrix(test1[i,1:12])%*%regfits$coef[1:12,]+regfits$coef[13,]
  yhattest[i]<-which(yfitstest[i,]==max(yfitstest[i,]))
}
# misclassification error estimate
print("Error: ") # 0.6416185
sum(yhattest[1:ntest1]!=test1[,13])/ntest1

# accuracy estimate
print("Accuracy: ") # 0.3583815
sum(yhattest[1:ntest1]==test1[,13])/ntest1

### Logistic Regression
pred.logis_precip <- nnet::multinom(class~., data = train_precip)
predicted.classes_precip <- pred.logis_precip %>% predict(test1)
mean(predicted.classes_precip == test1$class) # accuracy 0.4104046

### Decision Tree
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.dec_tree_precip <- train(train_precip[,c(1:12)], train_precip$class,
                                     method = "rpart", trControl = train.control,  metric = "Accuracy")
print(pred.dec_tree_precip) # 0.4209876

### Conditional Tree
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.cond_tree_precip <- train(class ~., method = "ctree", trControl = train.control,  metric = "Accuracy",
                                      data = train_precip)
print(pred.cond_tree_precip) # 0.4452383

### Random Forest
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.rf_precip <- train(class ~., method = "rf", trControl = train.control,  metric = "Accuracy",
                               data = train_precip)
print(pred.rf_precip) # 0.5451186

### Linear SVM
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.svm_linear_precip <- train(class ~., method = "svmLinear", trControl = train.control, metric = "Accuracy",
                                       data = train_precip)
print(pred.svm_linear_precip) # 0.3329117

### Radial SVM
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.svm_radial_precip <- train(class ~., method = "svmRadial", trControl = train.control, metric = "Accuracy",
                                       data = train_precip)
print(pred.svm_radial_precip) # 0.3844152

### Polynomial SVM
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.svm_pol_precip <- train(class ~., method = "svmPoly", trControl = train.control, metric = "Accuracy",
                                    data = train_precip)
print(pred.svm_pol_precip) # 0.3921160


####################################################################################################################

# REANALYSIS_PRECIP_AMT_KG_PER_M2

### KNN
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)
set.seed(2020)
pred.knn_reanalysis <- train(class~.,
                                    method     = "knn",
                                    tuneGrid   = expand.grid(k = 1:20),
                                    trControl  = train.control,
                                    metric     = "Accuracy",
                                    data       = train_reanalysis)
# Summarize the results
print(pred.knn_reanalysis) 

### Naive Bayes
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)
set.seed(2020)
pred.nb_reanalysis <- train(class~.,
                                   method     = "nb",
                                   #tuneGrid   = expand.grid(k = 1:20),
                                   trControl  = train.control,
                                   metric     = "Accuracy",
                                   data       = train_reanalysis)
# Summarize the results
print(pred.nb_reanalysis) 

### LDA
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.lda_reanalysis <- train(class ~., method = "lda", trControl = train.control,  metric = "Accuracy",
                                    data = train_reanalysis)
print(pred.lda_reanalysis) 

### LINDA (Robust LDA)
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.rlda_reanalysis <- train(class ~., method = "Linda", trControl = train.control,  metric = "Accuracy",
                                     data = train_reanalysis)
print(pred.rlda_reanalysis) 

### QDA
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.qda_reanalysis <- train(class ~., method = "qda", trControl = train.control,  metric = "Accuracy",
                                    data = train_reanalysis)
print(pred.qda_reanalysis) 

### QdaCov (Robust QDA)
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.rqda_reanalysis <- train(class ~., method = "QdaCov", trControl = train.control,  metric = "Accuracy",
                                     data = train_reanalysis)
print(pred.rqda_reanalysis) 

### Indicator Matrix
ntrain <- dim(train_reanalysis)[1]
k<-5
set.seed(2020)

# we shuffle the data and partition it in 5 folds
train_reanalysis <- train_reanalysis[sample(ntrain),]

set1.1 <- train_reanalysis[c(1:174),]
set1.2 <- train_reanalysis[c(174:348),]
set1.3 <- train_reanalysis[c(349:521),]
set1.4 <- train_reanalysis[c(522:694),]
set1.5 <- train_reanalysis[c(695:867),]


# we have to do 5 iterations changing the test set to do k fold cv
train1 <- rbind(set1.1, set1.2, set1.5, set1.4)
ntrain1 <- dim(train1)[1]
Y<-matrix(rep(0,ntrain1*k),nrow=ntrain1)
test1 <- set1.3

for (i in 1:ntrain1) {
  Y[i,train1$class[i]]<-1
  # for dataset 1
  regfits <- lm(Y~.,data=train1)}

ntest1<-dim(test1)[1]
yhattest <- numeric(ntest1)
yfitstest <- matrix(rep(0,ntest1*k),nrow=ntest1)
for (i in 1:ntest1) {
  yfitstest[i,] <- as.matrix(test1[i,1:12])%*%regfits$coef[1:12,]+regfits$coef[13,]
  yhattest[i]<-which(yfitstest[i,]==max(yfitstest[i,]))
}
# misclassification error estimate
print("Error: ") 
sum(yhattest[1:ntest1]!=test1[,13])/ntest1

# accuracy estimate
print("Accuracy: ") 
sum(yhattest[1:ntest1]==test1[,13])/ntest1

### Logistic Regression
pred.logis_reanalysis <- nnet::multinom(class~., data = train_reanalysis)
predicted.classes_reanalysis <- pred.logis_reanalysis %>% predict(test1)
mean(predicted.classes_reanalysis == test1$class) 

### Decision Tree
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.dec_tree_reanalysis <- train(train_reanalysis[,c(1:12)], train_reanalysis$class,
                                         method = "rpart", trControl = train.control,  metric = "Accuracy")
print(pred.dec_tree_reanalysis) 

### Conditional Tree
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.cond_tree_reanalysis <- train(class ~., method = "ctree", trControl = train.control,  metric = "Accuracy",
                                          data = train_reanalysis)
print(pred.cond_tree_reanalysis)

### Random Forest
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.rf_reanalysis <- train(class ~., method = "rf", trControl = train.control,  metric = "Accuracy",
                                   data = train_reanalysis)
print(pred.rf_reanalysis) 

### Linear SVM
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.svm_linear_reanalysis <- train(class ~., method = "svmLinear", trControl = train.control, metric = "Accuracy",
                                           data = train_reanalysis)
print(pred.svm_linear_reanalysis) 

### Radial SVM
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.svm_radial_reanalysis <- train(class ~., method = "svmRadial", trControl = train.control, metric = "Accuracy",
                                           data = train_reanalysis)
print(pred.svm_radial_reanalysis) # 0.3844152

### Polynomial SVM
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.svm_pol_reanalysis <- train(class ~., method = "svmPoly", trControl = train.control, metric = "Accuracy",
                                        data = train_reanalysis)
print(pred.svm_pol_reanalysis) 


####################################################################################################################

# STATION_PRECIP_MM

### KNN
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)
set.seed(2020)
pred.knn_station <- train(class~.,
                                 method     = "knn",
                                 tuneGrid   = expand.grid(k = 1:20),
                                 trControl  = train.control,
                                 metric     = "Accuracy",
                                 data       = train_station)
# Summarize the results
print(pred.knn_station) # 0.3613605

### Naive Bayes
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)
set.seed(2020)
pred.nb_station <- train(class~.,
                                method     = "nb",
                                #tuneGrid   = expand.grid(k = 1:20),
                                trControl  = train.control,
                                metric     = "Accuracy",
                                data       = train_station)
# Summarize the results
print(pred.nb_station) 

### LDA
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.lda_station <- train(class ~., method = "lda", trControl = train.control,  metric = "Accuracy",
                                 data = train_station)
print(pred.lda_station) 

### LINDA (Robust LDA)
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.rlda_station <- train(class ~., method = "Linda", trControl = train.control,  metric = "Accuracy",
                                  data = train_station)
print(pred.rlda_station) 

### QDA
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.qda_station <- train(class ~., method = "qda", trControl = train.control,  metric = "Accuracy",
                                 data = train_station)
print(pred.qda_station) 

### QdaCov (Robust QDA)
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.rqda_station <- train(class ~., method = "QdaCov", trControl = train.control,  metric = "Accuracy",
                                  data = train_station)
print(pred.rqda_station) 

### Indicator Matrix
ntrain <- dim(train_station)[1]
k<-5
set.seed(2020)

# we shuffle the data and partition it in 5 folds
train_station <- train_station[sample(ntrain),]

set1.1 <- train_station[c(1:174),]
set1.2 <- train_station[c(174:348),]
set1.3 <- train_station[c(349:521),]
set1.4 <- train_station[c(522:694),]
set1.5 <- train_station[c(695:867),]


# we have to do 5 iterations changing the test set to do k fold cv
train1 <- rbind(set1.1, set1.2, set1.5, set1.4)
ntrain1 <- dim(train1)[1]
Y<-matrix(rep(0,ntrain1*k),nrow=ntrain1)
test1 <- set1.3

for (i in 1:ntrain1) {
  Y[i,train1$class[i]]<-1
  # for dataset 1
  regfits <- lm(Y~.,data=train1)}

ntest1<-dim(test1)[1]
yhattest <- numeric(ntest1)
yfitstest <- matrix(rep(0,ntest1*k),nrow=ntest1)
for (i in 1:ntest1) {
  yfitstest[i,] <- as.matrix(test1[i,1:12])%*%regfits$coef[1:12,]+regfits$coef[13,]
  yhattest[i]<-which(yfitstest[i,]==max(yfitstest[i,]))
}
# misclassification error estimate
print("Error: ") 
sum(yhattest[1:ntest1]!=test1[,13])/ntest1

# accuracy estimate
print("Accuracy: ") 
sum(yhattest[1:ntest1]==test1[,13])/ntest1

### Logistic Regression
pred.logis_station <- nnet::multinom(class~., data = train_station)
predicted.classes_station <- pred.logis_station %>% predict(test1)
mean(predicted.classes_station == test1$class) 

### Decision Tree
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.dec_tree_station <- train(train_station[,c(1:12)], train_station$class,
                                      method = "rpart", trControl = train.control,  metric = "Accuracy")
print(pred.dec_tree_station) 

### Conditional Tree
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.cond_tree_station <- train(class ~., method = "ctree", trControl = train.control,  metric = "Accuracy",
                                       data = train_station)
print(pred.cond_tree_station)

### Random Forest
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.rf_station <- train(class ~., method = "rf", trControl = train.control,  metric = "Accuracy",
                                data = train_station)
print(pred.rf_station) 

### Linear SVM
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.svm_linear_station <- train(class ~., method = "svmLinear", trControl = train.control, metric = "Accuracy",
                                        data = train_station)
print(pred.svm_linear_station) 

### Radial SVM
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.svm_radial_station <- train(class ~., method = "svmRadial", trControl = train.control, metric = "Accuracy",
                                        data = train_station)
print(pred.svm_radial_station) # 0.3844152

### Polynomial SVM
train.control <- trainControl(method = "repeatedcv", number = 5, repeats = 3)

set.seed(2020)
pred.svm_pol_station <- train(class ~., method = "svmPoly", trControl = train.control, metric = "Accuracy",
                                     data = train_station)
print(pred.svm_pol_station) 