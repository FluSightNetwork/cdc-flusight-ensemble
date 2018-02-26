## scatterplot with models on x-axis, skill on y

library(dplyr)
library(readr)
library(ggplot2)
theme_set(theme_minimal())

scores <- read_csv("../../scores/scores.csv")
models <- read_csv("../../model-forecasts/component-models/model-id-map.csv")
complete_models <- c(models$`model-id`[models$complete=="true"], "UTAustin-edm")

compartment_models <- c("CU-EAKFC_SEIRS", "CU-EAKFC_SIRS", "CU-EKF_SEIRS", 
    "CU-EKF_SIRS", "CU-RHF_SEIRS", "CU-RHF_SIRS", "LANL-DBM")

## define column with scores of interest
SCORE_COL <- quo(`Multi bin score`)

all_target_bounds <- read_csv("data/all-target-bounds.csv")

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
        skill = exp(avg_score),
        min_score = min(score_adj)
    ) %>%
    ungroup() %>%
    mutate(Model = reorder(Model, avg_score))
scores_by_model <- scores_adj %>%
    group_by(Model) %>%
    summarize(
        avg_score = mean(score_adj),
        skill = exp(avg_score),
        min_score = min(score_adj)) %>%
    ungroup() %>%
    mutate(Model = reorder(Model, avg_score))

p <- ggplot(scores_by_season, aes(x=Model, y=skill)) +
    geom_point(alpha=.5, aes(color=Season)) + 
    geom_point(data=scores_by_model, shape="x", size=1, stroke=5)+
    scale_color_brewer(palette="Dark2") +
    ylab("average forecast skill") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5,
        face=ifelse(
            levels(scores_by_season$Model)%in% compartment_models,
            "bold", 
            "plain"
        ))) 

ggsave("./figures/fig-results-model-season.pdf", plot=p, device="pdf", width=8, height=5.5)
saveRDS(scores_by_model, file="./data/scores_by_model.rds")
saveRDS(scores_by_season, file="./data/scores_by_season.rds")