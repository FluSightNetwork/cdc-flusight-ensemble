#' Reformat old CDC-format forecasts
#'
#' @param old_format_filename 
#'
#' @return updated forecast entry
reformat_forecast <- function(old_format_filename) {
    require(readr)
    require(FluSight)
    require(dplyr)
    
    tmp <- read_entry(old_format_filename) %>% dplyr::select(-forecast_week)
    
    week_targets <- c("Season peak week", "Season onset")
    inc_targets <- c("Season peak percentage", paste(1:4, "wk ahead"))
    new_forecast_df <- filter(tmp, target %in% week_targets) 
    
    ## fix trailing ".0" on week bin ends
    # bad_bins <- paste0(c(2:21, 41:53), ".0")
    # idx_to_fix <- which(new_forecast_df$bin_end_notincl %in% bad_bins)
    # new_forecast_df$bin_end_notincl[idx_to_fix] <- substr(
    #     new_forecast_df$bin_end_notincl[idx_to_fix], 
    #     start = 0,
    #     stop = nchar(new_forecast_df$bin_end_notincl[idx_to_fix])-2)
    
    forecast_inc_targets <- filter(tmp, target %in% inc_targets)
    
    ## reformat all incidence targets
    for(inc_target in inc_targets) {
        for(region in unique(tmp$location)) {
            old_target_df <- filter(tmp, target == inc_target, location == region)
            new_target_df <- reformat_one_target(old_target_df)
            new_forecast_df <- rbind(new_forecast_df, new_target_df)
        }
    }
    
    ## generate point estimates
    new_forecast_point_ests <- generate_point_forecasts(new_forecast_df)
    new_forecast_df <- new_forecast_df %>%
        filter(type == "Bin") %>%
        bind_rows(new_forecast_point_ests)
    
    if(!verify_entry(new_forecast_df))
        stop(paste("new forecast df not a valid entry for", old_format_filename))
    
    return(new_forecast_df)
}

#' Function to reformat a single target's CDC-format forecast
#' 
#' \code{reformat_one_target} reformats its input, an old-style CDC-format 
#' forecast of one forecasted target in a data-frame, into an updated format
#' with more bins. It returns the new output in a dataframe.
#'
#' @param df 
#'
#' @return a reformatted df with expanded bins
#'
reformat_one_target <- function(df) {
    require(dplyr)
    ## df should contain all bin values for one target
    ## df <- filter(tmp, location == "US National", target == "Season peak percentage", type=="Bin")
    df <- filter(df, type=="Bin")
    ## assume it is an incidence target, with final bin representing 13-100
    final_bin_idx <- which(df$bin_start_incl=="13.0")
    final_bin_row <- df[final_bin_idx,]
    df_without_final_bin <- df[-final_bin_idx,]
    df_without_final_bin$bin_start_incl <- as.numeric(df_without_final_bin$bin_start_incl)
    df_without_final_bin$bin_end_notincl <- as.numeric(df_without_final_bin$bin_end_notincl)
    
    ## where we want the new probabilities interpolated for
    newx <- c(0, seq(.05, 12.95, by=.1))
    
    ## set x and y vals for cumsum spline
    ## need to add first point at (0,0) to ensure positive values for all newx > 0
    x <- c(0, (df_without_final_bin$bin_start_incl+df_without_final_bin$bin_end_notincl)/2, 13)
    y <- c(0, df$value)
    cdffun <- splinefun(x=x, y=cumsum(y), method="hyman")
    new_values <- c(diff(cdffun(newx)), final_bin_row$value)
    new_values_std <- new_values/sum(new_values)
    # plot(x,cumsum(y))
    # lines(newx, cdffun(newx), col="red")
    
    new_df <- data_frame(
        location = df$location[1],
        target = df$target[1],
        type = "Bin",
        unit = "percent",
        bin_start_incl = sprintf(seq(0, 13, .1), fmt = '%#.1f'),
        bin_end_notincl = sprintf(c(seq(.1, 13, .1), 100), fmt = '%#.1f'),
        value = new_values_std
    )
    return(new_df)
}