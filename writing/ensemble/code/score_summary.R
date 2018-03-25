# Summary functions for forecast scores
library(tidyverse)

# Overall team average --------------------------------------------------------
overall_avg <- function(scores, this_location = NULL) {
  if (is.null(this_location)) this_location = unique(scores$location)
  scores %>%
    filter(location %in% this_location) %>%
    group_by(team) %>%
    summarize(score = mean(score, na.rm = T)) %>%
    mutate(skill = exp(score)) %>%
    arrange(desc(score))
}


# Average team score for each individual target/location combination ----------
target_scores <- function(scores, this_location = NULL) {
  if (is.null(this_location)) this_location = unique(scores$location)
  scores %>%
    filter(location %in% this_location) %>%
    group_by(location, target, team) %>%
    summarize(score = mean(score)) %>%
    mutate(skill = exp(score)) %>%
    arrange(location, target, team) %>%
    ungroup
}

# Median avg team score for each target/location combination ------------------
target_team_med <- function(scores, this_location = NULL) {
  if (is.null(this_location)) this_location = unique(scores$location)
  scores %>%
    filter(location %in% this_location) %>%
    group_by(location, target, team) %>%
    summarize(score = mean(score)) %>%
    ungroup() %>%
    mutate(skill = exp(score)) %>%   
    group_by(target) %>%
    summarize(minskill = exp(min(score)),
              onequar = exp(quantile(score)[2]),
              medskill = exp(median(score)),
              thirdquar = exp(quantile(score)[4]),
              maxskill = exp(max(score)))%>%
    arrange(medskill) %>%
    ungroup()
}

# Average team score for all week-ahead targets in a location -----------------
week_ahead_avg <- function(scores, this_location = NULL) {
  if (is.null(this_location)) this_location = unique(scores$location)
  scores %>%
    filter(location %in% this_location,
           target %in% c("1 wk ahead", "2 wk ahead",
                         "3 wk ahead", "4 wk ahead")) %>%
    group_by(team) %>%
    summarize(score = mean(score)) %>%
    mutate(skill = exp(score)) %>%
    ungroup() %>%
    arrange(desc(score))
}

# Average team score for all seasonal targets ---------------------------------
seasonal_avg <- function(scores, this_location = NULL) {
  if (is.null(this_location)) this_location = unique(scores$location)
  scores %>%
    filter(location %in% this_location, 
         target %in% c("Season onset", "Season peak week", "Season peak percentage")) %>%
    group_by(team) %>%
    summarize(score = mean(score)) %>%
    mutate(skill = exp(score)) %>%
    arrange(desc(score))
}

# Average team score for targets across just HHS Regions ----------------------
hhs_week <- function(scores) {
  scores %>%
    filter(location != "US National") %>%
    group_by(team, target, forecast_week) %>%
    summarize(score = mean(score)) %>%
    mutate(skill = exp(score)) %>%
    ungroup() %>%
    arrange(team, target, forecast_week)
}

# Average team ranking for target/location combinations -----------------------
avg_rank <- function(scores, this_target = NULL, this_location = NULL) {
  
  # Set targets and locations to be all if not specified
  if (is.null(this_target)) this_target <- unique(scores$target)
  if (is.null(this_location)) this_location <- unique(scores$location)
  
  scores %>%
    filter(target %in% this_target, location %in% this_location) %>%
    group_by(target, location, team) %>%
    summarize(score = mean(score)) %>%
    mutate(skill = exp(score),
           rank = rank(-score)) %>%
    group_by(team) %>%
    summarize(avg_rank = mean(rank)) %>%
    arrange(avg_rank)
      
}

# Lowest rank for a particular team across target/location combinations -------
low_rank <- function(scores, this_team, this_target = NULL, 
                     this_location = NULL) {
  
  # Set targets and locations to be all if not specified
  if (is.null(this_target)) this_target <- unique(scores$target)
  if (is.null(this_location)) this_location <- unique(scores$location)
  
  scores %>%
    filter(target %in% this_target, location %in% this_location) %>%
    group_by(target, location, team) %>%
    summarize(score = mean(score)) %>%
    mutate(skill = exp(score),
           rank = rank(-score)) %>%
    ungroup() %>%
    filter(team == this_team) %>%
    filter(rank == max(rank))
  
}

# Count number of times a model has a particular rank -------------------------
count_rank <- function(scores, this_team = NULL, this_target = NULL,
                       this_location = NULL) {
  # Set targets and locations to be all if not specified
  if (is.null(this_target)) this_target <- unique(scores$target)
  if (is.null(this_location)) this_location <- unique(scores$location)
  
  scores %>%
    filter(target %in% this_target, location %in% this_location) %>%
    group_by(target, location, team) %>%
    summarize(score = mean(score)) %>%
    mutate(skill = exp(score),
           rank = rank(-score)) %>%
    group_by(team, rank) %>%
    summarize(count = n()) %>%
    arrange(team, rank) %>%
    {if (!is.null(this_team)) filter(., team == this_team)} 
}

# Wide table of all target scores for a particular location =------------------
wide_reg_target_scores <- function(scores, this_location) {
  scores %>%
    filter(location %in% this_location) %>%
    group_by(location, target, team) %>%
    summarize(score = mean(score)) %>%
    ungroup %>%
    select(target, team, score) %>%
    spread(target, score)
}


# Calculate Hellinger distance of scores
calc_Hellinger <- function(subs) {
  
  all <- bind_rows(map(subs_1718, bind_rows), .id = "team") 
  
  Hell_dist <- tibble()

  for(this_week in unique(all$forecast_week)) {
    Hell_dist <- all %>%
      filter(!team %in% c("UnwghtAvg", "Hist-Avg"), type == "Bin", forecast_week == this_week) %>%
      group_by(location, target, forecast_week, bin_start_incl) %>%
      do(as.tibble(t(combn(unique(.$team), m = 2)))) %>%
      rename(team1 = V1, team2 = V2) %>%
      inner_join(all %>% rename(team1 = team, value1 = value) %>%
                   select(location, target, forecast_week, bin_start_incl, team1, value1),
                 by = c("location", "target", "forecast_week", "bin_start_incl", "team1")) %>%
      inner_join(all %>% rename(team2 = team, value2 = value) %>%
                   select(location, target, forecast_week, bin_start_incl, team2, value2),
                 by = c("location", "target", "forecast_week", "bin_start_incl", "team2")) %>%
      group_by(location, target, forecast_week, team1, team2) %>%
      summarize(HD = 1/sqrt(2) * sqrt(sum((sqrt(value1) - sqrt(value2))^2))) %>%
      bind_rows(Hell_dist, .)
  }
  
  return(Hell_dist)
}
