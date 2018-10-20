### modeling forecast performance 

library(dplyr)
library(readr)
library(ggplot2)
library(mgcv)
theme_set(theme_minimal())


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


# OLD draft modeling code for gamma regressions etc... below
# ## first pass at a model
# 
# scores_1wk <- filter(scores_agg, Target=="1 wk ahead") %>%
#     mutate(mbscore_adj = abs(multi_bin_score)+.00001,
#         Model = relevel(factor(Model), ref = "ReichLab-KDE"))
# 
# a <- gam(mbscore_adj ~ factor(Season) + factor(Model) + factor(Location) + factor(model_week),
#     family=Gamma(link="log"), data=scores_1wk)
# 
# ## bring in recent incidence as predictor
# 
# scores_1wk$resid <- residuals(a, type="response")
# scores_1wk$pred <- predict(a, type="response")
# 
# ggplot(filter(scores_agg, Model%in%c("ReichLab-KCDE", "UTAustin-edm", "Delphi-DeltaDensity1", "CU-EKF_SEIRS")),
#     aes(x=model_week, y=skill, color=Season) ) +
#     geom_line() + scale_y_log10() + facet_grid(Model~Location) +
#     geom_line(aes(y=pred), color="black")
# 
# ggplot(filter(scores_1wk, Model%in%c("ReichLab-KCDE", "UTAustin-edm", "Delphi-DeltaDensity1", "CU-EKF_SEIRS")),
#     aes(x=model_week, y=resid, color=Season) ) +
#     geom_line() + facet_grid(Model~Location, scales = "free_y")
# 
# 
# scores_1wk %>% group_by(Model) %>%
#     summarize(min_resid = min(resid),
#         max_resid = max(resid),
#         mean_resid = mean(resid),
#         min_pred = min(pred),
#         mean_pred = mean(pred),
#         resid_acf1 = acf(resid,2, plot=FALSE)$acf[2],
#         resid_acf2 = acf(resid,2, plot=FALSE)$acf[3]) %>%
#     arrange(mean_pred) %>%
#     print(n=100)
