# Check Travis scores against FluSight calculated scores
library(FluSight)
library(dplyr)
library(purrr)
library(stringr)

travis_scores <- read.csv("../scores/scores.csv",
                          stringsAsFactors = F)

# Create truth to score against
truth_condense <- function(year) {
  create_truth(fluview = T, year = year) %>%
    filter(is.na(forecast_week) | forecast_week >= 43 | forecast_week <= 18) %>%
    expand_truth(week_expand = 1, percent_expand = 5)
}

exp_truth_2010 <- truth_condense(2010)
exp_truth_2011 <- truth_condense(2011)
exp_truth_2012 <- truth_condense(2012)
exp_truth_2013 <- truth_condense(2013)
exp_truth_2014 <- truth_condense(2014)
exp_truth_2015 <- truth_condense(2015)
exp_truth_2016 <- truth_condense(2016)

# Pull in truth based on week 28 values in given year
obs_truth <- read.csv("../scores/target-multivals.csv",
                      stringsAsFactors = F)

expand_old_truth <- function(season) {
  obs_truth %>%
    filter(Season == season & (Calendar.Week >= 43 | Calendar.Week <= 18)) %>%
    mutate(forecast_week = ifelse(Target %in% c("Season onset", "Season peak week",
                                                "Season peak percentage"),
                                  NA,
                                  Calendar.Week)) %>%
    rename(location = Location, target = Target, bin_start_incl = Valid.Bin_start_incl) %>%
    distinct(location, target, forecast_week, bin_start_incl) %>%
    {if (season == "2014/2015") expand_truth(., week53 = T) else expand_truth(.) }
  
}

obs_exp_truth_2010 <- expand_old_truth("2010/2011")
obs_exp_truth_2011 <- expand_old_truth("2011/2012")
obs_exp_truth_2012 <- expand_old_truth("2012/2013")
obs_exp_truth_2013 <- expand_old_truth("2013/2014")
obs_exp_truth_2014 <- expand_old_truth("2014/2015")
obs_exp_truth_2015 <- expand_old_truth("2015/2016")
obs_exp_truth_2016 <- expand_old_truth("2016/2017")



# Pull in csvs from ensembles

read_all_entries <- function(model) {
  out_list <- list()
  
  dir <- paste0("../model-forecasts/cv-ensemble-models/", model, "/")

  files <- list.files(dir, pattern = "*.csv")
  
  for (this_file in files) {
    week <- str_extract(this_file, "EW[0-9]{2}")
    
    num_week <- as.numeric(str_extract(week, "[0-9]{2}"))
    
    year <- as.numeric(str_extract(this_file, "[0-9]{4}"))
    
    season <- if_else(num_week < 40, paste0(year - 1, "/", year),
                      paste0(year, "/", year + 1))
    
    out_list[[season]][[week]] <- read_entry(paste0(dir, this_file))
    
  }
  
  return(out_list)
}

ensemble_scores <- function(model) {
  
  entries <- read_all_entries(model)
  
  scores <- list()
  scores[["2010/2011"]] <- map(entries[["2010/2011"]],
                               score_entry, obs_exp_truth_2010)
  scores[["2011/2012"]] <- map(entries[["2011/2012"]],
                               score_entry, obs_exp_truth_2011)
  scores[["2012/2013"]] <- map(entries[["2012/2013"]],
                               score_entry, obs_exp_truth_2012)
  scores[["2013/2014"]] <- map(entries[["2013/2014"]],
                               score_entry, obs_exp_truth_2013)
  scores[["2014/2015"]] <- map(entries[["2014/2015"]],
                               score_entry, obs_exp_truth_2014)
  scores[["2015/2016"]] <- map(entries[["2015/2016"]],
                               score_entry, obs_exp_truth_2015)
  scores[["2016/2017"]] <- map(entries[["2016/2017"]], 
                               score_entry, obs_exp_truth_2016)
  
  all_scores <- bind_rows(map(scores, bind_rows), .id = "season")

  return(all_scores)
}

constant_weight_scores <- ensemble_scores("constant-weights")
equal_weight_scores <- ensemble_scores("equal-weights")
target_region_scores <- ensemble_scores("target-and-region-based-weights")
target_scores <- ensemble_scores("target-based-weights")
target_type_scores <- ensemble_scores("target-type-based-weights")

# Create boundaries for scores that we're interested in
all_ensemble_scores <- bind_rows(
  constant_weight_scores %>% mutate(Model = "FSNetwork-CW"),
  equal_weight_scores %>% mutate(Model = "FSNetwork-EW"),
  target_region_scores %>% mutate(Model = "FSNetwork-TRW"),
  target_scores %>% mutate(Model = "FSNetwork-TW"),
  target_type_scores %>% mutate(Model = "FSNetwork-TTW")
) %>%
  rename(Season = season, Location = location, Target = target,
         FluSight_score = score, Epiweek = forecast_week) %>%
  mutate(Model.Week = ifelse(Season == "2014/2015",
                             ifelse(Epiweek < 40, Epiweek + 53, Epiweek),
                             ifelse(Epiweek < 40, Epiweek + 52, Epiweek)))

# Compare Travis scores to FluSight scores
compare_scores <- all_ensemble_scores %>%
  left_join(travis_scores, by = c("Season", "Location", "Target",
                                  "Epiweek", "Model.Week", "Model")) %>%
  select(Season, Location, Target, Epiweek, Model, FluSight_score, Multi.bin.score) %>%
  mutate(diff = FluSight_score - Multi.bin.score)

# Print scores that differ by more than 1e-12
different_score <- compare_scores %>%
  filter(diff > 1e-12)

table(different_score$Model)
table(different_score$Target)
table(different_score$Location)
table(different_score$Epiweek)
table(different_score$Season)

# All differences in 2014/15 peak week
obs_exp_truth_2014 %>%
  filter(target == "Season peak week", location == "HHS Region 3") %>%
  distinct

obs_truth %>%
  filter(Season == "2014/2015", Target == "Season peak week") %>%
  distinct(Season, Target, Location, Valid.Bin_start_incl)

compare_scores %>%
  filter(Season == "2014/2015", Target == "Season peak week",
         Location == "HHS Region 3", Epiweek == 1)
