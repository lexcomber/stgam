% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data.R
\docType{data}
\name{us_data}
\alias{us_data}
\title{US States boundaries}
\format{
A \code{sf} polygon dataset with 48 rows and 6 fields.
\describe{
\item{GEOID}{The state code}
\item{NAME}{The name of the state}
\item{REGION}{The region}
\item{total_pop_10}{Population in 2010}
\item{total_pop_15}{Population in 2015}
}
}
\source{
Bivand, Roger, Jakub Nowosad, and Robin Lovelace. 2019. spData: Datasets for Spatial Analysis. R package
}
\usage{
us_data
}
\description{
A dataset of of the boundaries of 48 contiguous US states (with Washington DC merged into Maryland),  extracted from the \code{spData} package.
}
\examples{
data(us_data)
}
\keyword{datasets}
