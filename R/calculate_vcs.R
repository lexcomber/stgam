#' Extracts varying coefficient estimates (for SVC, TVC and STVC models).
#'
#' @param input_data the data used to create the GAM model in `data.frame`, `tibble` or `sf` format
#' @param mgcv_model a GAM model with smooths created using the `mgcv` package
#' @param terms a vector of names starting with "Intercept" plus the names of the covariates used in the GAM model (these are the names of the variables in `data` )
#'
#' @return A `data.frame` of the input data and the coefficient and standard error estimates for each covariate. It can be used to generate coefficient estimates for specific time slices and over grided surfaces as described in the package vignette.
#' @importFrom dplyr mutate
#' @importFrom stats predict
#'
#' @examples
#' require(dplyr)
#' require(doParallel)
#' # define input data
#' data("hp_data")
#' input_data <-
#'   hp_data |>
#'   # create Intercept as an addressable term
#'   mutate(Intercept = 1)
#' # evaluate different model forms
#' svc_mods <-
#'   evaluate_models(
#'     input_data = input_data,
#'     target_var = "priceper",
#'     vars = c("pef", "beds"),
#'     coords_x = "X",
#'     coords_y = "Y",
#'     STVC = FALSE,
#'     time_var = NULL,
#'     ncores = 2
#'   )
#' mod_comp <- gam_model_rank(svc_mods)
#' # have a look
#' mod_comp |> select(-f)
#' # select best model
#' f = as.formula(mod_comp$f[1])
#' # put into a `mgcv` GAM model
#' gam.m = gam(f, data = input_data)
#' # calculate the Varying Coefficients
#' terms = c("Intercept", "pef")
#' vcs = calculate_vcs(input_data, gam.m, terms)
#' vcs |> select(priceper, yot, X, Y, starts_with(c("b_", "se_")), yhat)
#'
#' @export
calculate_vcs <- function (input_data, mgcv_model, terms = NULL) {
  . = NULL
  if(is.null(terms)) {
    n_t = 1
  } else {
    n_t = length(terms)
  }
  input_data_copy = input_data
  output_data = input_data
  for (i in 1:n_t) {
    zeros = rep(0, n_t)
    zeros[i] = 1
    terms_df = data.frame(matrix(rep(zeros, nrow(input_data)),
                                 ncol = n_t, byrow = T))
    names(terms_df) = terms
    input_data_copy[, terms] = terms_df
    se.j = predict(mgcv_model, se = TRUE, newdata = input_data_copy)$se.fit
    b.j = predict(mgcv_model, newdata = input_data_copy)
    expr1 = paste0("b_", terms[i])
    expr2 = paste0("se_", terms[i])
    output_data[[expr1]] <- as.vector(unlist(with(output_data, b.j)))
    output_data[[expr2]] <- as.vector(unlist(with(output_data, se.j)))
  }
  if( all(terms %in% names(input_data))) {
    output_data$yhat = predict(mgcv_model, newdata = input_data)
  }
  return(output_data)
}




