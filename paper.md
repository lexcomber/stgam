---
title: 'stgam: An R package for GAM-based varying coefficient models'
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

Very often we are interested in quantifying how and where statistical relationships vary over space, and how they change over time. This can be doine using *varying coefficient* models. Our ability to undertake such space-time analyses is enhanced by the increased production and availability of data describing a wide range of phenomenon that include both spatial and temporal attributes in the form of GPS coordinates and time-stamps. The `stgam` cpackage provides a fremwork for creating regression models in which the relationships between the response (dependent) variable and individual predictor (independent) variables is allowed to vary over space, time or both, in order to create spatially, temporally or spatio-temporally varying coefficient models. 


However a key question is what form of space-time interaction should be specified in our staistical models? Most current approaches require this to be specified in advance. when the  The `stgam` package provides w

# Statement of need
Generalized Additive Models (GAMs) [@hastie1990generalized] provide a framework for constructing regression models in which the response varibale can have Gaussian and non-Gaussian distrubtions and linear or non-linear relationships with the predictor variables. GAMs handle varying responses and non-linear relationhsips using smooths. When smoths include location as well as indivodual predictor variables, then the result is a sptially varying coefficient model, with time a temporally varying one, and the inclusion of space *and* time results in a spatially and temporally varying coefficient model. 

The need There are a number of approaches for quantifying spatial characteristics such as spatial autocorrelation [@moran1950notes; @cliff1973; @getis2008history; @cliff2009were] and processes spatial heterogeneity  [@casetti1972generating; @jones1991specifying; @brunsdon1996geographically; @mcmillen1996one; @fotheringham2002geographically; @gelfand2003spatial; @griffith2008spatial]. Tools also exist that quantify the temporal dynamics of spatial processes [@pace1998spatiotemporal; @pace2000method; @elhorst2003specification; @gelfand2004dynamics; @di2006generalized; @crespo2007application; @huang2010geographically]. @griffith2010modeling groups these into approaches that model autocorrelation effects such as space-time autoregressive integrated moving average models, spatial panel regressions and geo-statistical space-time models, and temporal extensions to approaches that model relationship spatial heterogeneity such as eigenvector filtering, geographically weighted regression and Bayesian spatially varying coefficient models.

All of the space-time approaches described above make a critical assumption about the presence and nature of the space-time relationships in the data, as documented in @comber2024gtgpjgis: space-time autoregressive models assume that measurements collected over space and time are spatially and temporally correlated, spatial panel regression models assume the presence of serial and spatial autocorrelation and geo-statistical models are concerned with prediction uncertainty not process understanding. The other approaches, eigenvector spatio-temporal filtering [@patuelli2011spatial; @chun2014analyzing], geographically and temporally weighted regression (GTWR) [@huang2010geographically; @fotheringham2015geographical] and Bayesian models extended to space-time [@gelfand2005spatial; @paez2008spatially; @amaral2011hierarchical], all assume the presence of latent spatial and temporal autocorrelation in variables.

This paper describes an R package and a workflow for undertaking space-time varying coefficient (STVC) models using GAMs. It parameterises GAMS with Gaussian Process (GP) smooths for spatially varying coefficient (SVC), temporally varying coefficient (TVC) and STVC models, and explicitly investigates spatio-temporal interactions in the data in order to determine the appropriate spatio-temporal model form. This workflow supports user investigations of the presence and the nature of data spatial interactions, temporal interactions, as well as space-time ones. This builds on the work describing the development for spatially varying coefficient models with GP-GAMs in @comber2024multiscale and the extension to spatial and temporal coefficient modelling in @comber2024gtgpjgis. 
# Package overview

# Worked example

# Reference
