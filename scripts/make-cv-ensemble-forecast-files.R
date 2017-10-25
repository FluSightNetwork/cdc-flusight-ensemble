## script to generate CV ensemble files

## devtools::install_github("jarad/FluSight")
library(FluSight) 
library(dplyr)
library(doMC)
registerDoMC(cores = 20)

source("scripts/stack_forecasts.R")

## get list of component models
model_names <- read.csv("model-forecasts/component-models/model-id-map.csv",
    stringsAsFactors = FALSE)

## get weights data.frame
weight_files <- list.files("weights")
weight_types <- sub(
    pattern = "-weights.csv", 
    replacement = "",
    weight_files)

for(j in 1:length(weight_files)){
    stacking_weights <- read.csv(paste0("weights/", weight_files[j]), 
        stringsAsFactors=FALSE)
    stacked_name <- sub(pattern = ".csv", replacement = "", weight_files[j])
    dir.create(file.path("model-forecasts", "cv-ensemble-models", stacked_name), 
        showWarnings = FALSE)
    
    #####
    ### verify that weights data_frame has weights for all models?
    #####
    
    seasons <- unique(stacking_weights$season)
    if("2017/2018" %in% seasons)
        seasons <- seasons[-which(seasons=="2017/2018")]
    ## loop through each season and each season-week to make stacked forecasts
    for(i in 1:length(seasons)){
        loso_season =  seasons[i]
        wt_subset <- filter(stacking_weights, season==loso_season) %>%
            dplyr::select(-season)
        
        ## identify the "EWXX-YYYY" combos for files given season
        first_year <- substr(loso_season, 0, 4)
        first_year_season_weeks <- if(first_year==2014) {43:53} else {43:52}
        week_names <- c(
            paste0("EW", first_year_season_weeks, "-", first_year),
            paste0("EW", formatC(1:18, width=2, flag=0), "-", as.numeric(first_year)+1)
        )
        
        foreach(k=1:length(week_names)) %dopar% {
        ## for(this_week in 1:length(week_names)) {
            this_week <- week_names[k]
            message(paste(stacked_name, "::", this_week, "::", Sys.time()))
            ## stack models, save ensemble file
            files_to_stack <- paste0(
                "model-forecasts/component-models/",
                model_names$model.dir, "/",
                this_week, "-", model_names$model.dir, ".csv"
            )
            file_df <- data.frame(
                file = files_to_stack, 
                model_id = model_names$model.id,
                stringsAsFactors = FALSE)
            stacked_entry <- stack_forecasts(file_df, wt_subset)
            stacked_file_name <- paste0(
                "model-forecasts/cv-ensemble-models/",
                stacked_name, "/", this_week, "-", stacked_name, ".csv"
            )
            write.csv(stacked_entry, file=stacked_file_name, 
                row.names = FALSE, quote = FALSE)
        }
    }
}
    