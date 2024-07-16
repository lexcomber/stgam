---
title: '**stgam**: An R package for GAM-based varying coefficient models'
tags:
  - R
  - spatio-temporal analysis
authors:
  - name: Lex Comber
    orcid: 0000-0002-3652-7846
    equal-contrib: true
    affiliation: 1
  - name: Paul Harris
    orcid: 0000-0003-0259-4079
    equal-contrib: true
    affiliation: 2
  - name: Chris Brunsdon
    orcid: 0000-0003-4254-1780
    equal-contrib: true
    affiliation: 3
affiliations:
 - name: School of Geography, University of Leeds, UK
   index: 1
 - name: Rothamsted Research, North Wyke, UK
   index: 2
 - name: National Centre for Geocomputation, Maynooth University, Ireland
   index: 3
date: 16 July 2024
bibliography: paper.bib
---

# Summary

We are often interested in understanding how and where statistical relationships vary over space, and how they change over time. Quantifying such *process heterogeneity* (spatial and or temporal) can be done using *varying coefficient* models. The opportunity to undertake such space-time analyses are greater due to the increased generation and availability of data that include both spatial and temporal attributes (e.g. GPS coordinates and time-stamps). The **stgam** package provides a framework for creating regression models using Generalized Additive Models (GAMs) [@hastie1990generalized] in which the relationships between the response (dependent) variable and individual predictor (independent) variables are allowed to vary over space, time or both. It addresses a key question of the form space-time interaction to be specified in models. Frequently randomly guessed have to be made about the form of predictor-to-response relationships until an effective model form and associated model fits are found. To address this the **stgam** package includes functions to create multiple models, each specifying different relationships between the response variable $y$ and the predictor variables $x_1 \dots x_n$. Each model is evaluated using the Bayesian Information Criterion (BIC) [@schwarz1978estimating] which approximates the likelihood (probability) of the model being the correct model, given the data used in the analysis. Where multiple models are highly probable, then these can be be combined using a Bayesian Model Averaging approach [@fragoso2018bayesian; @brunsdon2023gisci]. Finally the **stgam** package contains functions for creating spatially and / or temporally varying regression coefficient estimates. These can be mapped in the usual way to show how where and when the relationships between the response and the predictor variables vary over space and time.

# Statement of need

A number approaches have been established to quantify process spatial non-stationarity or heterogeneity [@casetti1972generating; @jones1991specifying; @brunsdon1996geographically; @mcmillen1996one; @fotheringham2002geographically; @gelfand2003spatial; @griffith2008spatial] and tools also exist to quantify the *temporal* dynamics of these [@pace1998spatiotemporal; @pace2000method; @elhorst2003specification; @gelfand2004dynamics; @di2006generalized; @crespo2007application; @huang2010geographically]. All existing models require the user to make decisions about the nature of the space-time relationships in the data and thus the model and assume the presence of latent spatial and temporal autocorrelation in variables. The most commonly used approach in geographical analyses of space-time problems is geographically and temporally weighted regression (GTWR) [@huang2010geographically] which seeks to optimises a single space-time kernel to define the space-time relationships of all covariates with the target variable. Some recent steps in the right direction have been taken in this regard: @liu2017mixed developed a semi-parametric temporal extension to mixed geographically weighted regression, in which some relationships and coefficients are assumed to be globally constant and others vary locally over time; @hong2021spatiotemporal used a bootstrap approach to identify global coefficients in such models, but still define the same space-time relationship for each varying covariate.

