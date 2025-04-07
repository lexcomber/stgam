#' Title Evaluates multiple models with each predictor variable specified in different ways in order to determining model form
#'
#' @param input_data he data to be used used to create the GAM model in (`data.frame` or `tibble` format), containing an Intercept column to allow it be treated as an addressable term in the model.
#' @param target_var the name of the target variable.
#' @param vars a vector of the predictor variable names (without the Intercept).
#' @param coords_x the name of the X, Easting or Longitude variable in `input_data`.
#' @param coords_y the name of the Y, Northing or Latitude variable in `input_data`.
#' @param STVC a logical operator indicating whether the model is space-time (`TRUE`) or just space (`FALSE`) which is the default.
#' @param time_var the name of the time variable if undertaking STVC model evaluations.
#' @param rho_space_vec a vector of *spatial* length scales from the `opt_length_scale` function.
#' @param rho_time_vec a vector of *temporal* length scales from the `opt_length_scale` function.
#' @param ncores the number of cores to use in parallelised approaches (default is 2 to overcome CRAN package checks). This can be determined for your computer by running parallel::detectCores()-1. Parallel approaches are only undertaken if the number of models to evaluate is greater than 30.
#'
#' @returns a `data.frame` with indices for each predictor variable, a GCV score (`gcv`) for each model and the associated formula (`f`).
#' @importFrom glue glue
#' @importFrom dplyr mutate
#' @importFrom mgcv gam
#' @importFrom mgcv te
#' @importFrom parallel makeCluster
#' @importFrom doParallel registerDoParallel
#' @importFrom foreach foreach
#' @importFrom parallel stopCluster
#' @export
#'
#' @examples
#' require(dplyr)
#' # define input data
#' input_data = productivity |> filter(year == 1975) |> mutate(Intercept = 1)
#' # detemine length ranges
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
#' # have a look
#' head(svc_mods)
evaluate_models <- function(
    input_data = input_data,
    target_var = "privC",
    vars = c("unemp", "pubC"),
    coords_x = "X",
    coords_y = "Y",
    STVC = FALSE,
    time_var = NULL,
    rho_space_vec = NULL,
    rho_time_vec = NULL,
    ncores = 2)
{
  # function to get model intercept terms
  get_form_intercept = function(index,rho_space = NULL, rho_time = NULL, bs = 'gp') {
    c("",
      glue("+te({coords_x},{coords_y},d=2,m=list(c(3,{rho_space})),bs='{bs}',by=Intercept)"),
      glue("+te({time_var},d=1,m=list(c(3,{rho_time})),bs='{bs}',by=Intercept)"),
      glue("+te({coords_x},{coords_y},d=2,m=list(c(3,{rho_space})),bs='{bs}',by=Intercept) + te({time_var},d=1,m=list(c(3,{rho_time})),bs='{bs}',by=Intercept)"),
      glue("+te({coords_x},{coords_y},{time_var},d=c(2,1),m=list(c(3,{rho_space}),c(3,{rho_time})),bs='{bs}',by=Intercept)"))[index]
  }

  # function to get model predictor terms
  get_form_covariate = function(varname, index, rho_space = NULL, rho_time = NULL, bs = "gp") {
    c("",
      glue("+ {varname}"),
      glue("+te({coords_x},{coords_y},d=2,m=list(c(3,{rho_space})),bs='{bs}',by={varname})"),
      glue("+te({time_var},d=1,m=list(c(3,{rho_time})),bs='{bs}',by={varname})"),
      glue("+te({coords_x},{coords_y},d=2,m=list(c(3,{rho_space})),bs='{bs}',by={varname}) + te({time_var},d=1,m=list(c(3,{rho_time})),bs='{bs}',by={varname})"),
      glue("+te({coords_x},{coords_y},{time_var},d=c(2,1),m=list(c(3,{rho_space}),c(3,{rho_time})),bs='{bs}',by={varname})"))[index]
  }

  # function to make SVC index grid
  make_svc_index_grid = function(vars) {
    expression_x = "expand.grid(Intercept = 1:2"
    for (i in vars) {
      expression_x = paste0(expression_x, ",", i, " = 1:3")
    }
    expression_x = paste0(expression_x, ")")
    eval(parse(text = expression_x))
  }

  # function to make STVC index grid
  make_stvc_index_grid = function(vars) {
    expression_x = "expand.grid(Intercept = 1:5"
    for (i in vars) {
      expression_x = paste0(expression_x, ",", i, " = 1:6")
    }
    expression_x = paste0(expression_x, ")")
    eval(parse(text = expression_x))
  }

  # function to make GAM model formula
  get_formula = function(indices, rho_space_vec, rho_time_vec) {
    form.i = glue("{target_var}~Intercept-1")
    form.i = paste0(form.i, get_form_intercept(indices[1],rho_space_vec[1], rho_time_vec[1]))
    for (j in 1:length(vars)) {
      varname = vars[j]
      form.i = paste0(form.i, get_form_covariate(varname, indices[j+1], rho_space_vec[j+1], rho_time_vec[j+1]))
    }
    return(formula(form.i))
  }

  # function to generate GAM TP smooth model formula
  evaluate_gam = function(i, terms_grid, input_data, rho_space_vec, rho_time_vec = NULL, ...) {
    indices = unlist(terms_grid[i, ])
    f <- get_formula(indices, rho_space_vec, rho_time_vec)
    input_data <- mutate(input_data, Intercept = 1)
    m = gam(f, data = input_data, method = "GCV.Cp")
    gcv = m$gcv.ubre
    index = data.frame(terms_grid[i, ])
    #f <- get_formula(indices, round(rho_space_vec,3), round(rho_time_vec, 3))
    f = paste0(target_var, " ~ ", as.character(f)[3])
    return(data.frame(index, gcv,f))
  }

  # 1. make the terms grid
  if (!STVC) {
    terms_grid = make_svc_index_grid(vars)
  } else {
    terms_grid = make_stvc_index_grid(vars)
  }

  # 2. evaluate each model
  # a) in a for loop if n <= 30
  if(STVC) {
    if (nrow(terms_grid) <= 30) {
      vc_res_gam <- NULL
      for (i in 1:nrow(terms_grid)) {
        res.i = evaluate_gam(i, terms_grid, input_data, rho_space_vec, rho_time_vec)
        vc_res_gam = rbind(vc_res_gam, res.i)
      }
    } else {
      # b) in parallel if n > 30
      #t1 = Sys.time()
      cl = makeCluster(ncores)
      registerDoParallel(cl)
      vc_res_gam <- foreach(i = 1:nrow(terms_grid), .combine = "rbind",
                            .packages = c("glue", "mgcv", "purrr", "dplyr")) %dopar%
        {evaluate_gam(i, terms_grid, input_data, rho_space_vec, rho_time_vec,
                      target_var, vars, coords_x, coords_y, time_var)
        }
      stopCluster(cl)
      # Sys.time() - t1 # 15 minutes
    }
  } else {
    if (nrow(terms_grid) <= 30) {
      vc_res_gam <- NULL
      for (i in 1:nrow(terms_grid)) {
        res.i = evaluate_gam(i, terms_grid, input_data, rho_space_vec)
        vc_res_gam = rbind(vc_res_gam, res.i)
      }
    } else {
      # b) in parallel if n > 30
      #t1 = Sys.time()
      cl = makeCluster(ncores)
      registerDoParallel(cl)
      vc_res_gam <- foreach(i = 1:nrow(terms_grid), .combine = "rbind",
                            .packages = c("glue", "mgcv", "purrr", "dplyr")) %dopar%
        {evaluate_gam(i, terms_grid, input_data, rho_space_vec,
                      target_var, vars, coords_x, coords_y)
        }
      stopCluster(cl)
      # Sys.time() - t1 # 15 minutes
    }
  }
  return(vc_res_gam)
}
