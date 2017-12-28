## script to generate real-time ensemble entry file
## Nicholas Reich
## created: November 2017

library(FluSight) ## devtools::install_github("jarad/FluSight")
library(dplyr)
library(gridExtra)
library(ggplot2)
theme_set(theme_minimal())

## Takes epiweek number as (first) command line argument
args <- commandArgs(TRUE)

source("scripts/stack_forecasts.R")

THIS_SEASON <- "2017/2018"
THIS_EW <- as.numeric(args[1])
cat(paste0("Generating ensemble files for week ", THIS_EW))

this_year <- ifelse(
    THIS_EW>=40,
    substr(THIS_SEASON, 0, 4),
    substr(THIS_SEASON, 5, 9))
this_week_name <- paste0("EW", THIS_EW, "-", this_year)

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
        warning(paste(
            length(files_to_stack) - sum(file.exists(files_to_stack)),
            "component files are missing.")
        )

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
    all_weights_sum_to_1 <- base::all.equal(
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

## move/rename submission file
ttw_file <- paste0(
    "model-forecasts/real-time-ensemble-models/target-type-based-weights/",
    this_week_name, "-", "target-type-based-weights.csv"
)
ttw_submission_file <- paste0(
    ## "model-forecasts/submissions/EW", THIS_EW, "-FSNetwork-", Sys.Date(), ".csv"
    ## Renaming the files to have week and year information in the start - Abhinav Tushar
    "model-forecasts/submissions/target-type-based-weights/EW", THIS_EW, "-2017-FSNetwork-", Sys.Date(), ".csv"
)

file.copy(ttw_file, ttw_submission_file)


## visualize the TTW submission
d <- read_entry(ttw_submission_file)

ttw_plots_name <- paste0(
    "model-forecasts/submissions/plots/", this_week_name, ".pdf"
)
pdf(ttw_plots_name, width = 12)
for(reg in unique(d$location)){
    p_onset <- plot_onset(d, region = reg) + ylim(0,1) +
        theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=.5, size=5))
    p_peakpct <- plot_peakper(d, region = reg) + ylim(0,1)
    p_peakwk <- plot_peakweek(d, region = reg) + ylim(0,1) +
        theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=.5, size=5))
    p_1wk <- plot_weekahead(d, region = reg, wk = 1, ilimax=13, years = 2017) + 
        ggtitle(paste(reg, ": 1 wk ahead")) + ylim(0,1)
    p_2wk <- plot_weekahead(d, region = reg, wk = 2, ilimax=13, years = 2017) + ylim(0,1)
    p_3wk <- plot_weekahead(d, region = reg, wk = 3, ilimax=13, years = 2017) + ylim(0,1)
    p_4wk <- plot_weekahead(d, region = reg, wk = 4, ilimax=13, years = 2017) + ylim(0,1)
    grid.arrange(p_1wk, p_2wk, p_3wk, p_4wk, p_onset, p_peakpct, p_peakwk, ncol=4)
}
dev.off()
