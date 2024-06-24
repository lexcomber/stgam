#' Extracts varying coefficient estimates (for SVC, TVC and STVC models).
#'
#' @param model a GAM model with smooths created using the `mgcv` package
#' @param terms a vector of names starting with "Intercept" plus the names of the covariates used in the GAM model (these are the names of the variables in `data` )
#' @param data the data used to create the GAM model, `data.frame` or `tibble` format
#'
#' @return A `data.frame` of the input data and the coefficient and standard error estimates for each covariate.
#' @importFrom magrittr %>%
#' @importFrom dplyr mutate
#' @importFrom stats predict
#'
#' @examples
#' library(dplyr)
#' library(mgcv)
#' # SVC
#' data(productivity)
#' data = productivity |> dplyr::filter(year == "1970") |> mutate(Intercept = 1)
#' gam.svc.mod = gam(privC ~ 0 + Intercept +
#'                   s(X, Y, bs = 'gp', by = Intercept) +
#'                   unemp + s(X, Y, bs = "gp", by = unemp) +
#'                   pubC + s(X, Y, bs = "gp", by = pubC),
#'                   data = data)
#' terms = c("Intercept", "unemp", "pubC")
#' svcs = calculate_vcs(gam.svc.mod, terms, data)
#' @export
calculate_vcs = function(model, terms, data) {
  . = NULL
  n_t = length(terms)
  input_data_copy = data
  output_data = data
  for (i in 1:n_t) {
    zeros = rep(0, n_t)
    zeros[i] = 1
    terms_df = data.frame(matrix(rep(zeros, nrow(data)), ncol = n_t, byrow = T))
    names(terms_df) = terms
    input_data_copy[, terms] = terms_df
    se.j = predict(model, se = TRUE, newdata = input_data_copy)$se.fit
    b.j=predict(model,newdata=input_data_copy)
    expr1 = paste0("b_", terms[i], "= b.j")
    expr2 = paste0("se_",terms[i], "= se.j")
    output_data = output_data %>%
      mutate(within(., !!parse(text = expr1))) %>%
      mutate(within(., !!parse(text = expr2)))
  }
  output_data$yhat = predict(model, newdata = data)
  output_data
}



