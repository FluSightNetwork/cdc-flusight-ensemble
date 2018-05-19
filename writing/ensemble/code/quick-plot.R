## 2017-2018 score analysis

library(ggplot2)
library(readr)
library(dplyr)
theme_set(theme_minimal())

load("writing/ensemble/scores/AllScoreFiles_1718.Rdata")
specify_decimal <- function(x, k=0) trimws(format(round(x, k), nsmall=k))


scores_aggr_by_target <- eval_scores_1718 %>%
    group_by(team, target) %>%
    summarize(
        avg_score = mean(score),
        skill = exp(avg_score)
    ) %>%
    ungroup() %>%
    mutate(Model = reorder(team, avg_score)) %>%
    ## compute % diff relative to KDE
    group_by(target) %>%
    mutate(
        baseline_score = avg_score[Model=="ReichLab_kde"]
    ) %>%
    ungroup() %>%
    mutate(
        baseline_skill = exp(baseline_score),
        pct_diff_baseline_skill = (skill - baseline_skill)/baseline_skill
        )

ggplot(scores_aggr_by_target, aes(x=target, y=Model, fill=pct_diff_baseline_skill)) +
    geom_tile() + ylab(NULL) + xlab(NULL) +
    geom_text(aes(label=specify_decimal(skill, 2))) +
    scale_fill_gradient2(name = "% change \nfrom baseline") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
    ggtitle("Average model scores by target, 2017-2018")


## overall season plot

SCORE_COL <- quo(`Multi bin score`)
compartment_models <- c("CU-EAKFC_SEIRS", "CU-EAKFC_SIRS", "CU-EKF_SEIRS", 
    "CU-EKF_SIRS", "CU-RHF_SEIRS", "CU-RHF_SIRS", "LANL-DBM")
FSN_labels <- c("EW", "CW", "TTW", "TW", "TRW")
FSN_levels <- paste0("FSNetwork-", FSN_labels)


name_disambig <- read.csv("tmp.csv")

scores <- read_csv("scores/scores.csv")
## Create data.frame of boundary weeks of scores to keep for each target/season
all_target_bounds <- read_csv("writing/comparison/data/all-target-bounds.csv")

## Remove scores that fall outside of evaluation period for a given target/season
scores_trimmed <- scores %>% 
    dplyr::left_join(all_target_bounds, by = c("Season", "Target", "Location")) %>%
    dplyr::filter(`Model Week` >= start_week_seq, `Model Week` <= end_week_seq)

scores_adj <- scores_trimmed %>%
    ## if NA, NaN or <-10, set score to -10
    mutate(score_adj = dplyr::if_else(is.nan(!!SCORE_COL) | is.na(!!SCORE_COL) , 
        -10, 
        !!SCORE_COL),
        target_type = dplyr::if_else(Target %in% c("Season onset", "Season peak week", "Season peak percentage"),
            "seasonal", "k-week-ahead")) %>%
    mutate(
        score_adj = dplyr::if_else(score_adj < -10 , -10, score_adj),
        Location = factor(Location, levels=c("US National", paste("HHS Region", 1:10))),
        model_type = ifelse(Model %in% compartment_models, "compartment_model", "stat_model"),
        stat_model = ifelse(Model %in% compartment_models, 0, 1)
    ) 

scores_by_model <- scores_adj %>%
    group_by(Model) %>%
    summarize(
        avg_logscore = mean(score_adj)
    ) %>%
    ungroup() %>%
    mutate(Model = reorder(Model, avg_logscore))

scores_by_model_season <- scores_adj %>%
    group_by(Model, Season) %>%
    summarize(
        avg_logscore = mean(score_adj)
    ) %>%
    ungroup() %>%
    mutate(Model = reorder(Model, avg_logscore))

scores_aggr_1718 <- eval_scores_1718 %>%
    group_by(team) %>%
    summarize(avg_logscore = mean(score)) %>%
    ungroup() %>%
    rename(folder_name = team) %>%
    left_join(name_disambig) %>%
    filter(Model != "UTAustin-edm")

ggplot(scores_by_model_season, aes(x=Model, y=exp(avg_logscore))) +
    geom_point(alpha=.5, aes(color=Season)) + 
    geom_point(data=scores_by_model, shape="x", size=1, stroke=5)+
    geom_point(data=scores_aggr_1718, color="black")+
    scale_color_brewer(palette="Dark2") +
    ylab("forecast skill") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5, 
    color = ifelse(
            levels(scores_by_model_season$Model)%in% FSN_levels,
            "red", 
            "black"
        )
        )
    )


