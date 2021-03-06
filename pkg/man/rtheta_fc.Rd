% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/core.R
\name{rtheta_fc}
\alias{rtheta_fc}
\title{rtheta_fc}
\usage{
rtheta_fc(XB, theta, UDU, Y, cinv, tau_i, s2)
}
\arguments{
\item{XB}{Time-length list of XB matrix}

\item{theta}{a T x n matrix of nodal effects}

\item{UDU}{Time-length list of UDU}

\item{Y}{relational array of relations}

\item{cinv}{inverse of Gaussian process covariance matrix}

\item{tau_i}{scale parameter of Gaussian process covariance}

\item{s2}{variance of normal error}
}
\value{
One sample estimate of theta from normal distribution
}
\description{
Sample theta with structural NA
}
