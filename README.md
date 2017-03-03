# Guidelines for a collaborative CDC FluSight ensemble effort for the 2017-2018 season.

## Overview of CDC FluSight
Starting in 20XX, the CDC has run the "Forecast the Influenza Season Collaborative Challenge", soliciting weekly forecasts of specific influenza season metrics from teams across the world during the influenza season. These forecasts are displayed together on a CDC-hosted website during the season and are evaluated for accuracy after the season is over.

## Ensemble prediction
Seen as one of the most powerful predictive methods available, ensemble models combine predictions from different models into a single prediction. We propose to implement an ensemble based on some or all of the submissions to the 2017-2018 influenza season challenge.

Specifically, we propose a framework for teams to share out-of-sample forecasts for previous years. These forecasts could be made available to the CDC only, could be made available to other members of the CDC influenza forecasting community, or could be made publicly available.

## Implementation details

### Submission unit: a CDC forecast file
The CDC challenge currently enforces a particular format to be followed. This is described in detail elsewhere, but will be summarized here. A submission file represents the forecasts made for a particular epidemic week (EW) of a season. The file contains binned predictive distributions for seven specific targets (onset week, peak week, peak height, and weighted influenza-like-illness in each of the subsequent four weeks) across the 10 HHS regions of the US plus the national level.

### Out-of-sample forecast files
To be included in the ensemble forecast for the 2017-2018 season, each team must provide at least one season of out-of-sample forecasts several months in advance of 2017-2018 competition [time TBD, but maybe June/July 2017?] . A team's OOS forecasts should consist of a folder containing a set of forecast files. Each forecast file must represent a single submission file, as would be submitted to the CDC challenge, and it must have a specific naming scheme (to be determined) that defines the year and epidemic week (EW) for which the file was created. 

Teams will be trusted to have created their submitted forecasts in an  out-of-sample fashion, i.e. fitting or training the model on data that was only available after the time for which forecast was made would be not allowed. Due to feasibility this will not be checked, so teams will be asked to provide, in a methods write-up, a description of how they ensured out-of-sample forecasts were made. 

There are several requirements for the ensemble forecast submissions:
 
 1. For a submitted forecast made as if in YYYY-WW, the forecast may only use data available on or before YYYY-WW.
 2. Every set of submitted forecasts for a particular season should be based on a model fit to previous seasons. Teams would not be allowed to use "leave-one-season-out" type of methodology for creating out of sample predictions.
 3. The modeling framework must remain consistent over the course of the subsequent prospective forecasting effort in the 2017-2018 season.

### Submission metadata
Each team will be required to submit a metadata file that includes

 - team name
 - team members
 - License for forecast use (CDC only, participants only, public)
 - brief description of data sources
 - methodological description, including the method used to ensure OOS predictions are made according to the ensemble rules.
 
### CDC-run ensemble
The CDC, upon receiving the forecast submissions, will conduct a small study to choose between a small number of pre-specified ensemble models. The study will involve choosing optimal parameters to create an ensemble forecast for previous seasons using the OOS test submissions. [This may be complicated by teams having submitted different numbers of OOS forecasted seasons. We could require teams to submit at least two seasons.]

Ensemble models to be considered will include:

 - A simple average of all models.
 - A weighted average with different weights for each model and metric, estimated by the degenerate EM algorithm.

### Research use

