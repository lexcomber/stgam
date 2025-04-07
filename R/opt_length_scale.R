#' Title Optimises the length scale parameters for Tensor Product smooths
#'
#' @param input_data the data to be used used to create the GAM model in (`data.frame` or `tibble` format), containing an Intercept column to allow it be treated as an addressable term in the model.
#' @param target_var the name of the target variable.
#' @param vars a vector of "Intercept" and the predictor variable names.
#' @param coords_x the name of the X, Easting or Longitude variable in `input_data`.
#' @param coords_y the name of the Y, Northing or Latitude variable in `input_data`.
#' @param STVC a logical operator indicating whether the model is space-time (`TRUE`) or just space (`FALSE`).
#' @param time_var the name of the time variable if undertaking STVC model evaluations
#' @param ... other prameters to be passed to `mgcv` `gam()` function.
#'
#' @returns A `data.frame` containing the spatial and temporal length scales \eqn{\rho_{space}} and \eqn{\rho_{time}}) for use in the Tensor Product smooths.
#' @importFrom glue glue
#' @importFrom mgcv gam
#' @importFrom mgcv te
#' @importFrom dplyr all_of
#' @importFrom dplyr select
#' @importFrom stats optimise
#' @importFrom stats dist
#' @importFrom ggplot2 xlab
#' @importFrom ggplot2 ylab
#' @importFrom ggplot2 ylim
#' @importFrom cowplot plot_grid
#' @export
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
#' # have a look!
#' rho_sp

opt_length_scale = function(input_data,
                            target_var = "privC",
                            vars = c("Intercept", "unemp", "pubC"),
                            coords_x = "X",
                            coords_y = "Y",
                            STVC = FALSE,
                            time_var = NULL,...
) {
  # functions
  get_XY_gcv = function(x, var) {
    f =  glue("{target_var} ~ te({coords_x},{coords_y},d=2,bs ='gp',m=list(c(3,{x})),by={var})")
    f = as.formula(f)
    gam.i = gam(f, data = input_data, method = "GCV.Cp")
    return(as.vector(gam.i$gcv.ubre))
  }
  get_time_gcv = function(x, var) {
    f =  glue("{target_var} ~ te({time_var},d=1,bs ='gp',m=list(c(3,{x})),by={var})")
    f = as.formula(f)
    gam.i = gam(f, data = input_data, method = "GCV.Cp")
    return(as.vector(gam.i$gcv.ubre))
  }
  # space: max distance
  d_max <-
    input_data |>
    select(all_of(coords_x), all_of(coords_y)) |>
    dist() |> as.vector() |> ceiling() |> max()
  # apply the get_XY_gcv function
  rho_sp = NULL
  for (i in vars) {
    rho_sp.i = optimise(get_XY_gcv, c(0,d_max), var = i, maximum=FALSE)$minimum
    rho_sp = c(rho_sp, rho_sp.i)
  }
  if(STVC) {
    # time max
    t_max <-
      input_data |>
      select(all_of(time_var)) |>
      as.vector() |> range() |> diff()
    # apply the get_time_gcv function
    rho_time = NULL
    for (i in vars) {
      rho_time.i = optimise(get_time_gcv, c(0,t_max), var = i, maximum=FALSE)$minimum
      rho_time = c(rho_time, rho_time.i)
    }
    out_tab = data.frame(Vars = vars, rho_space = rho_sp, rho_time = rho_time)

  } else {
    out_tab = data.frame(Vars = vars, rho_space = rho_sp)
  }
  return(out_tab)
}
