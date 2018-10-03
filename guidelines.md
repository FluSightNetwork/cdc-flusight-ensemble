# Guidelines for the participating in the FluSight Network ensemble 
updated 22 August 2018 for the 2018-2019 season

## Overview of CDC FluSight
Starting in the 2013-2014 influenza season, the CDC has run the "Forecast the Influenza Season Collaborative Challenge" (a.k.a. FluSight) each influenza season, soliciting weekly forecasts for specific influenza season metrics from teams across the world. These forecasts are displayed together on [a website](https://predict.phiresearchlab.org/post/57f3f440123b0f563ece2576) during the season and are evaluated for accuracy after the season is over. 

## Ensemble prediction for 2018-2019 season
Seen as one of the most powerful and flexible prediction approaches available, ensemble methods combine predictions from different models into a single prediction. Beginning in the 2015-2016 influenza season, the CDC created a simple weighted average ensemble of the submissios to the challenge. In the 2016-2017 season, this model was one of the top performing models among all of those submitted. In the  2017-2018 influenza season, the FluSight Network created, validated, and implemented a collaborative ensemble model that was be submitted to the CDC on a weekly basis. This model was based on a subset of all models submitted to the CDC. Any team that submitted a complete set of "submission files" from past years had their models included in the collaborative ensemble. (See details on submissions below.) This model was one of the top-performing forecasting models overall, scoring just 0.003 units of "forecast skill" behind the top Delphi-Epicast model. 

This document details the steps to take to participate in the collaborative ensemble for the 2018-2019 season and details how the ensemble will be implemented for this season.

## Overall Timeline

 - late August 2018: guidelines for 2018-2019 season finalized
 - October 15 2018: final deadline for providing historical out-of-sample forecasts to ensemble organizers for inclusion in 2018-2019 collaborative ensemble
 - November 5 (?) 2018: first real-time forecasts due to CDC
 - May XX 2019: last real-time forecasts due to CDC
 - Summer 2019: report/manuscript drafted summarizing performance in past season

## Parties involved

Ensemble organizers: a group of challenge participants and CDC officials who oversee the implementation of the ensemble challenge. Anyone is welcome to join this group.

Ensemble participants: anyone who submits forecasts for the October 2018 deadline. As detailed below, anyone is welcome to participate in the challenge.

Any interested parties are welcome to join the [FluSightNetwork email list](https://groups.google.com/d/forum/flusightnetwork).

## Implementation details

### Eligibility
All are welcome to participate in this collaborative challenge, including individuals or teams that have not participated in previous CDC forecasting challenges.

### Submissions

Submission will include a metadata file describing the model and out-of-sample forecasts for ensemble training purposes as described below. Existing submissions can be viewed as templates for the submission materials, and are available [on GitHub](https://github.com/reichlab/cdc-flusight-ensemble/). The files for a single model should be contained within a subfolder in the `model-forecasts/component-models/` directory of this repository. The folder should follow the naming convention of "teamabbreviation_model_name". Each folder should contain the following files:

 1. Metadata file (`metadata.txt`)
 
This will include

 - team name
 - team abbreviation for submission files
 - team members (with point of contact specified)
 - anonymity preference (one of either "anonymous" or "named")
 - brief description of data sources
 - whether or not the model itself is a type of ensemble model
 - methodological description, including the method used to ensure OOS predictions are made according to the ensemble rules. 
 
 
 2. The "common development-set": out-of-sample forecast files
 
The CDC challenge for 2017-2018 required that all forecast submissions follow a particular format. This is [described in detail elsewhere](https://predict.phiresearchlab.org/post/57f3f440123b0f563ece2576), but will be summarized here. A submission file represents the forecasts made for a particular epidemic week (EW) of a season. The file contains binned predictive distributions for seven specific targets (onset week, peak week, peak height, and weighted influenza-like-illness in each of the subsequent four weeks) across the 10 HHS regions of the US plus the national level.

To be included in the collaborative ensemble forecast for the 2018-2019 season, each team is asked to provide out-of-sample forecasts for the 2010/2011 - 2017/2018 seasons by October 15, 2018. If a team cannot, for any reason (e.g. an external data source was not available prior to 2015), provide the full set of out-of-sample forecasts, they may provide as few as the most recent 3 seasons of out-of-sample forecasts. At this point, we are not making guarantees that models that do not provide the full set of training data will be included in the final collaborative ensemble.

A team's OOS forecasts should consist of a subfolder containing a set of forecast files.  The files for a single model should be contained within a subfolder in the `model-forecasts/component-models/` directory of this repository. The folder should follow the naming convention of "teamabbreviation_model_name".  Each forecast file must represent a single submission file, as would be submitted to the CDC challenge. Every filename should adopt the following standard naming convention: a forecast submission using week 43 surveillance data from 2016 submitted by John Doe University using a model called "modelA" should be named “EW43-2016-JDU_modelA.csv” where EW43-2016 is the latest week and year of ILINet data used in the forecast, and JDU is the abbreviated name of the team making the submission (e.g. John Doe University). Neither the team or model names are pre-defined, but they must be consistent for all submissions by the team and match the specifications in the metadata file. Neither should include special characters or match the name of another team.

Teams will be trusted to have created their submitted forecasts in an  out-of-sample fashion, i.e. fitting or training the model on data that was only available after the time for which forecast was made would not be allowed. This is practically infeasible to check, so teams will be asked to provide, in a methodological write-up, a description of how they ensured out-of-sample forecasts were made. 


#### Requirements for ensemble forecast submissions
 
 A. Timing of forecasts and use of available data. Participants must be cognizant of any "backfill" issues with data available in realtime. For example, the wILI data for week 2014-04 that was available in week 2014-05 may be different than the data for 2014-04 that was available in week 2014-10. Other data sources may have similar issues with incomplete, partially reported, or backfilled data. For the out-of-sample forecasts, care should be taken to ensure that for forecasts made for the file "EWXX-YYYY", only data available at the time forecasts would have been made in real time is used. (To the extent possible: i.e. note that in some cases "unrevised" data is not available for some sources, and teams must to the extent possible use the best or most faithful to the real-time, data available.) For accessing the CDC influenza data that was available in real-time we encourage participants to use a source, such as the [DELPHI epidemiological data API](https://github.com/cmu-delphi/delphi-epidata), that provides the CDC ILI data available at a specific date. Also, the `mimicPastEpidataDF()` function in the [epiforecast R package](https://github.com/cmu-delphi/epiforecast-R) has some functionality to do this.  
 
Some data and code has been compiled from previous efforts to find the "unrevised" data available at each week. For example the ReichLab team used [this function](https://github.com/reichlab/2017-2018-cdc-flu-contest/blob/master/R/get-partially-revised-data.R) in [this script](https://github.com/reichlab/2017-2018-cdc-flu-contest/blob/master/inst/data-processing/save-unrevised-data.R) to generate [this R data file](https://github.com/reichlab/2017-2018-cdc-flu-contest/raw/master/data/flu_data_with_backfill.rds) that contains records of the data available at each timepoint (through the end of the 2016-2017 season). Others may use or adapt this code for generating their forecasts from revised data.
 
Specific guidelines for using data with revisions:

   - Retrospective component forecasts labeled "EWXX" are "due" (i.e. may only use data through) Monday 11:59pm of week XX+2.
   - Prospective (2017/2018) component forecasts labeled "EWXX" are also due Monday 11:59pm of week XX+2.
 
 B. Note that the condition above for creating out-of-sample forecasts is stronger than “leave-one-season-out”. Specifically, it is not allowed to use "leave-one-season-out" type of methodology for creating the out of sample predictions.
 
 C. The modeling framework must remain consistent over the course of the subsequent prospective forecasting effort in the 2018-2019 season.  Changes can of course be made to a site’s standalone forecasting submission, but the site’s contribution to the ensemble must remain essentially the same as that used to produce the OOS forecasts. Small modifications or bug-fixes to submitted models may be made without notification, however major changes to the model should be accompanied by resubmission of the out-of-sample prediction files for re-training of the model.

 D. For each season, files should be submitted for EW40 of the first calendar year of the season through EW20 of the follwing calendar year. For seasons that contain an EW53, a separate file labeled EW53 should be submitted. Additionally, for the peak week and onset week targets, a bin for EW53 should be included in all submission files for the seasons that have an EW53.


## Building the collaborative ensemble
The ensemble organizers, upon receiving the finalized forecast submissions in October 2018, will conduct a small, structured cross-validation study to examine the prediction error of small number of pre-specified ensemble models. The study will involve choosing one ensemble specification, chosen based on cross-validated performance in previous seasons, to submit to the CDC for the 2018/2019 forecasting challenge. This ensemble will be chosen prior to the first submission on November 5, 2018. It will remain constant throughout the entire season. No new component models will be added to the ensemble during the course of the season.

### Model specifications considered for submission to CDC

Ensemble models will use the method of stacking probabilistic distributions to create the collaborative ensemble, as described for example by [Ray and Reich (2018)](https://doi.org/10.1371/journal.pcbi.1005910). Let the number of component models be represented by $M$. The following weighting parameterizations will be evaluated (number of weight parameters to be estimated is in parentheses):

 - Equal weights for all models (0).
 - Weights estimated per model (_M_). 
 - Weights estimated per model and target-type (_2M_, one set of weights for seasonal targets, another for weekly incidence).
 - Weights estimated per model and target (_7M_).
 
If time permits additional exploration, we may additionally explore weights by model, target-type, and region (_22M_), with a possible constraint of only including the top 5 models in the ensemble.

### Ensemble validation and comparison for CDC submission

We will have eight years of data available for training and testing to choose a "best" ensemble specification. We will use leave-one-season-out cross-validation in all of the seven seasons on all ensemble specifications. Since we are only going to be looking at a very slim and simple list of ensemble specifications (nothing more than model/target combos), the risk of overfitting is smaller than it might be had we chosen some of the more heavily parameterized models. Therefore, we will not use separate testing and training phases for the ensemble model. The model with the highest average log-score across all regions, seasons, and targets will be selected as the ensemble specification to be submitted to the CDC.

<!--If up to two models perform significantly worse during this time (using permutation test framework described below) then they will be discarded before the testing phase. Therefore, no fewer than two models will be carried forward into the testing phase. -->

### Pre-specified analyses of ensemble performance

#### Retrospective (seven years of training data)

While the decision about which model to submit to the CDC will be made solely on the basis of the highest average log score, additional analyses will be implemented to understand better the uncertainty in our assessment of the "best" model. We will use permutation tests to make pairwise comparisons of the performance of the ensemble methods listed above. This will involve multiple separate hypothesis tests. Due to the low number of training seasons available, we will have limited power to detect true differences between models. We will evaluate differences between models, using a slightly anti-conservative Type-I error threshold of 0.10, with an additional Bonferroni correction depending on the exact number of tests performed.

#### Prospective (2018-2019 season)

At the end of the 2018-2019 season, we will compare the region-specific performance (log-score) of each component model as well as the chosen ensemble. Since will only represent the performance of a single season, we will not make a formal statistical evaluation of these scores.

### Licensed use of submissions

Upon registration for the challenge, teams will choose to make their predictions either anonymously or with attribution. All forecasts will be made publicly available under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License (CC BY-NC-SA 4.0)](https://creativecommons.org/licenses/by-nc-sa/4.0/) within one day of the submission deadline each week throughout the 2018-2019 season. 
Teams who participate should not expect to receive authorship in publications that use their forecast files, although the ensemble organizers request that a citation or other formal acknowledgment be provided when anyone uses a team's forecasts. Citations to the ensemble and this repository are asked to use [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1255023.svg)](https://doi.org/10.5281/zenodo.1255023).

