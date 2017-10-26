
# Function to create scoring period for each season
create_scoring_period <- function() {
  require(cdcfluview)
  require(dplyr)
  
  # Pull in baselines
  baselines <- read.csv("../baselines/wILI_baseline.csv",
                        stringsAsFactors = F) %>%
    mutate(Season = paste0(year, "/", year + 1)) %>%
    select(Location = location, Season, base = value)
  
  # Fetch ILINet data from CDC
  ILI <- get_flu_data(region = "national", data_source = "ilinet", years = 2010:2016) %>%
    mutate(REGION = "US National") %>%
    bind_rows(
      get_flu_data(region = "hhs", sub_region = 1:10, data_source = "ilinet",
                   years = 2010:2016) %>%
        mutate(REGION = paste("HHS", REGION))
    ) %>%
    mutate(Season = if_else(WEEK < 40, 
                            paste0(YEAR - 1, "/", YEAR),
                            paste0(YEAR, "/", YEAR + 1)),
           ILI = round(`% WEIGHTED ILI`, 1)) %>%
    select(Location = REGION, Season, Epiweek = WEEK, ILI)
  
  # Pull in targets
  onsets <- read.csv("../scores/target-multivals.csv",
                     stringsAsFactors = FALSE) %>%
    filter(Target == "Season onset") %>%
    distinct(Season, Location, Valid.Bin_start_incl) %>%
    mutate(Onset = suppressWarnings(as.numeric(Valid.Bin_start_incl))) %>%
    select(-Valid.Bin_start_incl)
  
  
  # Find week at which ILINet goes back below baseline
  short_term_bounds <- ILI %>%
    left_join(baselines, by = c("Location", "Season")) %>%
    group_by(Location, Season) %>%
    filter(ILI >= base) %>%
    summarize(end_week = last(Epiweek) + 3) %>%
    # Set end_week to a max of 18 since that's the end of the season
    mutate(end_week = if_else(end_week > 18,
                              18, end_week)) %>%
    # Join onset weeks in
    right_join(onsets, by = c("Location", "Season")) %>%
    # Set end_week to missing if no onset
    mutate(end_week = ifelse(is.na(Onset), 18, end_week),
           start_week = ifelse(is.na(Onset), 43, 
                               ifelse(Onset - 4 < 1, Onset - 4 + 52, Onset - 4)))
  
  # Create onset bounds
  onset_bounds <- onsets %>%
    mutate(start_week = 43,
           end_week = ifelse(Season == "2014/2015",
                             ifelse(Onset + 6 > 53, Onset - 47, Onset + 6),
                             ifelse(Onset + 6 > 52, Onset - 46, Onset + 6)),
           end_week = ifelse(is.na(end_week), 18, end_week))
  
  # Create peak bounds
  peak_bounds <- short_term_bounds %>%
    mutate(start_week = 43)
  
  
  # Combine all bounds together
  all_target_bounds <- bind_rows(
    onset_bounds %>% mutate(Target = "Season onset"),
    peak_bounds %>% mutate(Target = "Season peak week"),
    peak_bounds %>% mutate(Target = "Season peak percentage"),
    short_term_bounds %>% mutate(Target = "1 wk ahead"),
    short_term_bounds %>% mutate(Target = "2 wk ahead"),
    short_term_bounds %>% mutate(Target = "3 wk ahead"),
    short_term_bounds %>% mutate(Target = "4 wk ahead")
  ) %>%
    select(-Onset) %>%
    # Mutate start and end week to be sequential
    mutate(start_week_seq = ifelse(Season == "2014/2015",
                                   ifelse(start_week < 40, start_week + 53, start_week),
                                   ifelse(start_week < 40, start_week + 52, start_week)),
           end_week_seq = ifelse(Season == "2014/2015",
                                 ifelse(end_week < 40, end_week + 53, end_week),
                                 ifelse(end_week < 40, end_week + 52, end_week)))
    
   
  return(all_target_bounds)
}
