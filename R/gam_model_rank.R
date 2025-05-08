#' Ranks models by GCV, giving the model form for each predictor variable.
#'
#' @param res_tab a `data.frame` returned from the `evaluate_models()` function.
#' @param n the number of ranked models to return.
#'
#' @returns a `tibble` of the 'n' best models, ranked by GCV, with the form of each predictor variable where '---' indicates the absence of a predictor, 'Fixed' that a parametric form was specified,  's_S' a spatial smooth, 's_T'  a temporal smooth and 't2_ST' a spatio-temporal smooth.
#' @importFrom dplyr relocate
#' @importFrom dplyr mutate
#' @importFrom dplyr rename
#' @importFrom dplyr arrange
#' @importFrom dplyr slice_head
#' @importFrom dplyr across
#' @importFrom dplyr tibble
#'
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
#' gam_model_rank(svc_mods)
gam_model_rank <- function(res_tab, n = 10) {
  Rank <- NULL
  GCV <- NULL
  gcv <- NULL
  nm <- names(res_tab)
  len <- length(nm)
  res_tab <- res_tab |> rename(GCV = gcv) |> arrange(GCV)
  int_terms <- function(x) c("Fixed", "s_S", "s_T", "s_T + s_S", "t2_ST")[x]
  var_terms <- function(x) c("---", "Fixed", "s_S", "s_T", "s_T + s_S", "t2_ST")[x]
  out_tab <-
    mutate(
      mutate(
        slice_head(res_tab, n = n),
        across(nm[2]:nm[len - 2], var_terms)),
      across(nm[1]:nm[1], int_terms)) |>
    mutate(Rank = 1:n()) |>
    dplyr::relocate(Rank)
  return(out_tab)
}
