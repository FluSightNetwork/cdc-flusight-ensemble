library(dplyr)
library(readr)
library(broom)
library(ggplot2)
library(fiftystater)
library(MMWRweek)
library(xtable)
library(cdcfluview)
library(mapproj)
library(gridExtra)

theme_set(theme_minimal())
specify_decimal <- function(x, k=0) trimws(format(round(x, k), nsmall=k))

scores <- read_csv("../../scores/scores.csv")
models <- read_csv("../../model-forecasts/component-models/model-id-map.csv")
targets <- read_csv("../../scores/target-multivals.csv")

complete_models <- c(models$`model-id`[models$complete=="true"], "UTAustin-edm")
compartment_models <- c("CU-EAKFC_SEIRS", "CU-EAKFC_SIRS", "CU-EKF_SEIRS", 
                        "CU-EKF_SIRS", "CU-RHF_SEIRS", "CU-RHF_SIRS", "LANL-DBM")


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

scores_by_model_target <- scores_adj %>%
  group_by(Model, Target) %>%
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

scores_by_model_targettype <- scores_adj %>%
  group_by(Model, target_type) %>%
  summarize(
    avg_logscore = mean(score_adj)
  ) %>%
  ungroup() %>%
  mutate(Model = reorder(Model, avg_logscore))

scores_by_model_region <- scores_adj %>%
  group_by(Model, Location) %>%
  summarize(
    avg_logscore = mean(score_adj)
  ) %>%
  ungroup() %>%
  mutate(Model = reorder(Model, avg_logscore))

scores_by_model_season_target <- scores_adj %>%
  group_by(Model, Season, Target) %>%
  summarize(
    avg_logscore = mean(score_adj)
  ) %>%
  ungroup() %>%
  mutate(Model = reorder(Model, avg_logscore))

scores_by_model_season_target_region <- scores_adj %>%
  group_by(Model, Season, Target, Location) %>%
  summarize(
    avg_logscore = mean(score_adj)
  ) %>%
  ungroup() %>%
  mutate(Model = reorder(Model, avg_logscore))

scores_by_model_targettype_region <- scores_adj %>%
  group_by(Model, target_type, Location) %>%
  summarize(
    avg_logscore = mean(score_adj)
  ) %>%
  ungroup() %>%
  mutate(Model = reorder(Model, avg_logscore))

scores_by_model_season_targettype_region <- scores_adj %>%
  group_by(Model, Season, target_type, Location) %>%
  summarize(
    avg_logscore = mean(score_adj)
  ) %>%
  ungroup() %>%
  mutate(Model = reorder(Model, avg_logscore))

scores_by_region <- scores_adj %>%
  group_by(Location) %>%
  summarize(
    avg_logscore = mean(score_adj)
  ) %>%
  ungroup() %>%
  mutate(Location = reorder(Location, avg_logscore))

scores_by_season <- scores_adj %>%
  group_by(Season) %>%
  summarize(
    avg_logscore = mean(score_adj)
  ) %>%
  ungroup() %>%
  mutate(Season = reorder(Season, avg_logscore))

scores_by_region_targettype <- scores_adj %>%
  group_by(Location, target_type) %>%
  summarize(
    avg_logscore = mean(score_adj)
  ) %>%
  ungroup() %>%
  mutate(Location = reorder(Location, avg_logscore))


dat <- read_csv("./data/truth-with-lags.csv")
scores <- read_csv("../../scores/scores.csv")

region_map <- data.frame(
  region = c("nat", "hhs1", "hhs2", "hhs3", "hhs4", "hhs5", "hhs6", "hhs7", "hhs8", "hhs9", "hhs10"),
  Location = c("US National", "HHS Region 1", "HHS Region 2", "HHS Region 3", "HHS Region 4",
               "HHS Region 5", "HHS Region 6", "HHS Region 7", "HHS Region 8", "HHS Region 9", "HHS Region 10"),
  stringsAsFactors = FALSE
)

lagged_truth <- dat %>% 
  mutate(
    epiweek_char = as.character(epiweek),
    year = as.numeric(substr(epiweek_char, 1, 4)),
    epiweek = as.numeric(substr(epiweek_char, 5, 6)),
    Season = ifelse(epiweek>35, paste0(year, "/", year+1), paste0(year-1, "/", year)),
    bias_first_report = (`first-observed-wili` - `final-observed-wili`),
    abs_bias_first_report = abs(bias_first_report),
    bias_first_report_factor = relevel(cut(bias_first_report, seq(-3.5, 3.5, by=1)), ref="(-0.5,0.5]"),
    pct_bias_first_report = bias_first_report/`final-observed-wili`,
    abs_pct_bias_first_report = abs(pct_bias_first_report),
    abs_pct_bias_factor = cut(abs_pct_bias_first_report, c(seq(0, 1, by=.05), Inf)),
    pct_bias_factor = cut(pct_bias_first_report, c(-Inf, seq(-1, 1, by=.05), Inf))
  ) %>%
  left_join(region_map) %>%
  select(-region, epiweek_char)

