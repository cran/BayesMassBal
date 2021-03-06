% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/twonodeSim.R
\name{twonodeSim}
\alias{twonodeSim}
\title{Two Node Process Data Simulation}
\usage{
twonodeSim(
  K = 7,
  feed = list(rate = 100, sd = 6, CuFeS2grade = 1.2),
  rec = list(CuFeS2 = list(mean = c(98, 95)/100, var = c(5e-05, 8e-05)), gangue =
    list(mean = c(7, 4)/100, var = c(5e-05, 2.5e-05))),
  assayNoise = list(CuFeS2 = c(0.15, 0.2, 0.05, 5e-05, 0.005), gangue = c(5, 1, 0.03,
    2, 0.5)),
  truncation = TRUE
)
}
\arguments{
\item{K}{Numeric specifying the number of sample sets to be simulated.}

\item{feed}{List specifying qualities for the process grade.  See default for required structure.  \code{rate} is the mean feed rate.  \code{sd} is the standard deviation of the feed rate.  \code{CuFeS2grade} is the mass percent CuFeS2 present in the feed.  Grade is not stochastic.  See Details for important information on specifying these values.}

\item{rec}{List specifying mean and variance in process performance.  See default for required structure. \code{rec$component$mean} is a vector giving mean fractional recovery of the given component for \code{c(node1,node2)}.  \code{rec$component$var} gives the variance in the process in a similar manner.  See Details.}

\item{assayNoise}{List specifying standard deviations of random noise added to simulated process outputs.  See default for required structure.  The index of a vector within the list is equivalent to the index of the sampling location.  See Details section for important information on specifying these values.}

\item{truncation}{Logical indicating if the simulation should be rerun, and previous results discarded, until no observed values are less than 0. Default is TRUE.  See details for more information.}
}
\value{
Returns a list of simulated data and expected values.  List members are as follows:

\item{\code{simulation}}{List of matrices giving simulated data.  \code{twonodeSim()$simulation} is structured so that it can directly be passed to the \code{\link{BMB}} function as the \code{y} argument.}

\item{\code{expectations}}{List of matrices giving expected values of the mass flow rate for each component at every location.  See the Details section for information about instances that may create reliability issues with this output.}
}
\description{
Simulates data for a stochastic two node, two component process at steady state.  Location indices are the same as what is shown in \code{vignette("Two_Node_Process", package = "BayesMassBal")}.
}
\details{
Each of the \code{K} data sets collected from the \code{twonodeSim()} simulation is independent and identically distributed.

The feed rate to the process is normally distributed with a mean of \code{feed$rate}, and a standard deviation of \code{feed$sd}.  If the feed rate is sufficiently small, and the standard deviation is sufficiently large, negative feed rates can be generated.

Process recovery at each node is simulated from a \href{https://en.wikipedia.org/wiki/Beta_distribution}{beta distribution}, reparameterized as shown in \href{https://stats.stackexchange.com/a/12239}{this post} to make parameter specification more intuitive.  This reparameterization is only valid when \eqn{\sigma^2 \leq \mu(1-\mu)}, and the list argument \code{rec} must be specified as such.

The steps of the simulation for each sample set are:

\enumerate{
\item Draw a random normally distributed feed rate.
\item Draw random values for recovery of the two components at each node.
\item Calculate mass flow rate at each location.  These mass flow rates are the \emph{true} mass flow rates, given the process variability.
\item Adds normally distributed noise to each observation as specified in argument \code{assayNoise}
}

\strong{If the standard deviations supplied to \code{feed} and \code{assayNoise} are sufficiently large, the simulation can return negative mass flow rates.}

The argument \code{truncation = TRUE} discards negative mass flow rates, and reruns the simulation until all values are non-negative.  For some combinations of a large \code{K} and specifications in \code{feed} and \code{assayNoise}, this can happen frequently.  If if the simulation is run three or more times a warning will be printed that the returned expectations are unreliable.  If this is the case, expectations should be calculated using analytical or Monte-Carlo methods outside of the abilities of this function.  For the default parameters, truncation can occur, but is rare.  The default parameters were chosen in a way that makes a truncation warning highly unlikely.
}
\examples{

y <- twonodeSim()$simulation

## Then the BMB function can be run as
\donttest{C <- matrix(c(1,-1,0,-1,0,0,1,-1,0,-1), byrow = TRUE, ncol = 5, nrow = 2)
X <- constrainProcess(C = C)
}
\donttest{BMB(X = X, y = y, BTE = c(100,600,1))}
}
