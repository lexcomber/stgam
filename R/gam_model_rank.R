#' Ranks models by AIC, giving the model form for each predictor variable.
#'
#' @param res_tab a `data.frame` returned from the `evaluate_models()` function.
#' @param n the number of ranked models to return.
#'
#' @returns a `tibble` of the 'n' best models, ranked by AIC, with the form of each predictor variable where '---' indicates the absence of a predictor, 'Fixed' that a parametric form was specified,  's(S)' a spatial smooth, 's(T)'  a temporal smooth and 'te(ST)' a combined space-time smooth. Model AIC is reported as are the knots in each smooth (`ks`) and the formula of each model (`f`).
#' @importFrom dplyr relocate
#' @importFrom dplyr mutate
#' @importFrom dplyr rename
#' @importFrom dplyr arrange
#' @importFrom dplyr slice_head
#' @importFrom dplyr across
#' @importFrom dplyr tibble
#' @importFrom stringr str_split
#' @importFrom stringr str_replace
#' @importFrom stringr str_detect
#' @importFrom purrr map2_chr
#' @importFrom magrittr %>%
#' @importFrom utils head
#' @importFrom mgcv k.check
#' @importFrom stats as.formula
#'
#' @examples
#' require(dplyr)
#' require(stringr)
#' require(purrr)
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
#'     vars = c("tmax"),
#'     coords_x = "X",
#'     coords_y = "Y",
#'     VC_type = "SVC"
#'   )
#' # rank the models
#' gam_model_rank(svc_mods)
#' @export
gam_model_rank <- function(res_tab, n = 10) {
  ks_col <- which(names(res_tab) == "ks")
  smooth_cols <- 1:(ks_col-1)
  nm <- names(res_tab)
  len <- length(nm)
  Rank <- NULL
  AIC <- NULL
  aic <- NULL
  res_tab <-
    res_tab |>
    rename(AIC = aic) |>
    arrange(AIC)

  int_terms <- function(x) c("Fixed", "s(S)", "s(T)", "s(S) + s(T)", "te(ST)")[x]
  var_terms <- function(x) c("---", "Fixed", "s(S)", "s(T)", "s(S) + s(T)", "te(ST)")[x]

  out_tab <-
    res_tab |>
    slice_head(n=n) |>
    #slice(30:40) |>
    mutate(across(nm[2]:nm[len - 3], var_terms)) |>
    mutate(across(nm[1]:nm[1], int_terms))

  # helper: attach a vector of ks to a vector of smooths
  attach_k <- function(smooths, ks) {
    map2_chr(smooths, ks, \(sm, k) {
      str_replace(sm, "\\)$", paste0(", k=", k, ")"))
    })
  }
  # helper: split smooths inside a cell
  split_smooths <- function(x) {
    x %>% str_split("\\s*\\+\\s*") %>% unlist()
  }
  # helper: detect if a cell contains one or more smooth expressions
  contains_smooth <- function(x) {
    str_detect(x, "\\b(s|te|ti)\\s*\\(")
  }

  for(i in 1:nrow(out_tab)) {
    row.i <- out_tab[i,]
    # create vector of k's allowing for non-smooth elements
    smooth_lists <- lapply(row.i[smooth_cols], split_smooths) |> unlist()
    smooth_counts <- sapply(smooth_lists, function(x) contains_smooth(x) + 0 |> unlist())
    ks_s <- str_split(row.i[ks_col], ",\\s*")[[1]] %>% as.numeric()
    ks_vec <- rep("", length(smooth_counts))
    ks_vec[which(smooth_counts > 0)] <- ks_s

    # how many smooths in each selected column?
    smooth_lists <- lapply(row.i[smooth_cols], split_smooths)
    smooth_counts <- lengths(smooth_lists)
    # cumulative positions to slice ks_vec
    k_starts <- cumsum(c(1, head(smooth_counts, -1)))
    k_ends   <- cumsum(smooth_counts)
    # assign new smooths back into their columns
    for (j in seq_along(smooth_cols)) {
      col_index <- smooth_cols[j]
      cell_value = smooth_lists[[j]]
      ks_slice  <- ks_vec[k_starts[j]:k_ends[j]]
      new_smooths <- attach_k(smooth_lists[[j]], ks_slice)
      new_smooths <- paste(new_smooths, collapse = " + ")
      new_smooths <- gsub(" ", "", new_smooths)
      row.i[,j] <- new_smooths
    }
    out_tab[i,] <- row.i
  }
  return(out_tab |> mutate(Rank = 1:n()) |> relocate(Rank))
}
