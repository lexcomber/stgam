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

# Reference
