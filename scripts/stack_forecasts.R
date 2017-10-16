#' Create stacked model from entry files and weights
#'
#' @param files a data.frame specifying filenames (columnname "file") and model_ids of entry files
#' @param stacking_weights weights data.frame, see details.
#'
#' @details The `stacking_weights` argument takes a data.frame that 
#' contains structured information about how to weight the component model
#' entries passed in by the `files` argument.
#' Each stacking_weights data.frame  is mandated to have the following two columns:
#'    - component_model_id: a unique string for model ID
#'    - weight: the weight
#'  And the file may have the following columns:
#'    - target: these should be in the same format as expected in an entry file
#'    - location: again, same format as entry file
#'  If the file doesn't have one or both of these columns, 
#'  then we assume them to be the same across all targets or all locations.
#'  The following checks will be performed:
#'    - the component_model_id must match strings in the filenames
#'    - for a fixed target (t) and location (l) (if specified) 
#'      $\sum_{i=i}^M weights_{i, t, l} = 1$. 
#'
#' @return a data_frame with the stacked entry
#' @export
#'
stack_forecasts <- function(files, stacking_weights) {
    require(dplyr)
    require(FluSight)
    nfiles <- nrow(files)
    
    ## retrieve expected model names from stacking_weights matrix
    model_names <- unique(stacking_weights$component_model_id)
    if(nfiles != length(model_names))
        stop("number of model_ids in weight matrix does not equal number of files")
    
    ## check that model weights sum to 1 for fixed target/location
    if("target" %in% colnames(stacking_weights)) {
        if("location" %in% colnames(stacking_weights)) {
            weight_sums <- stacking_weights %>% group_by(target, location) %>% 
                summarize(sum_weight=sum(weight)) %>% .$sum_weight
        } else {
            weight_sums <- stacking_weights %>% group_by(target) %>% 
                summarize(sum_weight=sum(weight)) %>% .$sum_weight
        }
    } else if("location" %in% colnames(stacking_weights)) {
        weight_sums <- stacking_weights %>% group_by(location) %>% 
            summarize(sum_weight=sum(weight)) %>% .$sum_weight
    } else {
            weight_sums <- stacking_weights %>% 
                summarize(sum_weight=sum(weight)) %>% .$sum_weight
    }
    if(!isTRUE(all.equal(weight_sums, rep(1, length(weight_sums)))))
        stop("weights don't sum to 1.")
        
    ## check that files are entries
    entries <- vector("list", nfiles)
    for(i in 1:nfiles) {
        entries[[i]] <- read_entry(files$file[i]) 
        verify_entry(entries[[i]])
    }
    
    ## stack distributions
    for(i in 1:length(entries)){
        entries[[i]] <- entries[[i]] %>%
            ## add column with component_model_id
            mutate(component_model_id = files$model_id[i]) %>%
            ## add weights column
            left_join(stacking_weights) 
        ## rename value column
        new_value_name <- paste0(files$model_id[i], "_value")
        entries[[i]][new_value_name] <- with(entries[[i]], value)
        ## rename weight column
        new_wt_name <- paste0(files$model_id[i], "_weight")
        entries[[i]][new_wt_name] <- with(entries[[i]], weight)
        ## add weighted value column
        new_wtvalue_name <- paste0(files$model_id[i], "_weighted_value")
        entries[[i]][new_wtvalue_name] <- with(entries[[i]], weight * value)
    }
    ## drop unneeded columns
    unneeded_columns <- c("component_model_id", "value", "weight")
    slim_entries <- lapply(entries, function(x) x[!(names(x) %in% unneeded_columns)])
    ensemble_entry <- Reduce(
        f = left_join, 
        x = slim_entries) %>% 
        as_data_frame %>%
        mutate(value = rowSums(.[grep("weighted_value", names(.))], na.rm = TRUE)) %>%
        select(-contains("_value")) %>%
        select(-contains("_weight")) %>%
        select(-c(forecast_week))
    return(ensemble_entry)
}
