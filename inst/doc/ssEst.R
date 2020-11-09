## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(BayesMassBal)
set.seed(5)

## ----datagen, echo = FALSE----------------------------------------------------
y <- rep(NA, times = 41)
y[1] <- 10
mu <- 20
alpha <- 0.8
sig <- 10

for(i in 2:length(y)){
  y[i] <- mu + alpha * y[i-1] + rnorm(1)*sig
}

plot(0:(length(y)-1),y,main= "Observations", ylab = "Mass Flow Rate of an Element", xlab ="Time", pch = 19)

## ----fakedatagen, eval = FALSE------------------------------------------------
#  y <- rep(NA, times = 41)
#  y[1] <- 10
#  mu <- 20
#  alpha <- 0.8
#  sig <- 10
#  
#  for(i in 2:length(y)){
#    y[i] <- mu + alpha * y[i-1] + rnorm(1)*sig
#  }

## ----ssEstunconst-------------------------------------------------------------
fit1 <- ssEst(y)

## ----plot1--------------------------------------------------------------------
plot(fit1)

## ----ssConst------------------------------------------------------------------
fit2 <- ssEst(y, stationary = TRUE)
plot(fit2)

