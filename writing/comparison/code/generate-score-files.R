## generate all score RDS files needed
## Nick Reich
## created: March 2018

library(dplyr)
library(readr)

scores <- read_csv("../../scores/scores.csv")
models <- read_csv("../../model-forecasts/component-models/model-id-map.csv")
complete_models <- c(models$`model-id`[models$complete=="true"], "UTAustin-edm")

## define column with scores of interest
SCORE_COL <- quo(`Multi bin score`)

## Create data.frame of boundary weeks of scores to keep for each target/season
all_target_bounds <- read_csv("data/all-target-bounds.csv")

## Remove scores that fall outside of evaluation period for a given target/season
scores_trimmed <- scores %>% 
    dplyr::left_join(all_target_bounds, by = c("Season", "Target", "Location")) %>%
    dplyr::filter(`Model Week` >= start_week_seq, `Model Week` <= end_week_seq)

## truncate lowest possible scores to -10, define target-type variable
scores_adj <- scores_trimmed %>%
    filter(Model %in% complete_models) %>%
    ## if NA, NaN or <-10, set score to -10
    mutate(score_adj = dplyr::if_else(is.nan(!!SCORE_COL) | is.na(!!SCORE_COL) , 
        -10, 
        !!SCORE_COL),
        target_type = dplyr::if_else(Target %in% c("Season onset", "Season peak week", "Season peak percentage"),
            "seasonal", "k-week-ahead")) %>%
    mutate(
        score_adj = dplyr::if_else(score_adj < -10 , -10, score_adj),
        Location = factor(Location, levels=c("US National", paste("HHS Region", 1:10)))
        ) 

scores_by_model_target <- scores_adj %>%
    group_by(Model, Target) %>%
    summarize(
        avg_score = mean(score_adj),
        skill = exp(avg_score),
        min_score = min(score_adj)
    ) %>%
    ungroup() %>%
    mutate(Model = reorder(Model, skill))
saveRDS(scores_by_model_target, file="./data/scores_by_model_target.rds")


scores_by_model_season <- scores_adj %>%
    group_by(Model, Season) %>%
    summarize(
        avg_score = mean(score_adj),
        skill = exp(avg_score),
        min_score = min(score_adj)
    ) %>%
    ungroup() %>%
    mutate(Model = reorder(Model, skill))
saveRDS(scores_by_model_season, file="./data/scores_by_model_season.rds")

scores_by_model_targettype <- scores_adj %>%
    group_by(Model, target_type) %>%
    summarize(
        avg_score = mean(score_adj),
        skill = exp(avg_score),
        min_score = min(score_adj)
    ) %>%
    ungroup() %>%
    mutate(Model = reorder(Model, skill))
saveRDS(scores_by_model_targettype, file="./data/scores_by_model_targettype.rds")

scores_by_model_season_target <- scores_adj %>%
    group_by(Model, Season, Target) %>%
    summarize(
        avg_score = mean(score_adj),
        skill = exp(avg_score),
        min_score = min(score_adj)
    ) %>%
    ungroup() %>%
    mutate(Model = reorder(Model, skill))
saveRDS(scores_by_model_season_target, file="./data/scores_by_model_season_target.rds")

scores_by_model_targettype_region <- scores_adj %>%
    group_by(Model, target_type, Location) %>%
    summarize(
        avg_score = mean(score_adj),
        skill = exp(avg_score),
        min_score = min(score_adj)
    ) %>%
    ungroup() %>%
    mutate(Model = reorder(Model, skill))
saveRDS(scores_by_model_targettype_region, file="./data/scores_by_model_targettype_region.rds")

scores_by_model_season_targettype_region <- scores_adj %>%
    group_by(Model, Season, target_type, Location) %>%
    summarize(
        avg_score = mean(score_adj),
        skill = exp(avg_score),
        min_score = min(score_adj)
    ) %>%
    ungroup() %>%
    mutate(Model = reorder(Model, skill))
saveRDS(scores_by_model_season_targettype_region, file="./data/scores_by_model_season_targettype_region.rds")

