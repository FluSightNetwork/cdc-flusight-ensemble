library(tidyverse)
library(FluSight)
library(MMWRweek)
library(cdcfluview)
library(stringr)

# Download FluSight package from GitHub if necessary
# devtools::install_github("jarad/FluSight")

# Read in CSVs to list in R
source("read_forecasts.R")
subs_comp_1718 <- read_forecasts("../../../model-forecasts/real-time-component-models/")
subs_ens_1718 <- read_forecasts("../../../model-forecasts/real-time-ensemble-models/")

subs_1718 <- c(subs_comp_1718, subs_ens_1718)

# # Create observed truth to score entries against ------------------------------
ILI_1718 <- ilinet(region = "national", year = 2017) %>%
  mutate(location = "US National") %>%
  select(location, week, ILI = weighted_ili) %>%
  bind_rows(
    ilinet(region = "hhs", year = 2017) %>%
      mutate(location = paste("HHS", region)) %>%
      select(location, week, ILI = weighted_ili)
  ) %>%
  mutate(ILI = round(ILI, 1))

# # After week 28, use code below to create ILI values
# ILI_1718 <- read_csv("../ILINet/2017-2018/ILINet_US_wk28_2018.csv") %>%
#   mutate(location = "US National") %>%
#   select(location, week, ILI = weighted_ili) %>%
#   bind_rows(
#     read_csv("../ILINet/2017-2018/ILINet_Regional_wk28_2018.csv") %>%
#       mutate(location = paste("HHS", region)) %>%
#       select(location, week, ILI = weighted_ili)
#   ) %>%
#   mutate(ILI = round(ILI, 1))


# Create truth ----------------------------------------------------------------
truth_1718 <- create_truth(fluview = FALSE, year = 2017, weekILI = ILI_1718,
                           challenge = "ilinet")

# Save observed truth
# write.table(truth_1718, "Targets_2017-2018.csv", sep = ",", row.names = F)

# Expand observed truth to include all bins that will be counted as correct
exp_truth_1718 <- expand_truth(truth_1718, week_expand = 1, percent_expand = 5,
                               challenge = "ilinet")

# Truth for examining seasonal severity for peak percentage
# intensity_truth <- tibble(target = rep("Season peak percentage", 23),
#                           location = rep("US National", 23),
#                           forecast_week = rep(NA, 23),
#                           bin_start_incl = seq(4.5, 6.7, 0.1)) %>%
#   mutate(bin_start_incl = trimws(format(bin_start_incl, nsmall = 1)))


# Calculate evaluation period for scoring -------------------------------------
# Boundaries of MMWR weeks ILINet was above baseline
wks_abv_baseline_1718 <- ILI_1718 %>%
  left_join(FluSight::past_baselines %>%
              filter(year == 2017),
            by = "location") %>%
  group_by(location) %>%
  filter(ILI >= value) %>%
  summarize(end_week = last(week)) %>%
  left_join(truth_1718 %>% filter(target == "Season onset") %>% 
              mutate(start_week = case_when(
                bin_start_incl == "none" ~ 43,
                TRUE ~ as.numeric(bin_start_incl)
              )) %>%
              select(location, start_week),
            by = "location")

# Seasonal target bounds for evaluation period
seasonal_eval_period_1718 <- truth_1718 %>%
  # Onset weekly bins
  filter(target == "Season onset") %>%
  mutate(start_week = 43,
         end_week = case_when(
           bin_start_incl == "none" ~ 18,
           TRUE ~ as.numeric(bin_start_incl) + 6
         ),
         end_week = case_when(
           end_week > 52 ~ end_week - 52,
           TRUE ~ end_week
         ),
         end_week_order = case_when(
           end_week < 40 ~ end_week + 52,
           TRUE ~ end_week
         )) %>%
  # Peak week and peak percent
  bind_rows(truth_1718 %>%
              filter(target == "Season peak week") %>%
              left_join(wks_abv_baseline_1718, by = "location") %>%
              mutate(start_week = 43,
                     end_week = case_when(
                       is.na(end_week) ~ 18,
                       TRUE ~ as.numeric(end_week) + 1
                     ),
                     end_week = case_when(
                       end_week > 18 & end_week < 40 ~ 18,
                       TRUE ~ end_week
                     ),
                     end_week_order = case_when(
                       end_week < 40 ~ end_week + 52,
                       TRUE ~ end_week
                     ))) %>%
  bind_rows(truth_1718 %>%
              filter(target == "Season peak week") %>%
              left_join(wks_abv_baseline_1718, by = "location") %>%
              mutate(start_week = 43,
                     end_week = case_when(
                       is.na(end_week) ~ 18,
                       TRUE ~ as.numeric(end_week) + 1
                     ),
                     end_week = case_when(
                       end_week > 18 & end_week < 40 ~ 18,
                       TRUE ~ end_week
                     ),
                     end_week_order = case_when(
                       end_week < 40 ~ end_week + 52,
                       TRUE ~ end_week
                     ),
                     target = "Season peak percentage")) %>%
  select(target, location, start_week, end_week) %>%
  unique()

