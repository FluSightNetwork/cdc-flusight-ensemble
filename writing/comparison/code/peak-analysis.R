## figure for region-season peak vs. peak intensity forecast accuracy

## Modified by ELR 2018-05-18:
## separate analysis for Season peak percentage and season peak week
## starts on line 67

library(dplyr)
library(readr)
library(ggplot2)
theme_set(theme_minimal())


scores <- read_csv("../../scores/scores.csv")
models <- read_csv("../../model-forecasts/component-models/model-id-map.csv")
truths <- read_csv("../../scores/target-multivals.csv") %>% 
    filter(Target %in% c("Season peak percentage", "Season peak week")) %>%
    rename(peak_bin = `Valid Bin_start_incl`) 

truths_summary <- truths %>%
    filter(`Model Week` == 40) %>% select(-`Model Week`, -`Calendar Week`, -Year, -Season) %>%
    group_by(Location) %>%
    mutate(mean_peak_bin = mean(peak_bin), sd_peak_bin=sd(peak_bin)) %>%
    ungroup() %>% select(-peak_bin)

truths_all <- truths %>% left_join(truths_summary) %>%
    mutate(peak_bin_zscore = (peak_bin - mean_peak_bin)/sd_peak_bin)

complete_models <- c(models$`model-id`[models$complete=="true"], "UTAustin-edm")

## define column with scores of interest
SCORE_COL <- quo(`Multi bin score`)

all_target_bounds <- read_csv("data/all-target-bounds.csv")

## Remove scores that fall outside of evaluation period for a given target/season
scores_trimmed <- scores %>%
    dplyr::left_join(all_target_bounds, by = c("Season", "Target", "Location")) %>%
    dplyr::filter(`Model Week` >= start_week_seq, `Model Week` <= end_week_seq)


scores_adj <- scores_trimmed %>%
    filter(Model %in% complete_models, Target == "Season peak percentage") %>%
    ## if NA, NaN or <-10, set score to -10
    mutate(score_adj = dplyr::if_else(is.nan(!!SCORE_COL) | is.na(!!SCORE_COL) , 
        -10, 
        !!SCORE_COL)) %>%
    mutate(score_adj = dplyr::if_else(score_adj < -10 , -10, score_adj)) 

scores_by_region_season <- scores_adj %>%
    group_by(Model, Location, Season) %>%
    summarize(
        avg_score = mean(score_adj),
        skill = exp(avg_score)
    ) %>%
    ungroup() %>%
    mutate(
        Model = reorder(Model, skill),
        Location = factor(Location, levels=c("US National", paste("HHS Region", 1:10)))) %>%
    #filter(Model %in% c("ReichLab-KCDE", "LANL-DBM", "Delphi-DeltaDensity1", "CU-EKF_SIRS")) %>%
    left_join(truths_all)

ggplot(scores_by_region_season, aes(x=peak_bin_zscore, y=skill)) + 
    geom_point(aes(color=Season)) + geom_smooth() 



# Start code for separate analysis for season peak percentage
# first with just 4 best models, then again with all models

truths <- read_csv("../../scores/target-multivals.csv") %>% 
  filter(Target %in% c("Season peak percentage")) %>%
  rename(peak_bin = `Valid Bin_start_incl`)

truths_summary <- truths %>%
  filter(`Model Week` == 40) %>% select(-`Model Week`, -`Calendar Week`, -Year, -Season) %>%
  group_by(Location) %>%
  mutate(mean_peak_bin = mean(peak_bin), sd_peak_bin=sd(peak_bin)) %>%
  ungroup() %>% select(-peak_bin)

truths_all <- truths %>% left_join(truths_summary) %>%
  mutate(peak_bin_zscore = (peak_bin - mean_peak_bin)/sd_peak_bin)

complete_models <- c(models$`model-id`[models$complete=="true"], "UTAustin-edm")

## define column with scores of interest
SCORE_COL <- quo(`Multi bin score`)

all_target_bounds <- read_csv("data/all-target-bounds.csv")

