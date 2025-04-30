#' London House Price dataset (Terraced, 2018-2024)
#'
#' A dataset of a sample terraced houses sales in the London area for 2018 to 2024.
#'
#' @format A tibble with 1888 rows and 13 columns.
#' \describe{
#' \item{price}{The house price in £1000s}
#' \item{priceper}{The house price per square metre in £s}
#' \item{tfa}{Total floor area}
#' \item{dot}{Date of transfer (sale))}
#' \item{yot}{Year of transfer (sale)}
#' \item{beds}{Number of bedrooms}
#' \item{type}{House type - here all `T` (terraced)}
#' \item{cef}{Current energy efficiency rating (values from 0-100)}
#' \item{pef}{Potential energy efficiency rating (values from 0-100)}
#' \item{ageb}{The age band of the house constructtion}
#' \item{lad}{The local authority district code of the property location}
#' \item{X}{Easting in metres derived from the geometric centroid (in OSGB projecttion - EPSG 27700) of the postcode of the sale}
#' \item{Y}{Northing in metres derived from the geometric centroid (in OSGB projecttion - EPSG 27700) of the postcode of the sale}
#' }
#' @source Chi, Bin, Dennett, Adam, Oléron-Evans, Thomas and Robin Morphet. 2025. House Price per Square Metre in England and Wales (https://data.london.gov.uk/dataset/house-price-per-square-metre-in-england-and-wales)
#'
#' @examples
#' data("hp_data")
"hp_data"

#' London borough boundaries
#'
#' A spatial dataset of of the boundaries of the 33 London Boroughs extracted from the `GWModel` package, cleaned and converted to `sf`.
#'
#' @format A `sf` polygon (MULTIPOLYGON) dataset with 33 observations and 2 fields.
#' \describe{
#' \item{name}{The name of the London borough}
#' \item{lad}{The ONS lcoal authrority district code for the borough}
#' }
#' @source Lu, Binbin, Harris, Paul, Charlton, Martin, Brunsdon, Chris, Nakaya, Tomoki, Murakami, Daisuke, Hu, Yigong, Evans, Fiona H, Høglund, Hjalmar. 2024. Geographically-Weighted Models
#'
#' @examples
#' data("lb")
"lb"
