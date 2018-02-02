library(dplyr)
library(readr)
library(ggplot2)
theme_set(theme_minimal())


scores <- read_csv("../../scores/scores.csv")
models <- read_csv("../../model-forecasts/component-models/model-id-map.csv")
complete_models <- c(models$`model-id`[models$complete=="true"], "UTAustin-edm")

## define column with scores of interest
SCORE_COL <- quo(`Multi bin score`)

## Create data.frame of boundary weeks of scores to keep for each target/season
source("../../scripts/create-scoring-period.R")
all_target_bounds = create_scoring_period(
    baselinefile = "../../baselines/wILI_Baseline.csv",
    scoresfile = "../../scores/target-multivals.csv")

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

midpt <- mean(filter(scores_by_season, Model=="ReichLab-KDE")$skill)
p <- ggplot(scores_by_season, 
    aes(x=Season, fill=skill, y=Model)) + 
    geom_tile() + ylab(NULL) + xlab(NULL) +
    geom_text(aes(label=round(skill, 2))) +
    scale_fill_gradient2(midpoint = midpt) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
    ggtitle("Average forecast skill by season")

ggsave("./figures/fig-results-season.pdf", plot=p, device="pdf")