## Remove scores that fall outside of evaluation period for a given target/season
scores_trimmed <- scores %>%
  dplyr::left_join(all_target_bounds, by = c("Season", "Target", "Location")) %>%
  dplyr::filter(`Model Week` >= start_week_seq, `Model Week` <= end_week_seq)


scores_adj <- scores_trimmed %>%
  filter(Model %in% complete_models, Target == "Season peak percentage") %>%
  ## if NA, NaN or <-10, set score to -10
  mutate(score_adj = dplyr::if_else(is.nan(!!SCORE_COL) | is.na(!!SCORE_COL) , 
                                    -10, 
                                    !!SCORE_COL)) %>%
  mutate(score_adj = dplyr::if_else(score_adj < -10 , -10, score_adj)) 

scores_by_region_season <- scores_adj %>%
  group_by(Model, Location, Season) %>%
  summarize(
    avg_score = mean(score_adj),
    skill = exp(avg_score)
  ) %>%
  ungroup() %>%
  mutate(
    Model = reorder(Model, skill),
    Location = factor(Location, levels=c("US National", paste("HHS Region", 1:10)))) %>%
  filter(Model %in% c("ReichLab-KCDE", "LANL-DBM", "Delphi-DeltaDensity1", "CU-EKF_SIRS")) %>%
  left_join(truths_all %>% select(-c(`Calendar Week`, `Model Week`)) %>% distinct() %>% filter(Target == "Season peak percentage"))

ggplot(scores_by_region_season, aes(x=peak_bin_zscore, y=skill)) + 
  geom_point(aes(color=Season)) +
  geom_smooth() +
  ggtitle("Peak Bin Z Score vs skill",
          subtitle = "Season Peak Percentage, 4 models, loess smooth")

ggplot(scores_by_region_season, aes(x=peak_bin_zscore, y=skill)) + 
  geom_point(aes(color=Season)) +
  geom_smooth(method = "lm", formula = y ~ poly(x, 2)) +
  ggtitle("Peak Bin Z Score vs skill",
          subtitle = "Season Peak Percentage, 4 models, quadratic lm smooth")

lm(skill ~ poly(peak_bin_zscore, 2), data = scores_by_region_season) %>% summary()


scores_by_region_season <- scores_adj %>%
  group_by(Model, Location, Season) %>%
  summarize(
    avg_score = mean(score_adj),
    skill = exp(avg_score)
  ) %>%
  ungroup() %>%
  mutate(
    Model = reorder(Model, skill),
    Location = factor(Location, levels=c("US National", paste("HHS Region", 1:10)))) %>%
  #filter(Model %in% c("ReichLab-KCDE", "LANL-DBM", "Delphi-DeltaDensity1", "CU-EKF_SIRS")) %>%
  left_join(truths_all %>% select(-c(`Calendar Week`, `Model Week`)) %>% distinct() %>% filter(Target == "Season peak percentage"))

ggplot(scores_by_region_season, aes(x=peak_bin_zscore, y=skill)) + 
  geom_point(aes(color=Season)) +
  geom_smooth() +
  ggtitle("Peak Bin Z Score vs skill",
          subtitle = "Season Peak Percentage, all models, loess smooth")

ggplot(scores_by_region_season, aes(x=peak_bin_zscore, y=skill)) + 
  geom_point(aes(color=Season)) +
  geom_smooth(method = "lm", formula = y ~ poly(x, 2)) +
  ggtitle("Peak Bin Z Score vs skill",
          subtitle = "Season Peak Percentage, all models, quadratic lm smooth")

lm(skill ~ poly(peak_bin_zscore, 2), data = scores_by_region_season) %>% summary()



# Start code for separate analysis for season peak week
# first with just 4 best models, then again with all models

truths <- read_csv("../../scores/target-multivals.csv") %>% 
  filter(Target %in% c("Season peak week")) %>%
  rename(peak_bin = `Valid Bin_start_incl`)

truths_summary <- truths %>%
  filter(`Model Week` == 40) %>% select(-`Model Week`, -`Calendar Week`, -Year, -Season) %>%
  group_by(Location) %>%
  mutate(mean_peak_bin = mean(peak_bin), sd_peak_bin=sd(peak_bin)) %>%
  ungroup() %>% select(-peak_bin)

