# stgam 0.0.0.9000

* created initial package for GitHub.

# stgam 0.0.1.0

* created initial package for CRAN submission.
* tidied functions to overcome 'no visible global function definition' in CMD checks,

# stgam 0.0.1.1

* updated initial package to replace `data` function inputs with `input_data`.
* tidied help file omissions and typos

# stgam 0.0.1.2

* corrected and genericised the `do_bma` function

# stgam 0.0.1.3

* expanded the output of `do_bma` to include averaged $\hat{y}$ and working residuals
* returns weighted vary coefficient estimates appended to input data

# stgam 1.0.0

* space-time GAMs are reformatted to include Tensor Product smooths for combined space-time 
* modelling averaging is removed

# stgam 1.0.1

* London borough data (`lb`) corrected  
* typos in vignette corrected 

# stgam 1.0.2

* fix to vignette plot 

# stgam 1.1.0

* updates to functions and vignette to use `te()` tensor product smooths for space-time smooths, replacing `t2()`
* inclusion of t-values in coefficient estimates    

# stgam 1.2.0

* updates to main function (`evaluate_models()`) for user specification of `k` or to increase `k` automatically
* new function for quantifying the effect size of each model term (`effect_size()`)
* updates to `gam_model_rank` to evaluate models by AIC and to report `k` for each smooth
* new vignettes 
* new case study dataset  
