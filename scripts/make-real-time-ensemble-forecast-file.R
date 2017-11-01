## script to generate real-time ensemble entry file
## Nicholas Reich
## created: November 2017

library(FluSight) ## devtools::install_github("jarad/FluSight")
library(dplyr)

source("scripts/stack_forecasts.R")

THIS_SEASON <- "2017/2018"
THIS_EW <- 43

## get list of component models
model_names <- read.csv("model-forecasts/component-models/model-id-map.csv",
    stringsAsFactors = FALSE)

## get weights data.frame for used weights
weight_files <- list.files("weights")

for(j in 1:length(weight_files)){
    stacking_weights <- read.csv(paste0("weights/", weight_files[j]), 
        stringsAsFactors=FALSE)
    stacked_name <- sub(pattern = ".csv", replacement = "", weight_files[j])
    dir.create(file.path("model-forecasts", "real-time-ensemble-models", stacked_name), 
        showWarnings = FALSE)
    
    wt_subset <- dplyr::filter(stacking_weights, season==THIS_SEASON) %>%
        dplyr::select(-season)
    weight_var_cols <- colnames(wt_subset)[!(colnames(wt_subset) %in% c("component_model_id", "weight"))]
    
    this_year <- ifelse(
        THIS_EW>=40, 
        substr(THIS_SEASON, 0, 4),
        substr(THIS_SEASON, 5, 9))
    this_week_name <- paste0("EW", THIS_EW, "-", this_year)
    
    ## assemble files to stack
    files_to_stack <- paste0(
        "model-forecasts/real-time-component-models/",
        model_names$model.dir, "/",
        this_week_name, "-", model_names$model.dir, ".csv"
    )
    file_df <- data.frame(
        file = files_to_stack, 
        model_id = model_names$model.id,
        stringsAsFactors = FALSE)
    
    ## check files exist, modify weights if they don't
    if(!all(file.exists(files_to_stack))){
        warning(paste(sum(file.exists(files_to_stack)), "component files are missing."))

        ## id which files don't exist
        missing_model_ids <- file_df[!file.exists(file_df$file),"model_id"]
        
        ## remove those rows from wt_subset
        wt_subset <- dplyr::filter(
            wt_subset, 
            !(component_model_id %in% missing_model_ids)
            )
        
        ## standardize weights
        wt_subset <- wt_subset %>% 
            group_by_at(vars(weight_var_cols)) %>%
            mutate(weight = weight/sum(weight)) %>%
            ungroup()
        
        ## remove corresponding rows from file_df
        file_df <- dplyr::filter(file_df, !(model_id %in% missing_model_ids))
    }
    
    ## check that weights sum to 1 in proper groups
    tot_target_weights <- wt_subset %>%
        group_by_at(vars(weight_var_cols)) %>%
        summarize(total_weights = sum(weight)) 
    all_weights_sum_to_1 <- all.equal(
        tot_target_weights$total_weights, 
        rep(1, nrow(tot_target_weights))
    )
    if(!all_weights_sum_to_1)
        stop(paste("Not all model weights sum to 1 for", weight_file[j]))
    
    ## create, save ensemble file
    stacked_entry <- stack_forecasts(file_df, wt_subset)
    stacked_file_name <- paste0(
        "model-forecasts/real-time-ensemble-models/",
        stacked_name, "/", this_week_name, "-", stacked_name, ".csv"
    )
    if(file.exists(stacked_file_name))
        warning(paste("Ensemble file already exists. Overwriting", stacked_file_name))

    write.csv(stacked_entry, file=stacked_file_name, 
        row.names = FALSE, quote = FALSE)
}
    