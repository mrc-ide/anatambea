% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{user_informed}
\alias{user_informed}
\title{Transformation function that calculates initial values for stochastic model}
\usage{
user_informed(init_state)
}
\arguments{
\item{init_state}{Initial state}
}
\description{
\code{user_informed} Calculates the model equilibrium based on an initial EIR values,
then optionally runs a deterministic seasonal model and returns initial
values to be used for the stochastic model fitting.
}
