#' Extracts varying coefficient estimates (for SVC, TVC and STVC models).
#'
#' @param input_data the data used to create the GAM model in `data.frame`, `tibble` or `sf` format. This can be the original data used to create the model or another surface with location and time attributes.
#' @param mgcv_model a GAM model with smooths created using the `mgcv` package
#' @param terms a vector of names starting with "Intercept" plus the names of the covariates used in the GAM model (these are the names of the variables in the `input_data` used to construct the model).
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
#' # create a model for example as result of running `evaluate_models`
#' gam.m = gam(priceper ~ Intercept - 1 + s(X, Y, by = Intercept) +
#'  s(X, Y, by = pef) + s(X, Y, by = beds), data = input_data)
#' # calculate the Varying Coefficients
#' terms = c("Intercept", "pef", "beds")
#' vcs = calculate_vcs(input_data, gam.m, terms)
#' vcs |> select(priceper, X, Y, starts_with(c("b_", "se_")), yhat)
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




