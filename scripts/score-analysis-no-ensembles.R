## score analysis with no ensembles

scores <- read_csv("../scores/scores.csv")
models <- read_csv("../model-forecasts/component-models/model-id-map.csv")
complete_models <- models$`model-id`[models$complete=="true"]

## define column with scores of interest
SCORE_COL <- quo(`Multi bin score`)

## Create data.frame of boundary weeks of scores to keep for each target/season
source("create-scoring-period.R")
all_target_bounds = create_scoring_period()

## Remove scores that fall outside of evaluation period for a given target/season
scores_trimmed <- scores %>%
    dplyr::left_join(all_target_bounds, by = c("Season", "Target", "Location")) %>%
    dplyr::filter(`Model Week` >= start_week_seq, `Model Week` <= end_week_seq)


scores_adj <- scores_trimmed %>%
    filter(Model %in% complete_models) %>%
    ## if NA, NaN or <-10, set score to -10
    mutate(score_adj = dplyr::if_else(is.nan(!!SCORE_COL) | is.na(!!SCORE_COL) , 
        -10, 
        !!SCORE_COL)) %>%
    mutate(score_adj = dplyr::if_else(score_adj < -10 , -10, score_adj)) 

scores_by_season <- scores_adj %>%
    group_by(Model, Season) %>%
    summarize(
        avg_score = mean(score_adj),
        min_score = min(score_adj)
    ) %>%
    ungroup() %>%
    mutate(Model = reorder(Model, avg_score))

scores_by_target <- scores_adj %>%
    group_by(Model, Target) %>%
    summarize(avg_score = mean(score_adj)) %>%
    ungroup() %>%
    mutate(Model = reorder(Model, avg_score))

scores_by_model <- scores_adj %>%
    group_by(Model) %>%
    summarize(
        avg_score = mean(score_adj),
        min_score = min(score_adj)) %>%
    ungroup() %>%
    mutate(Model = reorder(Model, avg_score))

scores_by_region <- scores_adj %>%
    group_by(Model, Location) %>%
    summarize(
        avg_score = mean(score_adj),
        min_score = min(score_adj)) %>%
    ungroup() %>%
    mutate(Model = reorder(Model, avg_score))

scores_by_target_region <- scores_adj %>%
    group_by(Model, Target, Location) %>%
    summarize(
        avg_score = mean(score_adj),
        min_score = min(score_adj)) %>%
    ungroup() %>%
    mutate(Model = reorder(Model, avg_score))

scores_by_target_season <- scores_adj %>%
    group_by(Model, Target, Season) %>%
    summarize(
        avg_score = mean(score_adj),
        min_score = min(score_adj)) %>%
    ungroup() %>%
    mutate(Model = reorder(Model, avg_score))

scores_by_target_season_region <- scores_adj %>%
    group_by(Model, Target, Season, Location) %>%
    summarize(
        avg_score = mean(score_adj),
        min_score = min(score_adj)) %>%
    ungroup() %>%
    mutate(Model = reorder(Model, avg_score))

scores_by_week_season <- scores_adj %>%
    group_by(Model, Target, Season, `Model Week`) %>%
    summarize(
        avg_score = mean(score_adj),
        min_score = min(score_adj)) %>%
    ungroup() %>%
    mutate(Model = reorder(Model, avg_score))

scores_by_week <- scores_adj %>%
    group_by(Model, Target, `Model Week`) %>%
    summarize(
        avg_score = mean(score_adj),
        min_score = min(score_adj)) %>%
    ungroup() %>%
    mutate(Model = reorder(Model, avg_score))

## by season
midpt <- mean(filter(scores_by_season, Model=="ReichLab-KDE")$avg_score)
ggplot(scores_by_season, 
    aes(x=Season, fill=avg_score, y=Model)) + 
    geom_tile() + ylab(NULL) + xlab(NULL) +
    geom_text(aes(label=round(avg_score, 2))) +
    scale_fill_gradient2(midpoint = midpt) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
    ggtitle("Average model scores by season")

## by model
midpt <- mean(filter(scores_by_model, Model=="ReichLab-KDE")$avg_score)
ggplot(scores_by_model, 
    aes(x=1, fill=avg_score, y=Model)) + 
    geom_tile() + ylab(NULL) + xlab(NULL) +
    geom_text(aes(label=round(avg_score, 2))) +
    scale_fill_gradient2(midpoint = midpt) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
    ggtitle("Model scores across all seasons")

## by target
midpt <- mean(exp(filter(scores_by_target, Model=="ReichLab-KDE")$avg_score))
ggplot(scores_by_target, 
    aes(x=Target, fill=exp(avg_score), y=Model)) + 
    geom_tile() + ylab(NULL) + xlab(NULL) +
    geom_text(aes(label=round(exp(avg_score), 2))) +
    scale_fill_gradient2(midpoint = midpt, name="forecast skill") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
    ggtitle("Average model performance by target")

## by model, highlight mechanistic models
mech_models <- c(
    paste0("CU-", c("EAKFC_SEIRS", "EAKFC_SIRS", "EKF_SEIRS", "EKF_SIRS", "RHF_SEIRS", "RHF_SIRS")),
    "LANL-DBM")
ggplot(scores_by_model, aes(x=Model, y=exp(avg_score))) +
    #geom_point(alpha=.5, aes(color=Season)) + 
    geom_point(data=scores_by_model, shape="x", size=1, stroke=5)+
    scale_color_brewer(palette="Dark2") +
    ylab("forecast skill") +
    theme(axis.text.x = element_text(
        angle = 90, hjust = 1, vjust = .5,
        color=ifelse(
            levels(scores_by_model$Model)%in% mech_models,
            "red", 
            "black"
        ))
    ) +
    ggtitle("Average performance across all seasons, targets, and weeks")

