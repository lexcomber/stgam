#' Evaluates multiple models with each predictor variable specified in different ways in order to determining model form
#'
#' @param input_data he data to be used used to create the GAM model in (`data.frame` or `tibble` format), containing an Intercept column to allow it be treated as an addressable term in the model.
#' @param target_var the name of the target variable.
#' @param vars a vector of the predictor variable names (without the Intercept).
#' @param coords_x the name of the X, Easting or Longitude variable in `input_data`.
#' @param coords_y the name of the Y, Northing or Latitude variable in `input_data`.
#' @param VC_type the type of varying coefficient model: options are "TVC" for temporally varying, "SVC" for spatially varying  and "STVC" for space-time .
#' @param time_var the name of the time variable if undertaking STVC model evaluations.
#' @param ncores the number of cores to use in parallelised approaches (default is 2 to overcome CRAN package checks). This can be determined for your computer by running parallel::detectCores()-1. Parallel approaches are only undertaken if the number of models to evaluate is greater than 30.
#'
#' @returns a `data.frame` with indices for each predictor variable, a GCV score (`gcv`) for each model and the associated formula (`f`), which  should be passed to the `gam_model_rank` function.
#' @importFrom glue glue
#' @importFrom dplyr mutate
#' @importFrom mgcv gam
#' @importFrom mgcv te
#' @importFrom parallel makeCluster
#' @importFrom doParallel registerDoParallel
#' @importFrom foreach foreach
#' @importFrom foreach "%dopar%"
#' @importFrom parallel stopCluster
#' @importFrom stats formula
#' @export
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
#'     vars = c("pef"),
#'     coords_x = "X",
#'     coords_y = "Y",
#'     VC_type = "SVC",
#'     time_var = NULL,
#'     ncores = 2
#'   )
#' head(svc_mods)
evaluate_models <- function(
    input_data,
    target_var,
    vars,
    coords_x,
    coords_y,
    VC_type = "SVC",
    time_var = NULL,
    ncores = 2)
{
  # function to get model intercept terms
  get_form_intercept <- function(index) {
    c("",
      glue("+s({coords_x},{coords_y},by=Intercept)"),
      glue("+s({time_var},by=Intercept)"),
      glue("+s({coords_x},{coords_y},by=Intercept) + s({time_var},by=Intercept)"),
      glue("+t2({coords_x},{coords_y},{time_var},d=c(2,1),by=Intercept)"))[index]
  }

  # function to get model predictor terms
  get_form_covariate <- function(varname, index) {
    c("",
      glue("+ {varname}"),
      glue("+s({coords_x},{coords_y},by={varname})"),
      glue("+s({time_var},by={varname})"),
      glue("+s({coords_x},{coords_y},by={varname}) + s({time_var},by={varname})"),
      glue("+t2({coords_x},{coords_y},{time_var},d=c(2,1),by={varname})"))[index]
  }

  # function to make TVC index grid
  make_tvc_index_grid <- function(vars) {
    expression_x <- "expand.grid(Intercept = 1:2"
    for (i in vars) {
      expression_x <- paste0(expression_x, ",", i, " = c(1,2,4)")
    }
    expression_x <- paste0(expression_x, ")")
    eval(parse(text = expression_x))
  }

  # function to make SVC index grid
  make_svc_index_grid <- function(vars) {
    expression_x <- "expand.grid(Intercept = 1:2"
    for (i in vars) {
      expression_x <- paste0(expression_x, ",", i, " = 1:3")
    }
    expression_x <- paste0(expression_x, ")")
    eval(parse(text = expression_x))
  }

  # function to make STVC index grid
  make_stvc_index_grid <- function(vars) {
    expression_x <- "expand.grid(Intercept = 1:5"
    for (i in vars) {
      expression_x <- paste0(expression_x, ",", i, " = 1:6")
    }
    expression_x <- paste0(expression_x, ")")
    eval(parse(text = expression_x))
  }

  # function to make GAM model formula
  get_formula <- function(indices) {
    form.i <- glue("{target_var}~Intercept-1")
    form.i <- paste0(form.i, get_form_intercept(indices[1]))
    for (j in 1:length(vars)) {
      varname <- vars[j]
      form.i <- paste0(form.i, get_form_covariate(varname, indices[j+1]))
    }
    return(formula(form.i))
  }

  # function to generate GAM TP smooth model formula
  evaluate_gam <- function(i, terms_grid, input_data, ...) {
    indices <- unlist(terms_grid[i, ])
    f <- get_formula(indices)
    input_data <- mutate(input_data, Intercept = 1)
    m <- gam(f, data = input_data, method = "REML")
    gcv <- m$gcv.ubre
    index <- data.frame(terms_grid[i, ])
    f <- paste0(target_var, " ~ ", as.character(f)[3])
    return(data.frame(index, gcv,f))
  }

  # 1. make the terms grid
  if (VC_type == "SVC") {
    terms_grid <- make_svc_index_grid(vars)
  }
  if (VC_type == "TVC") {
    terms_grid <- make_tvc_index_grid(vars)
  }
  if (VC_type == "STVC") {
    terms_grid <- make_stvc_index_grid(vars)
  }

  # 2. evaluate each model
  if (nrow(terms_grid) < 30) {
    vc_res_gam <- NULL
    for(i in 1:nrow(terms_grid)) {
      res.i = evaluate_gam(i, terms_grid, input_data)
      vc_res_gam = rbind(vc_res_gam, res.i)
    }
  } else {
    cl = makeCluster(ncores)
    registerDoParallel(cl)
    vc_res_gam <-
      foreach(i = 1:nrow(terms_grid),
              .combine = 'rbind',
              .packages = c("glue", "mgcv", "purrr", "dplyr")) %dopar% {
                evaluate_gam(i, terms_grid,  input_data,
                             target_var, vars, coords_x, coords_y, time_var)
              }
    stopCluster(cl)
  }
  return(vc_res_gam)
}
