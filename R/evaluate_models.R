#' Evaluates multiple models with each predictor variable specified in different ways in order to determining model form
#'
#' @param input_data he data to be used used to create the GAM model in (`data.frame` or `tibble` format), containing an Intercept column to allow it be treated as an addressable term in the model.
#' @param target_var the name of the target variable.
#' @param vars a vector of the predictor variable names (without the Intercept).
#' @param model_family the mdoel family, defaults to Guassian
#' @param coords_x the name of the X, Easting or Longitude variable in `input_data`.
#' @param coords_y the name of the Y, Northing or Latitude variable in `input_data`.
#' @param VC_type the type of varying coefficient model: options are "TVC" for temporally varying, "SVC" for spatially varying  and "STVC" for space-time.
#' @param time_var the name of the time variable if undertaking STVC model evaluations.
#' @param k_set a logical value for user defined `k` values. The default is `FALSE`. Cannot be used with `k_increase`.
#' @param spatial_k the value of `k` for spatial smooths if `k_set` is `TRUE`.
#' @param temporal_k the value of `k` for temporal smooths if `k_set` is `TRUE`.
#' @param k_increase a logical value of whether to check and increase the number of knots in each smooth. The default is `FALSE`.
#' @param k2edf_ratio a threshold of the ratio of the number of knots, `k`, in each smooth to its Effective Degrees of Freedom. If any smooth has a *knots-to-EDF* ratio less than this value then the knots are iteratively increased by the `k_multiplier` value until the threshold check is passed, the number knots passes the maximum degrees of freedom, or the number of iterations, `max_iter` is reached. Cannot be used with `k_set`.
#' @param k_multiplier a multiplier by which the knots are increased on each iteration. The default is 2.
#' @param max_iter the maximum number of iterations that `k` is increased.
#' @param ncores the number of cores to use in parallelised approaches (default is 2 to overcome CRAN package checks). This can be determined for your computer by running parallel::detectCores()-1. Parallel approaches are only undertaken if the number of models to evaluate is greater than 30.
#'
#' @returns a `data.frame` with indices for each predictor variable, the knots specified in each smooth (`ks`), a AIC score (`aic`) for each model and the associated formula (`f`). The output should be passed to the `gam_model_rank` function.
#' @importFrom glue glue
#' @importFrom dplyr mutate
#' @importFrom mgcv gam
#' @importFrom mgcv te
#' @importFrom mgcv s
#' @importFrom mgcv k.check
#' @importFrom parallel makeCluster
#' @importFrom doParallel registerDoParallel
#' @importFrom foreach foreach
#' @importFrom foreach "%dopar%"
#' @importFrom parallel stopCluster
#' @importFrom stats formula
#' @importFrom stats as.formula
#' @importFrom stats family
#' @importFrom utils installed.packages
#' @importFrom stats sd
#'
#' @examples
#' \dontrun{
#' require(dplyr)
#' require(doParallel)
#' require(sf)
#'
#' # define input data
#' data("chaco")
#' input_data <-
#'   chaco |>
#'   # create Intercept as an addressable term
#'   mutate(Intercept = 1) |>
#'   # remove the geometry
#'   st_drop_geometry()
#'
#' # evaluate different model forms
#' # example 1 with 6 models and no `k` adjustment
#' svc_mods <-
#'   evaluate_models(
#'     input_data = input_data,
#'     target_var = "ndvi",
#'     model_family = "gaussian()",
#'     vars = c("tmax"),
#'     coords_x = "X",
#'     coords_y = "Y",
#'     VC_type = "SVC"
#'   )
#' # have a look!
#' svc_mods
#'
#' # example 2 with 6 models and `k` adjustment
#' svc_k1_mods <-
#'   evaluate_models(
#'     input_data = input_data,
#'     target_var = "ndvi",
#'     vars = c("tmax"),
#'     model_family = "gaussian()",
#'     coords_x = "X",
#'     coords_y = "Y",
#'     VC_type = "SVC",
#'     k_increase = TRUE,
#'     k2edf_ratio = 1.5,
#'     k_multiplier = 2,
#'     max_iter = 10
#'   )
#' # have a look!
#' svc_k1_mods
#'
#' # example 3 with 6 models and `k` set by user
#' svc_k2_mods <-
#'   evaluate_models(
#'     input_data = input_data,
#'     model_family = "gaussian()",
#'     target_var = "ndvi",
#'     vars = c("tmax"),
#'     coords_x = "X",
#'     coords_y = "Y",
#'     VC_type = "SVC",
#'     time_var = NULL,
#'     k_set = TRUE,
#'     spatial_k = 20,
#'   )
#' # have a look!
#' svc_k2_mods
#'}
#'
#' @export
evaluate_models <- function(input_data,
                            target_var,
                            model_family = "gaussian()",
                            vars,
                            coords_x = "X",
                            coords_y = "Y",
                            VC_type = "SVC",
                            time_var = NULL,
                            k_set = FALSE,
                            spatial_k = 50,
                            temporal_k = 10,
                            k_increase = FALSE,
                            k2edf_ratio = 1.5,
                            k_multiplier = 2,
                            max_iter = 10,
                            ncores = 2)
{
  ## ---------------------------------------------------------
  ## 1. BASIC INPUT CHECKS
  ## ---------------------------------------------------------

  if (!is.data.frame(input_data)) {
    stop("input_data must be a data.frame or tibble")
  }

  if(k_set & k_increase){
    stop("You cannot set both k_set and k_increase to be TRUE")
  }

  if( (VC_type == "TVC" | VC_type == "STVC") & is.null(time_var)){
    stop("You need to speciy a time_var for SVC or STVC")
  }

  required_packages <- c("mgcv", "glue", "dplyr")
  missing_pkgs <- required_packages[!required_packages %in% installed.packages()[,"Package"]]
  if (length(missing_pkgs) > 0) {
    stop("Missing required packages: ", paste(missing_pkgs, collapse = ", "))
  }

  if (!target_var %in% names(input_data)) {
    stop("target_var is not a column in input_data.")
  }
  if (!is.numeric(input_data[[target_var]])) {
    stop("target_var must be numeric (GAM requires numeric response).")
  }

  # Check covariates
  missing_vars <- vars[!vars %in% names(input_data)]
  if (length(missing_vars) > 0) {
    stop("These vars are missing from input_data: ", paste(missing_vars, collapse = ", "))
  }
  non_numeric_vars <- vars[!sapply(input_data[vars], is.numeric)]
  if (length(non_numeric_vars) > 0) {
    stop("These vars must be numeric: ", paste(non_numeric_vars, collapse = ", "))
  }

  # # Coordinates
  # if (!coords_x %in% names(input_data) || !coords_y %in% names(input_data)) {
  #     stop("coords_x and coords_y must be columns in input_data.")
  # }

  # VC_type
  if (!VC_type %in% c("SVC", "TVC", "STVC")) {
    stop("VC_type must be one of: 'SVC', 'TVC', 'STVC'.")
  }

  # time_var requirement
  if (VC_type %in% c("TVC", "STVC")) {
    if (is.null(time_var))
      stop("time_var must be provided for TVC or STVC models.")
    if (!time_var %in% names(input_data))
      stop("time_var is not a column in input_data.")
  }

  # Number of cores
  if (ncores < 1)
    stop("ncores must be >= 1.")

  ## ---------------------------------------------------------
  ## 2. INTERNAL FUNCTIONS to increase k
  ## ---------------------------------------------------------

  ## 2.1 Increase k
  increase_k <- function(m, k2edf_ratio, k_multiplier) {
    if (!inherits(m, "gam"))
      stop("m must be a mgcv GAM model")
    # --- 1. Get k.check table ---
    tab <- k.check(m)
    r   <- tab[, 1] / tab[, 2]
    k_increase <- which(r < k2edf_ratio)
    old_k_vals <- tab[, 1]
    # Nothing to change
    if (length(k_increase) == 0)
      return(m$formula)
    # --- 2. Extract smooth terms from formula string ---
    form_str <- paste(deparse(m$formula), collapse = " ")
    smooth_terms <- regmatches(
      form_str,
      gregexpr("s\\([^\\)]+\\)|te\\([^\\)]+\\)|ti\\([^\\)]+\\)",
               form_str)
    )[[1]]
    # --- helper: update or insert k ---
    update_k_in_smooth <- function(s_term, new_k) {
      # CASE 1: Smooth already has a k= argument
      if (grepl("k\\s*=", s_term)) {
        # replace the existing k= value
        s_new <- sub(
          "k\\s*=\\s*[^,\\)]+",
          paste0("k=", new_k),
          s_term
        )
        return(s_new)
      }
      # CASE 2: Smooth does NOT contain k — insert before closing bracket
      s_new <- sub(
        "\\)$",
        paste0(", k=", new_k, ")"),
        s_term
      )
      return(s_new)
    }
    # --- 3. Loop over smooths where k must increase ---
    form_new <- form_str
    for (i in k_increase) {
      current_smooth <- smooth_terms[i]
      old_k <- old_k_vals[i]
      new_k <- old_k * k_multiplier
      updated_smooth <- update_k_in_smooth(current_smooth, new_k)
      # replace in formula string
      form_new <- sub(
        fixed = TRUE,
        pattern = current_smooth,
        replacement = updated_smooth,
        x = form_new
      )
    }
    return(form_new)
  }
  ## 2.2 Iteratively increase k
  iterate_increase_k <- function(m, k2edf_ratio, k_multiplier, max_iter, model_family) {
    old_m <- m
    iteration <- 1
    repeat {
      # 1. Run k.check()
      tab <- k.check(m)
      r <- tab[, 1] / tab[, 2]
      k_increase <- which(r < k2edf_ratio)
      # 2. Stop if nothing to change
      if (length(k_increase) == 0) {
        break
      }
      # 3. Safety stop
      if (iteration >= max_iter) {
        break
      }
      # 4. Build updated formula
      new_formula_str <- increase_k(
        m,
        k2edf_ratio = k2edf_ratio,
        k_multiplier = k_multiplier
      )
      new_formula <- as.formula(new_formula_str)
      # 5. Refit model
      old_m <- m
      m <- try(gam(new_formula, data = m$model, method = m$method, family = model_family),
               silent = TRUE)
      # check for running out of degrees of freedom
      if (inherits(m, "try-error")) {
        return (old_m)
      }
      # cat(iteration, "\t")
    }
    return(m)
  }

  ## ---------------------------------------------------------
  ## 3. INTERNAL FUNCTIONS to construct models
  ## ---------------------------------------------------------

  get_form_intercept <- function(index, k_set = FALSE) {
    if(!k_set) {
      c("",
        glue("+s({coords_x},{coords_y},by=Intercept)"),
        glue("+s({time_var},by=Intercept)"),
        glue("+s({coords_x},{coords_y},by=Intercept) + s({time_var},by=Intercept)"),
        glue("+te({coords_x},{coords_y},{time_var},d=c(2,1),bs=c('tp','cr'),by=Intercept)")
      )[index]
    } else {
      c("",
        glue("+s({coords_x},{coords_y},k={spatial_k},by=Intercept)"),
        glue("+s({time_var},k={temporal_k},by=Intercept)"),
        glue("+s({coords_x},{coords_y},k={spatial_k},by=Intercept) + s({time_var},k={temporal_k},by=Intercept)"),
        glue("+te({coords_x},{coords_y},{time_var},d=c(2,1),bs=c('tp','cr'),k=c({spatial_k},{temporal_k}),by=Intercept)")
      )[index]
    }

  }

  get_form_covariate <- function(varname, index, k_set = FALSE) {
    if(!k_set) {
      c("",
        glue("+{varname}"),
        glue("+{varname}+s({coords_x},{coords_y},by={varname})"),
        glue("+{varname}+s({time_var},by={varname})"),
        glue("+{varname}+s({coords_x},{coords_y},by={varname}) + s({time_var},by={varname})"),
        glue("+{varname}+te({coords_x},{coords_y},{time_var},d=c(2,1),bs=c('tp','cr'),by={varname})")
      )[index]
    } else  {
      c("",
        glue("+{varname}"),
        glue("+{varname}+s({coords_x},{coords_y},k={spatial_k},by={varname})"),
        glue("+{varname}+s({time_var},k={temporal_k},by={varname})"),
        glue("+{varname}+s({coords_x},{coords_y},k={spatial_k},by={varname}) + s({time_var},k={temporal_k},by={varname})"),
        glue("+{varname}+te({coords_x},{coords_y},{time_var},d=c(2,1),bs=c('tp','cr'),k=c({spatial_k},{temporal_k}),by={varname})")
      )[index]
    }
  }

  make_tvc_index_grid <- function(vars) {
    expression_x <- "expand.grid(Intercept = c(1, 3)"
    for (i in vars) expression_x <- paste0(expression_x, ",", i, " = c(1,2,4)")
    eval(parse(text = paste0(expression_x, ")")))
  }

  make_svc_index_grid <- function(vars) {
    expression_x <- "expand.grid(Intercept = 1:2"
    for (i in vars) expression_x <- paste0(expression_x, ",", i, " = 1:3")
    eval(parse(text = paste0(expression_x, ")")))
  }

  make_stvc_index_grid <- function(vars) {
    expression_x <- "expand.grid(Intercept = 1:5"
    for (i in vars) expression_x <- paste0(expression_x, ",", i, " = 1:6")
    eval(parse(text = paste0(expression_x, ")")))
  }

  get_formula <- function(indices, k_set) {
    form.i <- glue("{target_var} ~ Intercept - 1")
    form.i <- paste0(form.i, get_form_intercept(indices[1], k_set))
    for (j in seq_along(vars)) {
      varname <- vars[j]
      form.i <- paste0(form.i, get_form_covariate(varname, indices[j + 1], k_set))
    }
    formula(form.i)
  }

  evaluate_gam <- function(i, terms_grid, input_data, k_set, k_increase, ...) {
    indices <- unlist(terms_grid[i, ])
    f <- get_formula(indices, k_set)
    input_data <- dplyr::mutate(input_data, Intercept = 1)
    m <- mgcv::gam(f, data = input_data, method = "REML", family = model_family)
    if(k_increase) {
      m <- iterate_increase_k(m, k2edf_ratio = k2edf_ratio,
                              k_multiplier = k_multiplier,
                              max_iter = max_iter,
                              model_family = model_family)
    }
    ks <- k.check(m)[,1] |> as.vector()
    ks <- gsub(", ", ", ", toString(ks))
    aic <- m$aic
    index <- data.frame(terms_grid[i, ])
    f <- paste0(target_var, " ~ ",  as.character(m$formula)[3])
    data.frame(index, ks, aic, f)
  }

  ## ---------------------------------------------------------
  ## 4. CONSTRUCT TERM GRID
  ## ---------------------------------------------------------
  terms_grid <- switch(
    VC_type,
    "SVC"  = make_svc_index_grid(vars),
    "TVC"  = make_tvc_index_grid(vars),
    "STVC" = make_stvc_index_grid(vars)
  )

  ## ---------------------------------------------------------
  ## 5. RUN GAM MODELS (SEQUENTIAL OR PARALLEL)
  ## ---------------------------------------------------------
  if (nrow(terms_grid) < 30) {
    vc_res_gam <- NULL
    for (i in 1:nrow(terms_grid)) {
      vc_res_gam <- rbind(vc_res_gam, evaluate_gam(i, terms_grid, input_data, k_set, k_increase))
    }
  } else {
    cl <- parallel::makeCluster(ncores)
    doParallel::registerDoParallel(cl)

    vc_res_gam <- foreach::foreach(
      i = 1:nrow(terms_grid),
      .combine = "rbind",
      .packages = c("glue", "mgcv", "purrr", "dplyr")
    ) %dopar% {
      evaluate_gam(i, terms_grid, input_data, k_set, k_increase, target_var,
                   vars, coords_x, coords_y, time_var, spatial_k, temporal_k)
    }

    parallel::stopCluster(cl)
  }

  return(vc_res_gam)
}

