#' Quantifies the relative effect sizes of each component of zmgcv` GAM model.
#'
#' @param mgcv_model a GAM model created by the `mgcv` package
#' @param digits the number of significant figures of uysed to report effect size
#'
#' @returns a matrix of the model terms, the size of the effect (range) ad standard deviation (sd)
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
#'   te(X,Y, by = tmax) +
#'   s(X,Y, by = pr),
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
