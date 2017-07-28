---
output:
  word_document: default
  html_document: default
---
# Guidelines for a CDC FluSight ensemble (2017-2018)

## Overview of CDC FluSight
Starting in the 2013-2014 influenza season, the CDC has run the "Forecast the Influenza Season Collaborative Challenge" (a.k.a. FluSight) each influenza season, soliciting weekly forecasts for specific influenza season metrics from teams across the world. These forecasts are displayed together on [a website](https://predict.phiresearchlab.org/post/57f3f440123b0f563ece2576) during the season and are evaluated for accuracy after the season is over. 

## Ensemble prediction for 2017-2018 season
Seen as one of the most powerful and flexible prediction approaches available, ensemble methods combine predictions from different models into a single prediction. Beginning in the 2015-2016 influenza season, the CDC created a simple weighted average ensemble of the submissios to the challenge. In the upcoming 2017-2018 influenza season, the CDC intends to create and implement more sophisticated ensemble model based on some or all of the submissions to the CDC 2017-2018 FluSight challenge. This document outlines a proposed framework for a collaborative implementation of an ensemble during this time.

## Overall Timeline

 - early May 2017: ensemble framework announced and disseminated
 - July 15 2017: first deadline for providing historical out-of-sample forecasts to ensemble organizers
 - Summer 2017: structured experiments conducted to evaluate different ensemble specifications
 - October 15 2017: final deadline for providing historical out-of-sample forecasts to ensemble organizers for inclusion in 2017-2018 collaborative ensemble
 - November 13 2017: first real-time forecasts due to CDC
 - May 14 2018: last real-time forecasts due to CDC
 - Summer 2018: report/manuscript drafted summarizing the effort

## Parties involved

Ensemble organizers: a group of challenge participants and CDC officials who oversee the implementation of the ensemble challenge. Anyone is welcome to join this group, and must commit to a once-weekly conference call starting in July 2017.

Ensemble participants: anyone who submits forecasts for the July or October 2017 deadline. As detailed below, anyone is welcome to participate in the challenge.

Any interested parties are welcome to join the [FluSightNetwork email list](https://groups.google.com/d/forum/flusightnetwork).

## Implementation details

### Eligibility
All are welcome to participate in this collaborative challenge, including individuals or teams that have not participated in previous CDC forecasting challenges.

### Submissions

Submission will include a metadata file describing the model and out-of-sample forecasts for ensemble training purposes as described below. Templates for the submission materials are available [on GitHub](https://github.com/reichlab/cdc-flusight-ensemble/tree/master/templates).

 1. Metadata file
 
This will include

 - team name
 - team abbreviation for submission files
 - team members (with point of contact specified)
 - anonymity preference (one of either "anonymous" or "named")
 - brief description of data sources
 - whether or not the model itself is a type of ensemble model
 - methodological description, including the method used to ensure OOS predictions are made according to the ensemble rules.
 
 
 2. The "common development-set": out-of-sample forecast files
 
The CDC challenge for 2016-2017 required that all forecast submissions follow a particular format. This is described in detail elsewhere, but will be summarized here. A submission file represents the forecasts made for a particular epidemic week (EW) of a season. The file contains binned predictive distributions for seven specific targets (onset week, peak week, peak height, and weighted influenza-like-illness in each of the subsequent four weeks) across the 10 HHS regions of the US plus the national level.

To be included in the development of the ensemble forecast for the 2017-2018 season, each team is asked to provide out-of-sample forecasts for the 2010/2011 - 2016/2017 seasons by July 15 2017. Alternatively, a team may provide out-of-sample forecasts for the training seasons by October 15, 2017 to be included in the submitted collaborative ensemble for the 2017-2018 season. If a team cannot, for any reason (e.g. an exogenous data source was not available prior to 2015), provide the full set of out-of-sample forecasts, they may provide as few as the most recent 3 seasons of out-of-sample forecasts.

A team's OOS forecasts should consist of a folder containing a set of forecast files. Each forecast file must represent a single submission file, as would be submitted to the CDC challenge. Every filename should adopt the following standard naming convention: a forecast submission using week 43 surveillance data from 2016 submitted by John Doe University should be named “EW43-2016-JDU.csv” where EW43-2016 is the latest week and year of ILINet data used in the forecast, and JDU is the abbreviated name of the team making the submission (e.g. John Doe University). Neither of these names are pre-defined, but they must be consistent for all submissions by the team and specified in the metadata file. It should not include special characters or match the name of another team.

Teams will be trusted to have created their submitted forecasts in an  out-of-sample fashion, i.e. fitting or training the model on data that was only available after the time for which forecast was made would not be allowed. This is practically infeasible to check, so teams will be asked to provide, in a methodological write-up, a description of how they ensured out-of-sample forecasts were made. 

#### Requirements for ensemble forecast submissions
 
 A. Timing of forecasts and use of available data. Participants must be cognizant of any "backfill" issues with data available in realtime. For example, the wILI data for week 2014-04 that was available in week 2014-05 may be different than the data for 2014-04 that was available in week 2014-10. Other data sources may have similar issues with incomplete, partially reported, or backfilled data. For the OOS forecasts, care should be taken to ensure that for forecasts made for YYYY-WW, only data available at the time forecasts would have been made in real time is used. (To the extent possible: note that in some cases "unrevised" data is not available for some sources, and teams must to the extent possible use the best, i.e. most faithful to the real-time, data available.) For accessing the CDC influenza data that was available in real-time we encourage participants to use a source, such as the [DELPHI epidemiological data API](https://github.com/cmu-delphi/delphi-epidata), that provides the CDC ILI data available at a specific date. Also, the `mimicPastEpidataDF()` function in the [epiforecast R package](https://github.com/cmu-delphi/epiforecast-R) has some functionality to do this.  Specifically:

   - Retrospective component forecasts labeled week N are "due" (i.e. may only use data through) Monday 11:59pm of week N+2.
   - Prospective (2017/2018) component forecasts labeled week N are also due Monday 11:59pm of week N+2.
 
 B. Note that the condition above for creating out-of-sample forecasts is stronger than “leave-one-season-out”. Specifically, it is not allowed to use "leave-one-season-out" type of methodology for creating the out of sample predictions.
 
 C. The modeling framework must remain consistent over the course of the subsequent prospective forecasting effort in the 2017-2018 season.  Changes can of course be made to a site’s standalone forecasting submission, but the site’s contribution to the ensemble must remain essentially the same as that used to produce the OOS forecasts. Small modifications or bug-fixes to submitted models may be made without notification, however major changes to the model should be accompanied by resubmission of the out-of-sample prediction files for re-training of the model.

### Collaborative ensemble
The ensemble organizers, upon receiving the forecast submissions in July 2017, will conduct a small, structured cross-validation study to examine the prediction error of small number of pre-specified ensemble models. The study will involve choosing one or more optimal ensemble specification(s) for previous seasons using the out-of-sample common dev-set submissions.

Ensemble models to be considered will include:

 - A simple average of all models.
 - A weighted average with different weights for each model and metric, estimated by the degenerate EM algorithm.
 - A weighted average with weights that vary by season-week or other features of the data or predictions themselves.

### Licensed use of submissions

Upon registration for the challenge, teams will choose to make their predictions either anonymously or with attribution. All forecasts will be made publicly available under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License (CC BY-NC-SA 4.0)](https://creativecommons.org/licenses/by-nc-sa/4.0/) within one day of the submission deadline each week throughout the 2017-2018 season. 
Teams who participate should not expect to receive authorship in publications that use their forecast files, although the ensemble organizers request that a citation or other formal acknowledgment be provided when anyone uses a team's forecasts.
