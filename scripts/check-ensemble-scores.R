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
  scores[["2010/2011"]] <- purrr::map(entries[["2010/2011"]],
                                      score_entry, exp_truth_2010)
  scores[["2011/2012"]] <- purrr::map(entries[["2011/2012"]],
                                      score_entry, exp_truth_2011)
  scores[["2012/2013"]] <- purrr::map(entries[["2012/2013"]],
                                      score_entry, exp_truth_2012)
  scores[["2013/2014"]] <- purrr::map(entries[["2013/2014"]],
                                      score_entry, exp_truth_2013)
  scores[["2014/2015"]] <- purrr::map(entries[["2014/2015"]],
                                      score_entry, exp_truth_2014)
  scores[["2015/2016"]] <- purrr::map(entries[["2015/2016"]],
                                      score_entry, exp_truth_2015)
  scores[["2016/2017"]] <- purrr::map(entries[["2016/2017"]], 
                                      score_entry, exp_truth_2016)
  
  all_scores <- bind_rows(map(scores, bind_rows), .id = "season")

  return(all_scores)
}

constant_weight_scores <- ensemble_scores("constant-weights")
equal_weight_scores <- ensemble_scores("equal-weights")
target_region_scores <- ensemble_scores("target-and-region-based-weights")
target_scores <- ensemble_scores("target-based-weights")
target_type_scores <- ensemble_scores("target-type-based-weights")