truths_all <- truths %>% left_join(truths_summary) %>%
  mutate(peak_bin_zscore = (peak_bin - mean_peak_bin)/sd_peak_bin)

complete_models <- c(models$`model-id`[models$complete=="true"], "UTAustin-edm")

## define column with scores of interest
SCORE_COL <- quo(`Multi bin score`)

all_target_bounds <- read_csv("data/all-target-bounds.csv")

## Remove scores that fall outside of evaluation period for a given target/season
scores_trimmed <- scores %>%
  dplyr::left_join(all_target_bounds, by = c("Season", "Target", "Location")) %>%
  dplyr::filter(`Model Week` >= start_week_seq, `Model Week` <= end_week_seq)


scores_adj <- scores_trimmed %>%
  filter(Model %in% complete_models, Target == "Season peak week") %>%
  ## if NA, NaN or <-10, set score to -10
  mutate(score_adj = dplyr::if_else(is.nan(!!SCORE_COL) | is.na(!!SCORE_COL) , 
                                    -10, 
                                    !!SCORE_COL)) %>%
  mutate(score_adj = dplyr::if_else(score_adj < -10 , -10, score_adj)) 

scores_by_region_season <- scores_adj %>%
  group_by(Model, Location, Season) %>%
  summarize(
    avg_score = mean(score_adj),
    skill = exp(avg_score)
  ) %>%
  ungroup() %>%
  mutate(
    Model = reorder(Model, skill),
    Location = factor(Location, levels=c("US National", paste("HHS Region", 1:10)))) %>%
  filter(Model %in% c("ReichLab-KCDE", "LANL-DBM", "Delphi-DeltaDensity1", "CU-EKF_SIRS")) %>%
  left_join(truths_all %>% select(-c(`Calendar Week`, `Model Week`)) %>% distinct() %>% filter(Target == "Season peak week"))

ggplot(scores_by_region_season, aes(x=peak_bin_zscore, y=skill)) + 
  geom_point(aes(color=Season)) +
  geom_smooth() +
  ggtitle("Peak Bin Z Score vs skill",
          subtitle = "Season Peak week, 4 models, loess smooth")

ggplot(scores_by_region_season, aes(x=peak_bin_zscore, y=skill)) + 
  geom_point(aes(color=Season)) +
  geom_smooth(method = "lm", formula = y ~ poly(x, 2)) +
  ggtitle("Peak Bin Z Score vs skill",
          subtitle = "Season Peak week, 4 models, quadratic lm smooth")

lm(skill ~ poly(peak_bin_zscore, 2), data = scores_by_region_season) %>% summary()


scores_by_region_season <- scores_adj %>%
  group_by(Model, Location, Season) %>%
  summarize(
    avg_score = mean(score_adj),
    skill = exp(avg_score)
  ) %>%
  ungroup() %>%
  mutate(
    Model = reorder(Model, skill),
    Location = factor(Location, levels=c("US National", paste("HHS Region", 1:10)))) %>%
  #filter(Model %in% c("ReichLab-KCDE", "LANL-DBM", "Delphi-DeltaDensity1", "CU-EKF_SIRS")) %>%
  left_join(truths_all %>% select(-c(`Calendar Week`, `Model Week`)) %>% distinct() %>% filter(Target == "Season peak week"))

ggplot(scores_by_region_season, aes(x=peak_bin_zscore, y=skill)) + 
  geom_point(aes(color=Season)) +
  geom_smooth() +
  ggtitle("Peak Bin Z Score vs skill",
          subtitle = "Season Peak week, all models, loess smooth")

ggplot(scores_by_region_season, aes(x=peak_bin_zscore, y=skill)) + 
  geom_point(aes(color=Season)) +
  geom_smooth(method = "lm", formula = y ~ poly(x, 2)) +
  ggtitle("Peak Bin Z Score vs skill",
          subtitle = "Season Peak week, all models, quadratic lm smooth")

lm(skill ~ poly(peak_bin_zscore, 2), data = scores_by_region_season) %>% summary()
