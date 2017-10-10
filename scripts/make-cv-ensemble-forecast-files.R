## script to generate CV ensemble files

## devtools::install_github("jarad/FluSight")
library(FluSight) 
library(dplyr)
library(doMC)

source("scripts/stack_forecasts.R")

## get list of component models
model_names <- system("ls model-forecasts/component-models", intern=TRUE)

## get weights data.frame
stacking_weights <- read.csv("weights/equal-weights.csv", stringsAsFactors=FALSE)
stacked_name <- "equal-weights"
dir.create(file.path("model-forecasts", "cv-ensemble-models", stacked_name), 
    showWarnings = FALSE)

#####
### verify that weights data_frame has weights for all models?
#####

seasons <- unique(stacking_weights$season)
registerDoMC()
## loop through each season and each season-week to make stacked forecasts
foreach(i=1:length(seasons)) %dopar% {
    loso_season =  seasons[i]
    wt_subset <- filter(stacking_weights, season==loso_season) %>%
        select(-season)
    
    ## identify the "EWXX-YYYY" combos for files given season
    first_year <- substr(loso_season, 0, 4)
    first_year_season_weeks <- if(first_year==2014) {43:53} else {43:52}
    week_names <- c(
        paste0("EW", first_year_season_weeks, "-", first_year),
        paste0("EW", formatC(1:20, width=2, flag=0), "-", as.numeric(first_year)+1)
    )

    for(week in week_names) {
        ## stack models, save ensemble file
        files_to_stack <- paste0(
            "model-forecasts/component-models/",
            model_names, "/",
            week, "-", model_names, ".csv"
        )
        file_df <- data.frame(file = files_to_stack, model_id = model_names,
            stringsAsFactors = FALSE)
        stacked_entry <- stack_forecasts(file_df, wt_subset)
        stacked_file_name <- paste0(
            "model-forecasts/cv-ensemble-models/",
            stacked_name, "/", week, "-", stacked_name, ".csv"
        )
        write.csv(stacked_entry, file=stacked_file_name, 
            row.names = FALSE, quote = FALSE)
    }
}

