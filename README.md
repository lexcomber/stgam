

# `stgam`: Spatially and Temporally Varying Coefficient Models Using Generalized Additive Models (GAMs)

<!-- badges: start -->
[![R-CMD-check](https://github.com/lexcomber/stgam/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/lexcomber/stgam/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

This package provides a framework for specifying space-time varying coefficient models using Generalized Additive Models (GAMs) with smooths. It builds on GAM functionality from the `mgcv` package. The smooths are parameterised with location, time and predictor variables. The framework suggests the need to investigate for the presence and nature of any space-time dependencies in the data. It proposes a workflow that creates and refines an initial space-time GAM and includes tools to create and evaluate multiple model forms. The workflow sequence is to: i) Prepare the data (`data.frame`, `tibble` or `sf` object) by lengthening it to have a single location and time variables for each observation. ii) Create all possible space and/or time models in which each predictor is specified in different ways in smooths. iii) Evaluate each model via their AIC value and pick the best one. iv) Create the final model. v) Calculate the varying coefficient estimates to quantify how the relationships between the target and predictor variables vary over space, time or space-time. vi) Create maps, time series plots etc. The number of knots used in each smooth can be specified directly or iteratively increased. This is ilustrated with a point dataset of NDVI and climate data. The data are sample of 2000 observations of Normalised Difference Vegetation Index (NDVI) (2012-2022) of the Chaco dry rainforest in South America with some climate data. This builds on work in Comber et al (2024) <doi:10.1080/13658816.2023.2270285> and Comber et al (2004) <doi:10.3390/ijgi13120459>.

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

This code below loads the package and undertakes the proposed workflow for a spatially varying coefficient model using GAMs with spatial smooths:

``` r
# a spatially varying coefficient model example
library(stgam)
library(dplyr)
library(ggplot2)
library(cols4all)

# define input data
data("hp_data")
input_data <-
  hp_data |>
  # create Intercept as an addressable term
  mutate(Intercept = 1)

# evaluate different model forms
svc_mods <-
  evaluate_models(
    input_data = input_data,
    target_var = "priceper",
    vars = c("pef", "beds"),
    coords_x = "X",
    coords_y = "Y",
    VC_type = "SVC",
    time_var = NULL,
    ncores = 2
  )
# rank the models
mod_comp <- gam_model_rank(svc_mods)
# have a look
mod_comp |> select(-f)

# select best model
f = as.formula(mod_comp$f[1])
# put into a `mgcv` GAM model
gam.m = gam(f, data = input_data)

# calculate the Varying Coefficients
terms = c("Intercept", "pef")
vcs = calculate_vcs(input_data, gam.m, terms)
vcs |> select(priceper, yot, X, Y, starts_with(c("b_", "se_")), yhat)

# map them
data(lb)
tit <-expression(paste(""*beta[`pef`]*"")) 
ggplot() + 
  geom_sf(data = lb, col = "lightgrey") +
  geom_point(data = vcs, aes(x = X, y = Y, col = b_pef)) + 
  scale_colour_continuous_c4a_div("brewer.rd_yl_bu", name = tit) +
  theme_bw() +
  coord_sf() +
  xlab("") + ylab("")

```
