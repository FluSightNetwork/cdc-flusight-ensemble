require(FluSight)
require(dplyr)

calc_scores <- function(subs, truth, exclude = FALSE) {
  
  scores <- data.frame()
  
  for (this_team in names(subs)) {
    
    # Determine which weeks to score
    # exclude = F will count missing weeks as -10
    # exclude = T will only score forecasts that teams have submitted
    if (exclude == FALSE) weeks <- names(subs[["Delphi_Uniform"]])
    else weeks <- names(subs[[this_team]])

    for (this_week in weeks) { 
      # Check for missing forecast - assign -10 if missing
      if (is.null(subs[[this_team]][[this_week]])) {
        these_scores <- expand.grid(location = c("US National", "HHS Region 1", 
                                                 "HHS Region 2", "HHS Region 3",
                                                 "HHS Region 4", "HHS Region 5", 
                                                 "HHS Region 6", "HHS Region 7",
                                                 "HHS Region 8", "HHS Region 9", 
                                                 "HHS Region 10"),
                                    target = c("Season onset", "Season peak percentage",
                                               "Season peak week", "1 wk ahead",
                                               "2 wk ahead", "3 wk ahead", 
                                               "4 wk ahead"),
                                    stringsAsFactors = FALSE)
        these_scores$score <- -10
        these_scores$forecast_week <- as.numeric(gsub("EW", "", this_week))
        these_scores$team <- this_team
      } else {
        # Score receieved entry
        these_scores <- score_entry(subs[[this_team]][[this_week]], truth)
        these_scores$team <- this_team
      }
      # Bind entry scores together
      scores <- bind_rows(scores, these_scores)
    }
  }
  
  # Create forecast skill metric and sort
  scores <- scores %>% 
    mutate(skill = exp(score)) %>%
    arrange(team, forecast_week)
  
  return(scores)
}



