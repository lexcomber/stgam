#' Quantifies the relative effect sizes of each component of zmgcv` GAM model.
#'
#' @param mgcv_model a GAM model created by the `mgcv` package
#' @param digits the number of significant figures of uysed to report effect size
#'
#' @returns a `tibble` of the 'n' best models, ranked by GCV, with the form of each predictor variable where '---' indicates the absence of a predictor, 'Fixed' that a parametric form was specified,  's_S' a spatial smooth, 's_T'  a temporal smooth and 'te_ST' a spatio-temporal smooth.
#' @importFrom mgcv predict.gam
#'
#' @examples
#' require(dplyr)
#' require(stringr)
#' require(purrr)
#' require(doParallel)
#'
#' # define input data
#' data("chaco")
#' m <- gam(
#' ndvi ~
#'   te(X,Y,month, by = tmax, bs = c("tp", "cr"), d = c(2,1)) +
#'   pr + s(X,Y, by = pr) + s(month, by = pr),
#'  data = chaco,
#'  method = "REML",
#'  family = gaussian()
#' )
#' # examine the effect size
#' effect_size(m, 3)
#' @export
effect_size <- function(mgcv_model, digits = 3) {
  if (!inherits(mgcv_model, "gam")) {
    stop("Error: 'mgcv_model' must be a GAM object from mgcv::gam().")
  }
  # extract the terms
  f <- predict(mgcv_model, type = "terms")
  # generate numeric summaries
  out <- apply(f, 2, function(v) c(sd = sd(v), range = diff(range(v)))) |> round(digits)
  return(out)
}
