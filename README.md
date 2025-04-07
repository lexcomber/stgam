
# `stgam`: Spatially and Temporally Varying Coefficient Models Using Generalized Additive Models (GAMs)

<!-- badges: start -->
[![R-CMD-check](https://github.com/lexcomber/stgam/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/lexcomber/stgam/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The `stgam` package provides a framework for capturing process spatial and spatio-temporal heterogeneity, via a varying coefficient modelling approach. It provides a wrapper for GAM functionaility in the `mgcv` package and uses GAMs and Tensor Product (TP) smooths with Gaussian Process (GP) bases, with a focus on process understanding rather than prediction . The `stgam` workflow is to i) determine TP smooth length ranges with `opt_length_scale`, ii) evaluate different model forms with `evaluate_models`, iii) rank models and translate predictor variable indices with `gam_model_scores` and pick the best model, and iv) finally calculate the varying coefficient estimates.

## Installation

You can install the CRAN version of stgam :
``` r
install.packages("stgam")
```
Or the development version:
``` r
# just the package
remotes::install_github("lexcomber/stgam")
# with the vignettes - takes a bit longer
remotes::install_github("lexcomber/stgam", build_vignettes = TRUE, force = T)
```

## Example

This code below loads the package and undertakes the proposed workflow for a spatially varying coefficient model using GAMs with TP smooths:

```{r eval = F}
# a spatially varying coefficient model example
library(stgam)
require(dplyr)
# define input data
input_data = productivity |> filter(year == 1975) |> mutate(Intercept = 1)
# i) determine TP smooth length ranges
rho_sp <- opt_length_scale(input_data,
       target_var = "privC",
       vars = c("Intercept", "unemp", "pubC"),
       coords_x = "X",
       coords_y = "Y",
       STVC = FALSE)
# have a look: these are the spatial scales of interaction
rho_sp
# ii) evaluate different model forms from the GAM GCV score (an unbiased risk estimator)
svc_mods = evaluate_models(
       input_data = input_data,
       target_var = "privC",
       vars = c("unemp", "pubC"),
       coords_x = "X",
       coords_y = "Y",
       STVC = FALSE,
       rho_space_vec = round(rho_sp$rho_space,1))
# iii) rank models and translate predicor variable indices
mod_comp <- gam_model_scores(svc_mods)
# have a look
mod_comp |> select(-f)
# select best model
f = as.formula(mod_comp$f[1])
# put into a `mgcv` GAM model
m = gam(f, data = input_data)
# iv) calculate the Varying Coefficients
terms = c("Intercept", "unemp", "pubC")
vcs = calculate_vcs(input_data, m, terms)
vcs |> select(state, year, starts_with(c("b_", "se_")))
```
