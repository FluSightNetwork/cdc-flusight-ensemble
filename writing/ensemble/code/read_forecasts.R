# Functions to read forecasts into memory

read_forecasts <- function(dir, these_weeks = NULL) {

  teams <- list.dirs(path = dir, recursive = F)
 
  subs <- list()

  for (this_team in teams) {
    
    # Extract team name from folder
    team_name <- str_extract(this_team, "[^/]+$")
    # Vector of submission files
    files <- list.files(path = this_team, pattern = "*.csv")
    # Only keep submission files from weeks specified
    if (!is.null(these_weeks)) {
      files <- files[str_extract(files, "EW[0-9]{2}") %in% these_weeks]
    }
    
    for (this_file in files) {
      
      week <- str_extract(this_file, "EW[0-9]{2}")

      tryCatch(
        {
          subs[[team_name]][[week]] <- read_entry(paste0(this_team,"/", this_file))
        },
        error = function(cond) {
          message(paste("Errors reading in submission for", team_name))
          message(cond)
          return(NA)
        },
        warning = function(cond) {
          message(paste("Warnings reading in submission for", team_name))
          message(cond)
          return(NA)
        },
        finally = message(paste("Submission read in for", team_name))
      )
      
      tryCatch(
        {
          verify_entry(subs[[team_name]][[week]])
        },
        error = function(cond) {
          message(paste("Errors in verifying submission for", team_name))
          message(cond)
          return(NA)
        },
        warning = function(cond) {
          message(paste("Warnings in verifying submission for", team_name))
          message(cond)
          return(NA)
        },
        finally = message(paste(week, "submission processed for", team_name))
      )
      
      # Remove invalid probabilities and normalize other probabilities.
      tryCatch(
        {
          subs[[team_name]][[week]] <- 
            remove_invalid(subs[[team_name]][[week]])
          
          subs[[team_name]][[week]] <- 
            normalize_probs(subs[[team_name]][[week]], ignore_invalid = TRUE)
        },
        error = function(cond) {
          message(paste("Errors in normalizing submission for", team_name))
          message(cond)
          return(NA)
        },
        warning = function(cond) {
          message(paste("Warnings in normalizing submission for", team_name))
          message(cond)
          return(NA)
        },
        finally = message(paste(week, "Probabilities normalized for", team_name))
      )
    }
  }
  

  return(subs)
}


subs_by_week <- function(subs) {
  outlist <- list()
  
  for (this_week in names(subs[[1]])){
    week_data <- data.frame()
    for (this_team in names(subs)) {
      # Check if entry for that week is missing
      if (!is.null(subs[[this_team]][[this_week]])) { 
        week_data <- subs[[this_team]][[this_week]] %>%
          select(-forecast_week) %>%
          mutate(team = this_team) %>%
          bind_rows(week_data)
      }
    }
    outlist[[this_week]] <- week_data %>%
      arrange(team)
  }
  
  return(outlist)
}
