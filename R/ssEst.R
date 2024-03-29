#' Steady State Estimate
#'
#' Allows for the estimation of process steady state of a single stream for a process using flow rate data.
#'
#' @param y Vector of mass flow rate observations.  Must be specified sequentially with \code{y[1]} as the initial observation.
#' @param BTE Numeric vector giving \code{c(Burn-in, Total-iterations, and Every)} for MCMC approximation of target distributions. The function \code{BMB} produces a total number of samples of \eqn{(T - B)/E}.  \eqn{E} specifies that only one of every \eqn{E} draws are saved. \eqn{E > 1} reduces autocorrelation between obtained samples at the expense of computation time.
#' @param stationary Logical indicating if stationarity will be imposed when generating posterior draws.  See Details.
#'
#' @return Returns a list of outputs
#' @return \item{\code{samples}}{List of vectors containing posterior draws of model parameters}
#' @return \item{\code{stationary}}{Logical indicating the setting of the \code{stationary} argument provided to the \code{ssEst} function}
#' @return \item{\code{y}}{Vector of observations initially passed to the \code{ssEst} function.}
#' @return \item{\code{type}}{Character string giving details of the model fit.  Primarily included for use with \code{\link{plot.BayesMassBal}}}
#'
#' @details
#'
#' The model of the following form is fit to the data:
#'
#' \deqn{y_t = \mu + \alpha y_{t-1} + \epsilon}
#'
#' Where \eqn{\epsilon \sim \mathcal{N}(0,\sigma^2)} and \eqn{t} indexes the time step.
#'
#' A time series is stationary, and predictable, when \eqn{|\alpha|< 1}.  Stationarity can be enforced, using the argument setting \code{stationary = TRUE}.  This setting utilizes the priors \eqn{p(\alpha) \sim \mathcal{N}}(0, 1000) truncated at (-1,1), and \eqn{p(\mu) \sim \mathcal{N}}(0, \code{var(y)*100}) for inference, producing a posterior distribution for \eqn{\alpha} constrained to be within (-1,1).
#'
#' When fitting a model where stationarity is not enforced, the Jeffreys prior of \eqn{p(\mu,\alpha)\propto 1} is used.
#'
#' The Jeffreys prior of \eqn{p(\sigma^2)\propto 1/\sigma^2} is used for all inference of \eqn{\sigma^2}
#'
#' A stationary time series will have an expected value of:
#'
#' \deqn{\frac{\mu}{1-\alpha}}
#'
#' Samples of this expectation are included in the output if \code{stationary = TRUE} or if none of the samples of \eqn{\alpha} lie outside of (-1,1).
#'
#' The output list is a \code{BMB} object, passing the output to \code{\link{plot.BayesMassBal}} allows for observation of the results.
#'
#' @examples
#'
#' ## Generating Data
#' y <- rep(NA, times = 21)
#'
#' y[1] <- 0
#' mu <- 3
#' alpha <- 0.3
#' sig <- 2
#' for(i in 2:21){
#'  y[i] <- mu + alpha*y[i-1] + rnorm(1)*sig
#' }
#'
#' ## Generating draws of model parameters
#'
#' fit <- ssEst(y, BTE = c(100,500,1))
#'
#' @importFrom stats var
#' @importFrom tmvtnorm rtmvnorm
#' @importFrom LaplacesDemon rinvgamma
#' @export

ssEst <- function (y, BTE = c(100, 1000, 1), stationary = FALSE)
{
  burn <- BTE[1]
  total <- BTE[2]
  every <- BTE[3]
  collected <- ceiling((total - burn)/every)
  y <- drop(y)
  Y <- y[-1]
  X <- matrix(1, nrow = length(y) - 1, ncol = 2)
  X[, 2] <- y[-length(y)]
  sig <- rep(NA, times = collected)
  beta <- matrix(NA, nrow = 2, ncol = collected)
  sigsamp <- var(y)
  if (stationary == TRUE) {
    B0 <- c(mean(y), 0)
    V0i <- diag(c(1/(sigsamp * 100), 1/(1000)))
    V0iB0 <- V0i %*% B0
    XTX <- t(X) %*% X
    V <- solve((1/sigsamp)*XTX  + V0i)
    bhat <- as.vector(V %*% (V0iB0 + (1/sigsamp) * t(X) %*%
                               Y))
    lb <- c(-Inf, -1)
    ub <- c(Inf, 1)
  }
  else if (stationary == FALSE) {
    bhat <- as.vector(solve(t(X) %*% X) %*% t(X) %*% Y)
    XTXi <- solve(t(X) %*% X)
    V <- XTXi * sigsamp
    lb <- c(-Inf, -Inf)
    ub <- c(Inf, Inf)
  }
  bsamp <- bhat
  a <- length(Y)/2
  for (i in 1:total) {
    bsamp <- as.vector(rtmvnorm(1, mean = bhat, sigma = V,
                                lower = lb, upper = ub))
    ymXB <- Y - X %*% bsamp
    b <- 0.5 * t(ymXB) %*% ymXB
    sigsamp <- rinvgamma(1, shape = a, scale = b)
    if (i > burn & ((i - burn)/every)%%1 == 0) {
      save.sel <- (i - burn)/every
      beta[, save.sel] <- bsamp
      sig[save.sel] <- sigsamp
    }
    if (stationary == TRUE) {
      V <- solve(XTX * (1/sigsamp) + V0i)
      bhat <- as.vector(V %*% (V0iB0 + (1/sigsamp) * t(X) %*%
                                 Y))
    }
    else {
      V <- XTXi * sigsamp
    }
  }
  if (stationary == TRUE) {
    expectation <- beta[1, ]/(1 - beta[2, ])
    samples <- list(mu = beta[1, ], alpha = beta[2, ], expectation = expectation,
                    s2 = sig)
  }
  else if (sum(beta[2, ] <= -1) == 0 & sum(beta[2, ] >= 1) ==
           0) {
    expectation <- beta[1, ]/(1 - beta[2, ])
    samples <- list(mu = beta[1, ], alpha = beta[2, ], expectation = expectation,
                    s2 = sig)
  }
  else {
    samples <- list(mu = beta[1, ], alpha = beta[2, ], s2 = sig)#, expectation = "Unable to compute expected value of y")
  }
  out <- list(samples = samples, stationary = stationary, y = y,
              type = "time-series")
  class(out) <- "BayesMassBal"
  return(out)
}

