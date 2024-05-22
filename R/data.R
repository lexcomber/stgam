#' Data to showcase f**k count
#'
#' A dataset of annual economic productivity data for the 48 contiguous US states (with Washington DC merged into Maryland), from 1970 to 1985 (17 years) in long format. The data productivity data table was extracted from the `plm` package.
#'
#' @format A data frame with 816 rows and 14 columns.
#' \describe{
#' \item{state}{The name of the state}
#' \item{GEOID}{The state code}
#' \item{region}{The region}
#' \item{pubC}{Public capital which is composed of highways and streets (hwy) water and sewer facilities (water) and other public buildings and structures (util)}
#' \item{hwy}{Highway and streets assets}
#' \item{util}{Other public buildings and structures}
#' \item{gsp}{Gross state product}
#' \item{emp}{Labour input measured by the employment in non-agricultural payrolls}
#' \item{unemp}{State unemployment rate capture elements of the business cycle}
#' \item{X}{Easting in metres from USA Contiguous Equidistant Conic projection (ESRI:102005)}
#' \item{Y}{Northing in metres from USA Contiguous Equidistant Conic projection (ESRI:102005)}
#' }
#' @source Croissant, Yves, Giovanni Millo, and Kevin Tappe. 2022. Plm: Linear Models for Panel Data
#'
#' @examples
#' data(productivity)
"productivity"
