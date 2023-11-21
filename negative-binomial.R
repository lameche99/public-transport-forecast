library(MASS)
library(tidyverse)
library(ggplot2)
library(lmtest)
setwd('~/Desktop/ISYE6414/public-transport-forecast')

transport <- read.table('./data/final_transportation.csv',
                        sep = ',',
                        header = TRUE)[,-1]
transport$Mode <- as.factor(transport$Mode)
transport$Season <- as.factor(transport$Season)
transport$Date <- as.Date(transport$Date)
transport$Month <- as.factor(months(transport$Date))

transport.3yr <- transport[transport$Date > '2019-12-31',]
transport.15yr <- transport[transport$Date <= '2019-12-31',]

#Negative Binomial
neg.bin <- glm.nb(UPT ~.-pubRate - Date - population - Month,
                      data = transport, link = log,
                      init.theta = 5)
neg.bin.3yr <- glm.nb(UPT ~.-pubRate - Date - population - Month,
                        data = transport.3yr, link = log,
                        init.theta = 5)
neg.bin.15yr <- glm.nb(UPT ~.-pubRate - Date - population - Month,
                            data = transport.15yr, link = log,
                            init.theta = 5)
summary(neg.bin)
summary(neg.bin.3yr)
summary(neg.bin.15yr)

#GOF
## Deviance Residuals
devi.std.full <- deviance(neg.bin)
devi.std.p.full <- 1 - pchisq(devi.std.full, 1790)
round(c(devi.std.full, devi.std.p.full), 2)
devi.std.3yr <- deviance(neg.bin.3yr)
devi.std.p.3yr <- 1 - pchisq(devi.std.3yr, 336)
round(c(devi.std.3yr, devi.std.p.3yr), 2)
devi.std.15yr <- deviance(neg.bin.15yr)
devi.std.p.15yr <- 1 - pchisq(devi.std.15yr, 1440)
round(c(devi.std.15yr, devi.std.p.15yr), 2)
## Pearson Residuals
pears.full <- residuals(neg.bin, type = 'pearson')
pearson.full <- sum(pears.full^2)
pears.p.full <- 1 - pchisq(pearson.full, 1790)
round(c(pearson.full, pears.p.full), 2)
pears.3yr <- residuals(neg.bin.3yr, type = 'pearson')
pearson.3yr <- sum(pears.3yr^2)
pears.p.3yr <- 1 - pchisq(pearson.3yr, 336)
round(c(pearson.3yr, pears.p.3yr), 2)
pears.15yr <- residuals(neg.bin.15yr, type = 'pearson')
pearson.15yr <- sum(pears.15yr^2)
pears.p.15yr <- 1 - pchisq(pearson.15yr, 1440)
round(c(pearson.15yr, pears.p.15yr), 2)

#Outliers
dev.resid.full <- residuals(neg.bin, type = 'deviance')
outliers.full<- which(abs(dev.resid.full)>qnorm(0.99995))
length(outliers.full)
dev.resid.3yr <- residuals(neg.bin.3yr, type = 'deviance')
outliers.3yr<- which(abs(dev.resid.3yr)>qnorm(0.99995))
length(outliers.3yr)
dev.resid.15yr <- residuals(neg.bin.15yr, type = 'deviance')
outliers.15yr<- which(abs(dev.resid.15yr)>qnorm(0.99995))
length(outliers.15yr)

#Overdispersion
overdispersion.full <- pearson.full / neg.bin$df.residual
overdispersion.3yr <- pears.3yr / neg.bin.3yr$df.residual
overdispersion.15yr <- pears.15yr / neg.bin.15yr$df.residual
  
# GOF 2.0
with(neg.bin, cbind(res.deviance = deviance, df = df.residual, p = 1 - pchisq(deviance, df.residual)))
with(neg.bin.3yr, cbind(res.deviance = deviance, df = df.residual, p = 1 - pchisq(deviance, df.residual)))
with(neg.bin.15yr, cbind(res.deviance = deviance, df = df.residual, p = 1 - pchisq(deviance, df.residual)))

#Plots
qqnorm(residuals(neg.bin), col = 'blue')
qqline(residuals(neg.bin), col = 'red')
hist(residuals(neg.bin), nclass = 20, col = 'blue', border = 'gold', main = 'Histograms of Residuals', xlab = 'Residuals')
plot(neg.bin$fitted.values, residuals(neg.bin), xlab = 'Fitted Values', ylab = "Residuals")
dwtest(neg.bin, alternative = "two.sided")


qqnorm(residuals(neg.bin.3yr), col = 'blue')
qqline(residuals(neg.bin.3yr), col = 'red')
hist(residuals(neg.bin.3yr), nclass = 20, col = 'blue', border = 'gold', main = 'Histograms of Residuals', xlab = 'Residuals')
plot(neg.bin.3yr$fitted.values, residuals(neg.bin.3yr), xlab = 'Fitted Values', ylab = "Residuals")
dwtest(neg.bin.3yr, alternative = "two.sided")

qqnorm(residuals(neg.bin.15yr), col = 'blue')
qqline(residuals(neg.bin.15yr), col = 'red')
hist(residuals(neg.bin.15yr), nclass = 20, col = 'blue', border = 'gold', main = 'Histograms of Residuals', xlab = 'Residuals')
plot(neg.bin.15yr$fitted.values, residuals(neg.bin.15yr), xlab = 'Fitted Values', ylab = "Residuals")
dwtest(neg.bin.15yr, alternative = "two.sided")