# ## Exploratory plots
# ggplot(lagged_truth) +
#     geom_bar(aes(x=abs_pct_bias_factor)) + facet_wrap(~Location)
# 
# ggplot(lagged_truth) +
#     geom_histogram(aes(x=pct_bias_first_report)) + facet_wrap(~Location)
#     



scores_by_delay <- scores %>%
  select(-Year, -Epiweek) %>%
  filter(Target %in% paste(1:4, "wk ahead")) %>%
  mutate(
    multi_bin_score = `Multi bin score`,
    forecast_step = as.numeric(substr(Target, 1, 2)),
    forecasted_modelweek = `Model Week` + forecast_step,
    long_season = as.numeric(Season=="2014/2015"),
    forecasted_epiweek =  ifelse(forecasted_modelweek-long_season>52, ## if forecasted modelweek is in next calendar year
                                 forecasted_modelweek - 52 - long_season, ## subtract off 52 if in regular season, 53 if in long season
                                 forecasted_modelweek) ## return modelweek if 
  ) %>%
  left_join(lagged_truth, by=c("Season"="Season", "Location"="Location", "forecasted_epiweek" = "epiweek")) 


scores_for_analysis <- filter(scores_by_delay, Model%in%c("ReichLab-KCDE", "LANL-DBM", "Delphi-DeltaDensity1", "CU-EKF_SIRS"))


max_logscore_wkahead <- max(scores_by_model_targettype$avg_logscore[which(scores_by_model_targettype$target_type == "k-week-ahead")])
max_logscore_model_wkahead <- as.character(unlist(scores_by_model_targettype[which(scores_by_model_targettype$avg_logscore == max_logscore_wkahead), "Model"]))[1] ## adding [1] in case multiple models are returned

kde_logscore_wkahead <- unlist(scores_by_model_targettype[which(scores_by_model_targettype$Model=="ReichLab-KDE"& scores_by_model_targettype$target_type=="k-week-ahead"), "avg_logscore"])
n_above_kde_wkahead <- sum(scores_by_model_targettype$avg_logscore[which(scores_by_model_targettype$target_type=="k-week-ahead")]>kde_logscore_wkahead)

## Get models better than KDE for k-week-ahead
scores_wkahead_better_than_kde <- scores_by_model_targettype %>%
  filter(target_type=="k-week-ahead", avg_logscore>kde_logscore_wkahead)
models_wkahead_better_than_kde <- as.character(scores_wkahead_better_than_kde$Model)

## look at region-specific, k-week-ahead scores
scores_by_region_wkahead <- filter(scores_by_region_targettype, target_type=="k-week-ahead")
best_region_wkahead <- scores_by_region_wkahead$Location[which.max(scores_by_region_wkahead$avg_logscore)]
best_region_wkahead_skill <- exp(scores_by_region_wkahead$avg_logscore[which.max(scores_by_region_wkahead$avg_logscore)])
worst_region_wkahead <- scores_by_region_wkahead$Location[which.min(scores_by_region_wkahead$avg_logscore)]
worst_region_wkahead_skill <- exp(scores_by_region_wkahead$avg_logscore[which.min(scores_by_region_wkahead$avg_logscore)])

kde_kwkahead_worst_score <- scores_by_model_targettype_region %>% 
  filter(Model %in% "ReichLab-KDE", Location==worst_region_wkahead, target_type=="k-week-ahead") %>% 
  .$avg_logscore %>% exp()


kde_logscore_seasonal <- unlist(scores_by_model_targettype[which(scores_by_model_targettype$Model=="ReichLab-KDE"& scores_by_model_targettype$target_type=="seasonal"), "avg_logscore"])
n_above_kde_seasonal <- sum(scores_by_model_targettype$avg_logscore[which(scores_by_model_targettype$target_type=="seasonal")]>kde_logscore_seasonal)

## Get models better than KDE for k-week-ahead
scores_seasonal_better_than_kde <- scores_by_model_targettype %>%
  filter(target_type=="k-week-ahead", avg_logscore>kde_logscore_seasonal)
models_seasonal_better_than_kde <- as.character(scores_seasonal_better_than_kde$Model)

## look at region-specific, k-week-ahead scores
scores_by_region_seasonal <- filter(scores_by_region_targettype, target_type=="seasonal")
best_region_seasonal <- scores_by_region_seasonal$Location[which.max(scores_by_region_seasonal$avg_logscore)]
best_region_seasonal_skill <- exp(scores_by_region_seasonal$avg_logscore[which.max(scores_by_region_seasonal$avg_logscore)])
worst_region_seasonal <- scores_by_region_seasonal$Location[which.min(scores_by_region_seasonal$avg_logscore)]
worst_region_seasonal_skill <- exp(scores_by_region_seasonal$avg_logscore[which.min(scores_by_region_seasonal$avg_logscore)])

kde_kseasonal_worst_score <- scores_by_model_targettype_region %>% 
  filter(Model %in% "ReichLab-KDE", Location==worst_region_seasonal, target_type=="k-week-ahead") %>% 
  .$avg_logscore %>% exp()


