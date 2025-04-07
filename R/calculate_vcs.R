#' Extracts varying coefficient estimates (for SVC, TVC and STVC models).
#'
#' @param input_data the data used to create the GAM model in `data.frame`, `tibble` or `sf` format
#' @param model a GAM model with smooths created using the `mgcv` package
#' @param terms a vector of names starting with "Intercept" plus the names of the covariates used in the GAM model (these are the names of the variables in `data` )
#'
#' @return A `data.frame` of the input data and the coefficient and standard error estimates for each covariate.
#' @importFrom dplyr mutate
#' @importFrom stats predict
#'
#' @examples
#' require(dplyr)
#' # define input data
#' input_data = productivity |> filter(year == 1975) |> mutate(Intercept = 1)
#' # determine length ranges
#' rho_sp <- opt_length_scale(input_data,
#'        target_var = "privC",
#'        vars = c("Intercept", "unemp", "pubC"),
#'        coords_x = "X",
#'        coords_y = "Y",
#'        STVC = FALSE)
#' # evaluate different model forms
#' svc_mods = evaluate_models(
#'        input_data = input_data,
#'        target_var = "privC",
#'        vars = c("unemp", "pubC"),
#'        coords_x = "X",
#'        coords_y = "Y",
#'        STVC = FALSE,
#'        rho_space_vec = round(rho_sp$rho_space,1))
#' # rank models and translate predicor variable indices
#' mod_comp <- gam_model_scores(svc_mods)
#' # have a look
#' mod_comp
#' # select best model
#' f = as.formula(mod_comp$f[1])
#' # put into a `mgcv` GAM model
#' m = gam(f, data = input_data)
#' # calculate the Varying Coefficients
#' terms = c("Intercept", "unemp", "pubC")
#' vcs = calculate_vcs(input_data, m, terms)
#' vcs |> select(state, year, starts_with(c("b_", "se_")))
#' @export
calculate_vcs = function(input_data, model, terms) {
  . = NULL
  n_t = length(terms)
  input_data_copy = input_data
  output_data = input_data
  for (i in 1:n_t) {
    zeros = rep(0, n_t)
    zeros[i] = 1
    terms_df = data.frame(matrix(rep(zeros, nrow(input_data)), ncol = n_t, byrow = T))
    names(terms_df) = terms
    input_data_copy[, terms] = terms_df
    se.j = predict(model, se = TRUE, newdata = input_data_copy)$se.fit
    b.j=predict(model,newdata=input_data_copy)
    expr1 = paste0("b_", terms[i])
    expr2 = paste0("se_", terms[i])
    output_data[[expr1]] <- as.vector(unlist(with(output_data, b.j)))
    output_data[[expr2]] <- as.vector(unlist(with(output_data, se.j)))
  }
  output_data$yhat = predict(model, newdata = input_data)
  output_data
}




