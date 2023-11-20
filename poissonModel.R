library(MASS)
library(tidyverse)
library(ggplot2)
setwd('~/Desktop/ISYE6414/public-transport-forecasting')

transport <- read.table('./data/final_transportation.csv', sep = ',', header = TRUE)[,-1]
transport$Mode <- as.factor(transport$Mode)
transport$Season <- as.factor(transport$Season)

boxplot(pubRate~Season, xlab = 'Season', ylab = 'Rate of Public Transport Use', data = transport)
boxplot(pubRate~Mode, xlab = 'Mode', ylab = 'Rate of Public Transport Use', data = transport)

trans.pois <- glm(UPT ~ Season + Mode + RE + Unemployment + WTI + AutoSales + CPI + CPIcn + CPIcu + offset(log(population)), data = transport, family = 'poisson')
summary(trans.pois)
trans.mlr <- lm(UPT ~ Season + Mode + RE + Unemployment + WTI + AutoSales + CPI + CPIcn + CPIcu, data = transport)
summary(trans.mlr)

#GOF
devi.std <- deviance(trans.pois)
devi.std.p <- 1 - pchisq(devi.std, 1790)
round(c(devi.std, devi.std.p), 2)

pears <- residuals(trans.pois, type = 'pearson')
pearson <- sum(pears^2)
pears.p <- 1 - pchisq(pearson, 1790)
round(c(pearson, pears.p), 2)

#Outliers
dev.resid <- residuals(trans.pois, type = 'deviance')
outliers <- which(abs(dev.resid)>qnorm(0.99995))
length(outliers)

#Overdispersion
wdf <- trans.pois$df.residual
overdispersion <- trans.pois$deviance / wdf
overdispersion

#Quasi-Poisson
trans.quasi <- glm(UPT ~ Season + Mode + RE + Unemployment + WTI + AutoSales + CPI + CPIcn + CPIcu, offset = offset(log(population)), data = transport, family = 'quasipoisson')
#Negative Binomial
trans.neg.bin <- glm.nb(UPT ~.-pubRate - Date, data = transport, link = log, init.theta = 5)
summary(trans.quasi)
summary(trans.neg.bin)

# GOF Quasi-Poisson & Negative Binomial
with(trans.quasi, cbind(res.deviance = deviance, df = df.residual, p = 1 - pchisq(deviance, df.residual)))
with(trans.neg.bin, cbind(res.deviance = deviance, df = df.residual, p = 1 - pchisq(deviance, df.residual)))

#Plots
qqnorm(residuals(trans.neg.bin), col = 'blue')
qqline(residuals(trans.neg.bin), col = 'red')
hist(residuals(trans.neg.bin), nclass = 20, col = 'blue', border = 'gold', main = 'Histograms of Residuals')

# Predictions
mse <- function(pred, data){
  round(mean((pred - data)^2), 4)
}
mae <- function(pred, data) {
  round(mean(abs(pred - data)), 4)
}
mape <- function(pred, data) {
  round(mean(abs(pred - data) / abs(data)), 4)
}
pm <- function(pred, data) {
  round(sum((pred - data)^2) / sum((data - mean(data))^2), 4)
}
prediction <- function(model, test) {
  pred <- predict(model, test, type = 'response')
  test.pred <- pred
  pred.metrics <- c(
    mse(test.pred, test$UPT),
    mae(test.pred, test$UPT),
    mape(test.pred, test$UPT),
    pm(test.pred, test$UPT)
  )
  return(pred.metrics)
}
## prepare data for prediction
clean <- transport[-c(1, 13)]
n <- nrow(clean)
## Poisson Monte-Carlo
set.seed(6414)
poisson.meas <- matrix(0,4,100)
for (i in 1:100) {
  sample.size <- floor(0.8*n)
  sample.obs <- sample(seq_len(n), size = sample.size)
  train.pois.curr <- clean[sample.obs,]
  test.pois.curr <- clean[-sample.obs,]
  pois.train <- glm(UPT ~. + offset(log(population)), data = train.pois.curr, family = 'poisson')
  poisson.meas[,i] <- prediction(pois.train, test.pois.curr)
}
pois.res <- round(apply(poisson.meas, 1, mean), 4)
## Quasi-Poisson Monte-Carlo
set.seed(6414)
quasi.meas <- matrix(0,4,100)
for (i in 1:100) {
  sample.size <- floor(0.8*n)
  sample.obs <- sample(seq_len(n), size = sample.size)
  train.quasi.curr <- clean[sample.obs,]
  test.quasi.curr <- clean[-sample.obs,]
  quasi.train <- glm(UPT ~. - population, offset = offset(log(population)), data = train.pois.curr, family = 'quasipoisson')
  quasi.meas[,i] <- prediction(quasi.train, test.quasi.curr)
}
quasi.res <- round(apply(quasi.meas, 1, mean), 4)
quasi.res

## Negative Binomial Monte-Carlo
set.seed(6414)
neg.bin.meas <- matrix(0,4,100)
for (i in 1:100) {
  sample.size <- floor(0.8*n)
  sample.obs <- sample(seq_len(n), size = sample.size)
  train.neg.bin.curr <- clean[sample.obs,]
  test.neg.bin.curr <- clean[-sample.obs,]
  neg.bin.train <- glm.nb(UPT ~., data = train.neg.bin.curr, link = log, init.theta = 5)
  neg.bin.meas[,i] <- prediction(neg.bin.train, test.neg.bin.curr)
}
neg.bin.res <- round(apply(neg.bin.meas, 1, mean), 4)
neg.bin.res

pred.results <- cbind.data.frame(pois.res, quasi.res, neg.bin.res)
pred.results$metric <- c('MSE', 'MAE', 'MAPE', 'PM')
colnames(pred.results) <- c('Poisson', 'Quasi-Poisson', 'Negative Binomial', 'Metrics')

pred.results
