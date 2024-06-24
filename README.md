
# stgam

<!-- badges: start -->
[![R-CMD-check](https://github.com/lexcomber/stgam/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/lexcomber/stgam/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of the `stgam` package is to provide a framework for capturing process spatial and or / or temporal heterogeneity, using a varying coefficient modelling approach based on GAMs with Gaussian Process (GP) smooths.  It constructs a series of models and uses probability to determine the best model or best set of competing models. Where there in no clear 'winner', competing and highly probabale models can be combined using Bayesian Model Averaging.

## Installation

You can install the development version of `stgam` :

``` r
# just the package
remotes::install_github("lexcomber/stgam")
# with the vignettes - takes a bit longer
remotes::install_github("lexcomber/stgam", build_vignettes = TRUE, force = T)
```

## Example

This code below loads the package and the package Imports (these have not been set as dependencies). It then undertakes and evaluates a series of spatially varying coefficient models using GAMs with GP smooths:

```{r eval = F}
library(stgam)
library(cols4all)   # for nice shading in graphs and maps
library(cowplot)    # for managing plots
library(dplyr)      # for data manipulation 
library(ggplot2)    # for plotting and mapping
library(glue)       # for model construction 
library(mgcv)       # for GAMs
library(sf)         # for spatial data
library(doParallel) # for parallelising operations
library(purrr)      # for model construction
library(tidyr)      # for model construction 

data("productivity")
data = productivity |> filter(year == "1970")
# create multiple models with different forms
svc_gam =
  evaluate_models(data = data,target_var = "privC", 
                  covariates = c("unemp", "pubC"),
                  coords_x = "X",
                  coords_y = "Y",
                  STVC = FALSE)
# examine
head(svc_gam)
# calculate the probabilities for each model 
mod_comp_svc <- gam_model_probs(svc_gam, n = 10)
# have a look
mod_comp_svc|> select(-f)
```