## gather data needed for plots
data("fifty_states")
data(hhs_regions)

## aggreate scores by target type for models better than KDE
scores_for_map_wkahead <- scores_by_model_targettype_region %>% 
  filter(Location != "US National", Model %in% models_wkahead_better_than_kde, target_type=="k-week-ahead") %>%
  group_by(Location) %>%
  summarize(avg_logscore = mean(avg_logscore)) %>% 
  ungroup() %>%
  mutate(region_number = gsub("[^0-9]", "", Location))
scores_for_map_seasonal <- scores_by_model_targettype_region %>% 
  filter(Location != "US National", Model %in% models_seasonal_better_than_kde, target_type=="seasonal") %>%
  group_by(Location) %>%
  summarize(avg_logscore = mean(avg_logscore)) %>% 
  ungroup() %>%
  mutate(region_number = gsub("[^0-9]", "", Location))
not_50 <- c(9, 10, 12, 50:55)
hhs_regions <- hhs_regions[-(not_50),]
hhs_regions$state <- tolower(hhs_regions$state_or_territory)
skill_lims <- c(.1, .6)

## get KDE specific scores
kde_scores_wkahead <- scores_by_model_targettype_region %>%
  filter(Model %in% "ReichLab-KDE", target_type=="k-week-ahead", Location != "US National") %>%
  rename(kde_logscore = avg_logscore) %>% 
  left_join(scores_for_map_wkahead) %>%
  mutate(
    logscore_diff = avg_logscore - kde_logscore
  )

kde_scores_seasonal <- scores_by_model_targettype_region %>%
  filter(Model %in% "ReichLab-KDE", target_type=="seasonal", Location != "US National") %>%
  rename(kde_logscore = avg_logscore) %>% 
  left_join(scores_for_map_seasonal) %>%
  mutate(
    logscore_diff = avg_logscore - kde_logscore
  )


report_bias_vs_avg_score <- scores_for_analysis %>%
  group_by(Location) %>%
  count(bias_first_report_factor) %>%
  filter(!is.na(bias_first_report_factor)) %>%
  mutate(proportion = n / sum(n)) %>%
  filter(Location != "US National") %>%
  filter(bias_first_report_factor == "(-0.5,0.5]") %>%
  left_join(
    scores_for_map_wkahead %>% transmute(Location = as.character(Location), `Week Ahead` = avg_logscore),
    by = "Location") %>%
  left_join(
    scores_for_map_seasonal %>% transmute(Location = as.character(Location), Seasonal = avg_logscore),
    by = "Location") %>%
  tidyr::gather("target_type", "avg_logscore", `Week Ahead`, Seasonal)

ggplot(data = report_bias_vs_avg_score,
    mapping = aes(x = proportion, y = exp(avg_logscore))) +
  geom_point() +
  facet_wrap(~ target_type) +
  geom_smooth(method = "lm", formula = y ~ poly(x, 2)) +
  xlab("Proportion of Initial Reports with Bias in the Range (-0.5, 0.5]") +
  ggtitle(label = "Intial Reporting Bias and Average Prediction Accuracy",
    subtitle = "Each Point Summarizes One HHS Region")

ggplot(data = report_bias_vs_avg_score,
       mapping = aes(x = proportion, y = exp(avg_logscore))) +
  geom_point() +
  facet_wrap(~ target_type) +
  geom_smooth(method = "lm") +
  xlab("Proportion of Initial Reports with Bias in the Range (-0.5, 0.5]") +
  ggtitle(label = "Intial Reporting Bias and Average Prediction Accuracy",
          subtitle = "Each Point Summarizes One HHS Region")


ggplot(data = report_bias_vs_avg_score,
       mapping = aes(x = log(proportion), y = exp(avg_logscore))) +
  geom_point() +
  facet_wrap(~ target_type) +
  geom_smooth(method = "lm") +
  xlab("log(Proportion of Initial Reports with Bias in the Range (-0.5, 0.5])") +
  ggtitle(label = "Intial Reporting Bias and Average Prediction Accuracy",
          subtitle = "Each Point Summarizes One HHS Region")


ggplot(data = report_bias_vs_avg_score,
       mapping = aes(x = proportion, y = exp(avg_logscore))) +
  geom_point() +
  facet_wrap(~ target_type) +
  geom_smooth(method = "loess", span = 1.5, se = FALSE) +
  xlab("Proportion of Initial Reports with Bias in the Range (-0.5, 0.5]") +
  ggtitle(label = "Intial Reporting Bias and Average Prediction Accuracy",
          subtitle = "Each Point Summarizes One HHS Region")

ggplot(data = report_bias_vs_avg_score,
       mapping = aes(x = proportion, y = exp(avg_logscore))) +
  geom_point() +
  facet_wrap(~ target_type) +
  geom_smooth(method = "loess") +
  xlab("Proportion of Initial Reports with Bias in the Range (-0.5, 0.5]") +
  ggtitle(label = "Intial Reporting Bias and Average Prediction Accuracy",
          subtitle = "Each Point Summarizes One HHS Region")
