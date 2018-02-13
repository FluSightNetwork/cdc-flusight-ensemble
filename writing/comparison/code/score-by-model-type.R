### modeling forecast performance 

library(dplyr)
library(readr)
library(xtable)

scores <- read_csv("../../scores/scores.csv")
models <- read_csv("../../model-forecasts/component-models/model-id-map.csv")
complete_models <- c(models$`model-id`[models$complete=="true"], "UTAustin-edm")

compartment_models <- c("CU-EAKFC_SEIRS", "CU-EAKFC_SIRS", "CU-EKF_SEIRS", 
    "CU-EKF_SIRS", "CU-RHF_SEIRS", "CU-RHF_SIRS", "LANL-DBM")

all_target_bounds <- read_csv("data/all-target-bounds.csv")

## define column with scores of interest
SCORE_COL <- quo(`Multi bin score`)

## categorize scores in three bins: 
##    100% prob to truth
##      0% prob to truth
##      something in the middle
##  average score when not 0/100
##  average score for week 52 (by target/location)


## removing scores that fall outside of evaluation period for a given target/season
scores_agg <- scores %>%
    filter(Model %in% complete_models) %>%
    dplyr::left_join(all_target_bounds, by = c("Season", "Target", "Location")) %>%
    dplyr::filter(`Model Week` >= start_week_seq, `Model Week` <= end_week_seq) %>%
    rename(multi_bin_score = `Multi bin score`,
        model_week = `Model Week`) %>%
    group_by(Model, Target, Season, Location) %>%
    summarize(mbscore_avg = mean(multi_bin_score)) %>%
    ungroup() %>%
    mutate(skill = exp(mbscore_avg),
        model_type = ifelse(Model %in% compartment_models, "compartment_model", "stat_model"),
        stat_model = ifelse(Model %in% compartment_models, 0, 1))

## filter out top three stat and top three compartmental models
top_models <- scores_agg %>%
    group_by(Model) %>%
    summarize(skill = exp(mean(mbscore_avg))) %>%
    arrange(desc(skill)) %>%
    mutate(model_type = ifelse(Model %in% compartment_models, "compartment_model", "stat_model"),
        stat_model = ifelse(Model %in% compartment_models, 0, 1)) %>%
    group_by(stat_model) %>%
    mutate(rank = row_number()) %>%
    ungroup() %>%
    filter(rank <= 3) %>% .$Model

scores_by_modeltype <- scores_agg %>%
    filter(Model %in% top_models) %>%
    group_by(Target) %>%
    summarize(
        stat_model_skill = sum(stat_model *skill)/sum(stat_model),
        compartment_model_skill = sum((1-stat_model) *skill)/sum((1-stat_model)),
        diff_model_skill = stat_model_skill - compartment_model_skill
    )
colnames(scores_by_modeltype) <- c("target", "stat. model skill", "compartment model skill", "difference")

caption_text <- paste0("Comparison of the top three statistical models (",
    paste(sanitize(top_models[!(top_models%in%compartment_models)]), collapse=", "),
    ") and the top three compartmental models, (",
    paste(sanitize(top_models[top_models%in%compartment_models]), collapse=", "),
    ") based on best average region-season forecast skill. The difference column represents the difference in the average probability assigned to the eventual outcome for the target in each row. Positive values indicate the top statistical models showed more average skill than the compartmental models.")

print(
    xtable(scores_by_modeltype,
        caption=caption_text, 
        label = "tab:score-by-model-type"), 
    file="./static-figures/score-by-model-type.tex",
    include.rownames = FALSE
    )
