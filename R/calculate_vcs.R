#' Extracts varying coefficient estimates (for SVC, TVC and STVC models).
#'
#' @param input_data the data used to create the GAM model in `data.frame`, `tibble` or `sf` format. This can be the original data used to create the model or another surface with location and time attributes.
#' @param mgcv_model a GAM model with smooths created using the `mgcv` package
#' @param terms a vector of names starting with "Intercept" plus the names of the covariates used in the GAM model (these are the names of the variables in the `input_data` used to construct the model).
#'
#' @return A `data.frame` of the input data, the coefficient estimates, the standard errors and the t-values estimates for each covariate. It can be used to generate coefficient estimates for specific time slices and over gridded surfaces as described in the package vignette.
#' @importFrom dplyr mutate
#' @importFrom stats predict
#'
#' @examples
#' require(dplyr)
#' require(doParallel)
#' # define input data
#' data("chaco")
#' input_data <-
#'   chaco |>
#'   # create Intercept as an addressable term
#'   mutate(Intercept = 1)
#' # create a model for example as result of running `evaluate_models`
#' gam.m = gam(ndvi ~ 0 + s(X, Y, by = Intercept) +
#'  s(X, Y, by = tmax) + s(X, Y, by = pr), data = input_data)
#' # calculate the Varying Coefficients
#' terms = c("Intercept", "tmax", "pr")
#' vcs = calculate_vcs(input_data, gam.m, terms)
#' vcs |> select(ndvi, X, Y, starts_with(c("b_", "se_", "t_")), yhat)
#'
#' @export
calculate_vcs <- function(input_data, mgcv_model, terms = NULL) {
  # --- Input validation ---
  if (!inherits(mgcv_model, "gam")) {
    stop("Error: 'mgcv_model' must be a GAM object from mgcv::gam().")
  }
  if (!is.data.frame(input_data)) {
    stop("Error: 'input_data' must be a data.frame.")
  }
  if (is.null(terms)) {
    # Default to all parametric terms
    terms <- attr(mgcv_model$terms, "term.labels")
  }
  if (!all(terms %in% names(input_data))) {
    missing_terms <- setdiff(terms, names(input_data))
    stop(paste("Error: The following terms are missing from input_data:",
               paste(missing_terms, collapse = ", ")))
  }
  if (is.null(terms)) {
    terms <- names(input_data)
  }
  n_t <- length(terms)

  # preallocate output list
  output_data <- input_data

  # create a template for modifying predictor columns
  input_data_copy <- input_data
  n_rows <- nrow(input_data)

  # build all term-modified datasets at once
  term_mats <- diag(n_t)
  colnames(term_mats) <- terms

  # loop over terms efficiently
  for (i in seq_len(n_t)) {
    # assign 0/1 indicators for this term
    for (t in seq_along(terms)) {
      input_data_copy[[terms[t]]] <- term_mats[i, t]
    }

    # single predict() call returning both fit and SE
    pred <- predict(mgcv_model, newdata = input_data_copy, se.fit = TRUE)
    b.j  <- pred$fit
    se.j <- pred$se.fit
    t.j  <- b.j / se.j

    # append results
    term_i <- terms[i]
    output_data[[paste0("b_", term_i)]]  <- b.j
    output_data[[paste0("se_", term_i)]] <- se.j
    output_data[[paste0("t_", term_i)]]  <- t.j
  }

  # optional predicted response (only if all terms present)
  if (all(terms %in% names(input_data))) {
    output_data$yhat <- predict(mgcv_model, newdata = input_data)
  }

  return(output_data)
}



