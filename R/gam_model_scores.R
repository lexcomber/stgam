#' Title Ranks models by GCV, giving the model form for each predctor variable.
#'
#' @param res_tab a `data.frame` returned from the `evaluate_models()` function.
#' @param n the number of ranked models to return.
#'
#' @returns a `tibble` of the 'n' best models, ranked by GCV, with the form of each predictor variable where '---' indicates the absence of a predictor, 'Fixed' that a parametric form was specified,  'te_S' a spatial Tensor Product (TP) smooth, 'te_T'  a temporal TP smooth and 'te_ST' a spatio-temporal TP smooth.
#' @importFrom dplyr relocate
#' @importFrom dplyr mutate
#' @importFrom dplyr rename
#' @importFrom dplyr arrange
#' @importFrom dplyr slice_head
#' @importFrom dplyr across
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
gam_model_scores <- function(res_tab, n = 10) {
  Rank = NULL
  GVC = NULL
  nm <- names(res_tab)
  len = length(nm)
  mod_comp <- rename(tibble(res_tab), GCV = gcv) |> arrange(GCV)
  int_terms <- function(x) c("Fixed", "te_S", "te_T", "te_T + te_S", "te_ST")[x]
  var_terms <- function(x) c("---", "Fixed", "te_S", "te_T", "te_T + te_S", "te_ST")[x]
  out_tab <-
    relocate(
      mutate(
        mutate(
          mutate(
            slice_head(mod_comp, n = n),
            across(nm[2]:nm[len - 2], var_terms)),
          across(nm[1]:nm[1], int_terms)),
        Rank = 1:n()),
      Rank)
  return(out_tab)
}
