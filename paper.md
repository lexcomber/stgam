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

We are often interested in understanding how and where statistical relationships vary over space, and how they change over time. Quantifying such *process heterogeneity* (spatial and or temporal) can be done using *varying coefficient* models. The opportunity to undertake such space-time analyses are greater due to the increased generation and availability of data that include both spatial and temporal attributes (e.g. GPS coordinates and time-stamps). The **stgam** package provides a framework for creating regression models using Generalized Additive Models (GAMs) [@hastie1990generalized] in which the relationships between the response (dependent) variable and individual predictor (independent) variables are allowed to vary over space, time or both.

# Reference