To address this gap, the **stgam** package draws from the `mgcv` GAM package [@wood2017generalized]. GAMs are able to handle many kinds of responses  [@fahrmeir2021regression] and provide an intuitive approach to fit relatively complex relationships in data with complex interactions and non-linearities [@wood2017generalized]. The outputs of GAMs provide readily understood summaries of the relationship between predictor and response variables, and how the outcome is modelled. They are able to predict well from complex systems, quantify relationships, and support inferences about these relationships, such as which variables are important and at what range of values they are most influential [@hastie1990generalized; @wood2017generalized]. GAMs can perform as well as or better than most machine learning models and they are relatively fast [@friedman2001greedy; @wood2017generalized]. Importantly, in the context of varying coefficient modelling, GAMs combine predictive power, model accuracy and model transparency. GAMs model non-linear relationships using smooths, also referred to as splines. These can be of different forms depending on the problem and data [@hastie1990generalized] and, as they can be represented as linear combinations of basis functions, they are sometimes referred to as Gaussian Process (GP) splines. A GP is a random process over functions, and its terms can be modelled using GP-splines within a GAM. Thus GP splines are represented as a linear combination of non-linear *basis functions* of predictor variables, which can generate predictions of the outcome variable. Basis functions can be either single or multi-dimensional in terms of predictor variables. As a result, a GAM consists of linear sums of multi-dimensional basis functions that allow complex relationships to be modelled. The appropriate degree of "wiggliness" in each spline is determined by the smoothing parameters, which balances over-fitting versus capturing the complexity in the relationship. GAMs with GP smooths parameterised with location and / or time can be used to construct regression models that allow coefficient estimates to vary and capture process spatial and / or temporal heterogeneity: a varying coefficient approach. While spline-based varying coefficient models have been proposed, for example using a generalized linear model with reduced-rank thin-plate splines [@fan2022spatially], here the predictor-to-response relationship is considered over space and time as a GP. 

A final consideration is the need to determine model form. Standard approaches for constructing spatially and  temporally varying coefficient models, which in the absence of a theoretical model, commonly assume that some degree of spatial and temporal dependence *is* present in the data and in the relationship of each covariate with the target variable. In the GAM GP smooth approach, each covariate would be specified in a SP smooth parameterised with location and with time under the assumption that any temporal trends in coefficient estimates *will* vary with location. However, each covariate can be specified in six different ways: it can be omitted, included as a parametric (global) term, in a smooth with location, in a smooth with time, in a smooth with location *and* time, or in two separate space and time smooths. The last five options similarly apply to the intercept. 

# Package overview

The **stgam** package contains functions to support varying coefficient modelling using GAMs with GP smooths, that provide a wrapper for the GAM implementation in the `mgcv` package [@wood2015package], that create, evaluate, and aggregate multiple models. It also contains two datasets that are used to illustrate the functions. These are described in Table \ref{tbl:stgampackage}. 


\begin{table}[h]
  \centering
    \caption{Functions and data currently implemented in \textbf{stgam}.}
      \label{tbl:stgampackage}
\begin{tabular}{l|l|p{6cm}}
\hline
Name & Type & Description\\
\hline
calculate\_vcs() & function & Extracts varying coefficient estimates (for SVC, TVC and STVC)\\
do\_bma() & function & Undertake undertake coefficient averaging using Bayesian Model Avergaing (BMA), weighting different models by their probabailities\\
evaluate\_models() & function & Creates evaluates multiple varying coefficient GAM GP smooth models (SVC or STVC)\\
gam\_model\_probs() & function & Calculates the model probabilities of the different GAM models generated by evaluate\_models'\\
plot\_1d\_smooth() & function & Plots a 1-Dimensional GAM smooth\\
plot\_2d\_smooth() & function & Plots a 2-Dimensional GAM smooth\\
productivity & data & US States Economic Productivity Data (1970-1985)\\
us\_data & data & US States boundaries\\
\hline
\end{tabular}
  \end{table}

The package includes two vignettes. The first, *space-time-gam-intro*, provides a gentle introduction to undertaking varying coefficient regression analyses with GAMs via the **mgcv** package. The second vignette, *space-time-gam-model-probs-BMA*, describes a standard **stgam** workflow to create and evaluate multiple models, and then to either select the best one or to combine competing models using Bayesian Model Averaging.

# References
