#' Creates and evaluates multiple varying coefficient GAM GP smooth models (SVC or STVC)
#'
#' @param data a `data.frame` or `tibble` containing the target variables, covariates and coordinate variables
#' @param target_var the name of the target variable in `data`
#' @param covariates the name of the covariates (predictor variables) in `data`
#' @param coords_x the name of the X, Easting or Longitude variable in `data`
#' @param coords_y the name of the Y, Northing or Latitude variable in `data`
#' @param STVC a logical operator to indicate whether the models Space-Time (`TRUE`) or just Space (`FALSE`)
#' @param time_var the name of the time variable if undertaking STVC model evaluations
#' @param ncores the number of cores to use in parallelised approaches (default is 2 to overcome CRAN package checks). This can be determined for your computer by running `parallel::detectCores()-1`. Parallel approaches are only undertaken if the number of models to evaluate is greater than 30.
#'
#' @return A data table in `data.frame` format of all possible model combinations with each covariate specified in all possible ways, with the BIC of the model and the model formula.
#' @importFrom glue glue
#' @importFrom stats formula
#' @importFrom stats BIC
#' @importFrom parallel makeCluster
#' @importFrom parallel detectCores
#' @importFrom doParallel registerDoParallel
#' @importFrom foreach %dopar%
#' @importFrom foreach foreach
#' @importFrom parallel stopCluster
#'
#' @examples
#' library(dplyr)
#' library(glue)
#' library(purrr)
#' library(doParallel)
#' library(mgcv)
#' data("productivity")
#' data = productivity |> filter(year == "1970")
#' svc_res_gam =
#'   evaluate_models(data = data,
#'                   target_var = "privC",
#'                   covariates = c("unemp", "pubC"),
#'                   coords_x = "X",
#'                   coords_y = "Y",
#'                   STVC = FALSE)
#' head(svc_res_gam)
#' @export
evaluate_models = function(data,
                           target_var = "privC",
                           covariates = c("unemp", "pubC"),
                           coords_x = "X",
                           coords_y = "Y",
                           STVC = FALSE,
                           time_var = NULL,
                           ncores = 2) {
  # Helper functions
  # 1 intercept formula
  get_form_intercept = function(index, bs = "gp") {
    c("",
      glue("+s({coords_x},{coords_y},bs='{bs}',by=Intercept)"),
      glue("+s({time_var},bs='{bs}',by=Intercept)"),
      glue("+s({coords_x},{coords_y},bs='{bs}',by= Intercept) + s({time_var},bs='{bs}',by=Intercept)"),
      glue("+s({coords_x},{coords_y},{time_var},bs='{bs}',by=Intercept)"))[index]
  }
  # get_form_intercept(3)

  # 2 covariate formula
  get_form_covariate = function(varname, index, bs = "gp") {
    c("",
      glue("+ {varname}"),
      glue("+s({coords_x},{coords_y},bs='{bs}',by={varname})"),
      glue("+s({time_var},bs='{bs}',by={varname})"),
      glue("+s({coords_x},{coords_y},bs='{bs}',by={varname}) + s({time_var},bs='{bs}',by={varname})"),
      glue("+s({coords_x},{coords_y},{time_var},bs='{bs}',by={varname})"))[index]
  }
  # get_form_covariate("unemp", 6)

  # 3 make combinations grid for SVC and STVC
  make_svc_index_grid = function(covariates) {
    expression_x = "expand.grid(Intercept = 1:2 "
    for (i in covariates) {
      expression_x =
        paste0(expression_x, ",", i, "=1:3")
    }
    expression_x = paste0(expression_x,")")
    eval(parse(text = expression_x))
  }
  # make_svc_index_grid(letters[1:3])
  make_stvc_index_grid = function(covariates) {
    expression_x = "expand.grid(Intercept = 1:5 "
    for (i in covariates) {
      expression_x =
        paste0(expression_x, ",", i, "=1:6")
    }
    expression_x = paste0(expression_x,")")
    eval(parse(text = expression_x))
  }
  # make_stvc_index_grid(letters[1:3])

  # 4 create the formula
  get_formula = function(indices){
    form.i = glue("{target_var}~Intercept-1")
    form.i = paste0(form.i,
                    get_form_intercept(indices[1])
    )
    for (j in 1:length(covariates)){
      varname = covariates[j]
      form.i = paste0(form.i,
                      get_form_covariate(varname, indices[j+1])
      )

    }
    return(formula(form.i))
  }
  # svc_grid = make_svc_index_grid(covariates)
  # indices = unlist(svc_grid[11,])
  # get_formula(indices)

  # 5 create and evaluate a GAM
  evaluate_gam = function(i, terms_grid, data, ...){
    # make the formula
    indices = unlist(terms_grid[i,])
    f <- get_formula(indices)
    # do the GAM
    data <-data |> mutate(Intercept = 1)
    m = gam(f,data=data)
    bic = BIC(m)
    # create the indices and formula for output
    index = data.frame(terms_grid[i,])
    f = paste0(target_var, ' ~ ', as.character(f)[3] )
    return(data.frame(index, bic, f))
  }
  if(!STVC) {
    terms_grid = make_svc_index_grid(covariates)
  } else {
    terms_grid = make_stvc_index_grid(covariates)
  }
  if (nrow(terms_grid) < 30) {
    vc_res_gam <- NULL
    for(i in 1:nrow(terms_grid)) {
      res.i = evaluate_gam(i, terms_grid, data)
      vc_res_gam = rbind(vc_res_gam, res.i)
    }
  } else {
    # see https://stackoverflow.com/questions/50571325/r-cran-check-fail-when-using-parallel-functions
    #chk <- Sys.getenv("_R_CHECK_LIMIT_CORES_", "")
    #if (nzchar(chk) && chk == "TRUE") {
      # use 2 cores in CRAN/Travis/AppVeyor
    #  cl <- makeCluster(2L)
    #} else {
    #  # use all cores in devtools::test()
    #  cl <- makeCluster(detectCores()-1)
    #}
    cl = makeCluster(ncores)
    registerDoParallel(cl)
    vc_res_gam <-
      foreach(i = 1:nrow(terms_grid),
              .combine = 'rbind',
              .packages = c("glue", "mgcv", "purrr", "dplyr")) %dopar% {
                evaluate_gam(i, terms_grid,  data,
                             target_var, covariates, coords_x, coords_y, time_var)
              }
    stopCluster(cl)
  }
  vc_res_gam
}
