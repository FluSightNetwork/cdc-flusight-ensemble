# Guidelines for a CDC FluSight ensemble (2017-2018)

## Overview of CDC FluSight
Starting in 20XX, the CDC has run the "Forecast the Influenza Season Collaborative Challenge" (a.k.a. FluSight), soliciting weekly forecasts of specific influenza season metrics from teams across the world during the influenza season. These forecasts are displayed together on [a website](https://predict.phiresearchlab.org/post/57f3f440123b0f563ece2576) during the season and are evaluated for accuracy after the season is over. 

## Ensemble prediction for 2017-2018 season
Seen as one of the most powerful and flexible prediction approaches available, ensemble methods combine predictions from different models into a single prediction. In the upcoming 2017-2018 influenza season, the CDC intends to create and implement an ensemble model based on some or all of the submissions to the CDC 2017-2018 FluSight challenge. This document outlines a proposed framework for a collaborative implementation of an ensemble during this time.

## Overall Timeline
April 1 2017: ensemble framework announced and disseminated
July 1 2017: out-of-sample forecasts due to CDC
October 2017: first real-time forecasts due to CDC
April 2018: last real-time forecasts due to CDC
Summer 2018: report/manuscript drafted summarizing the effort

## Implementation details

### Eligibility
All are welcome to participate in this collaborative challenge, including individuals or teams that have not participated in previous CDC forecasting challenges.

### Submission contents
Each team will be required to submit a metadata file that includes

 - team name
 - team members
 - License for forecast use (CDC only, participants only, public)
 - brief description of data sources
 - methodological description, including the method used to ensure OOS predictions are made according to the ensemble rules.
 
Additionally, each team will submit a set of out-of-sample forecasts, as described below, for ensemble training purposes.
 
### Submission unit: a CDC forecast file
The CDC challenge for 2016-2017 required that all forecast submissions follow a particular format. This is described in detail elsewhere, but will be summarized here. A submission file represents the forecasts made for a particular epidemic week (EW) of a season. The file contains binned predictive distributions for seven specific targets (onset week, peak week, peak height, and weighted influenza-like-illness in each of the subsequent four weeks) across the 10 HHS regions of the US plus the national level.

### Out-of-sample forecast files
To be included in the ensemble forecast for the 2017-2018 season, each team must provide out-of-sample forecasts for the 2010/2011 - 2016/2017 seasons [this is strict, but without some requirement of several seasons of training, how will we know how good the models are?] several months in advance of 2017-2018 competition [time TBD, but maybe June/July 2017?] . A team's OOS forecasts should consist of a folder containing a set of forecast files. Each forecast file must represent a single submission file, as would be submitted to the CDC challenge. Every filename should adopt the following standard naming convention: a forecast submission using week 43 surveillance data from 2016 submitted by John Doe University should be named “EW43-2016-JDU.csv” where EW43-2016 is the latest week and year of ILINet data used in the forecast, and JDU is the name of the team making the submission (e.g. John Doe University). 

Teams will be trusted to have created their submitted forecasts in an  out-of-sample fashion, i.e. fitting or training the model on data that was only available after the time for which forecast was made would be not allowed. Due to feasibility this will not be checked, so teams will be asked to provide, in a methodological write-up, a description of how they ensured out-of-sample forecasts were made. 

There are several requirements for the ensemble forecast submissions:
 
 1. For a submitted forecast made using data available for YYYY-WW, the forecast may only use data available on or before YYYY-WW. [There may be a more subtle point that we need to make here. I.e. specify for each YYYY-WW that we are asking for OOS forecasts for, an associated date on which that ILI data is published. This date should then be used as the cutoff for external data.]
 2. Every set of submitted forecasts for a particular season should be based on a model fit to previous seasons. Teams would not be allowed to use "leave-one-season-out" type of methodology for creating out of sample predictions.
 3. The modeling framework must remain consistent over the course of the subsequent prospective forecasting effort in the 2017-2018 season.


### CDC-run ensemble
The CDC, upon receiving the forecast submissions, will conduct a small study to choose between a small number of pre-specified ensemble models. The study will involve choosing optimal parameters to create an ensemble forecast for previous seasons using the out-of-sample training submissions.

Ensemble models to be considered will include:

 - A simple average of all models.
 - A weighted average with different weights for each model and metric, estimated by the degenerate EM algorithm.

### Research use