# Week eval period 
single_week_eval_period <- truth_1718 %>%
  filter(target == "Season onset") %>%
  mutate(start_week = case_when(
    bin_start_incl == "none" ~ 43,
    as.numeric(bin_start_incl) - 4 < 1 ~ as.numeric(bin_start_incl) + 48,
    as.numeric(bin_start_incl) - 4 < 43 & as.numeric(bin_start_incl) > 17 ~ 43,
    TRUE ~ as.numeric(bin_start_incl) - 4
  )) %>%
  left_join(wks_abv_baseline_1718 %>% select(-start_week), by = "location") %>%
  mutate(end_week = case_when(
    is.na(end_week) ~ 18,
    end_week + 3 > 18 & end_week + 3 < 40 ~ 18,
    end_week + 3 > 52 ~ end_week - 49,
    TRUE ~ end_week + 3
  )) %>%
  select(-forecast_week, -bin_start_incl)

week_eval_period_1718 <- bind_rows(
  single_week_eval_period %>%
    mutate(target = "1 wk ahead"),
  single_week_eval_period %>%
    mutate(target = "2 wk ahead"),
  single_week_eval_period %>%
    mutate(target = "3 wk ahead"),
  single_week_eval_period %>%
    mutate(target = "4 wk ahead")
)

# Combine eval bounds into single dataframe
all_eval_period_1718 <- bind_rows(
  seasonal_eval_period_1718,
  week_eval_period_1718
)

# Save week over baseline bounds and eval period bounds
# write_csv(wks_abv_baseline_1718, "Above_Baseline_ILI_Bounds_2017-2018.csv")
# write_csv(all_eval_period_1718, "Eval_Period_Bounds_2017-2018.csv")

# Convenience function to filter scores by evaluation period
create_eval_scores <- function(scores) {
  scores %>%
    left_join(all_eval_period_1718, by = c("location", "target")) %>%
    # Get all weeks in order - deal w/ New Year transition
    mutate(forecast_week_order = ifelse(forecast_week < 40, forecast_week + 52, forecast_week),
           start_week_order = ifelse(start_week < 40, start_week + 52, start_week),
           end_week_order = ifelse(end_week < 40, end_week + 52, end_week)) %>%
    filter(forecast_week_order >= start_week_order &
             forecast_week_order <= end_week_order) %>%
    select(-start_week, -end_week, -forecast_week_order, 
           -start_week_order, -end_week_order)
}

# Score entries and save results in list  -------------------------------------
source("calc_scores.R")
full_scores_1718 <- calc_scores(subs = subs_1718, truth = exp_truth_1718, exclude = F)

submitted_scores_1718 <- calc_scores(subs_1718, exp_truth_1718, exclude = T) 

eval_scores_1718 <- create_eval_scores(full_scores_1718)

eval_submitted_scores_1718 <- create_eval_scores(submitted_scores_1718)


# Save all scores for access from RMarkdown summary document ------------------
save(subs_1718, full_scores_1718, submitted_scores_1718, 
     eval_scores_1718, eval_submitted_scores_1718, #intensity_scores_1718, 
     file = "../scores/AllScoreFiles_1718.Rdata")

# Save observed ILI and truth values for access later -----
save(ILI_1718, truth_1718, exp_truth_1718, seasonal_eval_period_1718,
     week_eval_period_1718, all_eval_period_1718, wks_abv_baseline_1718,
     file = "../scores/TruthFiles_1718.Rdata")


# Investigate overall performance
source("score_summary.R")

# Overall average 
overall_average_score <- overall_avg(eval_scores_1718)

# Location/target specific average
loc_target_scores <- target_scores(eval_scores_1718)
