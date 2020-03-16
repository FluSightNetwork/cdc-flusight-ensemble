## reformat 2017/2018 truths to match target-multivals.csv

library(readr)
library(dplyr)

## load("~/Documents/research-versioned/cdc-flusight-ensemble/writing/ensemble/scores/TruthFiles_1718.Rdata")
## write.csv(truth_1718, file="../../scores/target-20172018.csv", row.names = F, quote=F)

truthdata <- read_csv("../../scores/target-multivals.csv")
truth_1718_raw <- read_csv("../../scores/target-20172018.csv") 

truth_1718_seasonal <- filter(truth_1718_raw, is.na(forecast_week))
truth_1718_weekly <- filter(truth_1718_raw, !is.na(forecast_week))

forecast_weeks <- unique(truth_1718_weekly$forecast_week)
nweeks <- length(forecast_weeks)
truth_1718_seasonal_full <- do.call(
    "rbind", 
    replicate(nweeks, truth_1718_seasonal, simplify = FALSE)
) %>%
    mutate(forecast_week = rep(forecast_weeks, each=nrow(truth_1718_seasonal)))

truth_1718 <- rbind(truth_1718_weekly, truth_1718_seasonal_full) %>%
    mutate(
        Season = "2017/2018", 
        `Model Week` = ifelse(forecast_week>40, forecast_week, forecast_week+52),
        Year = ifelse(forecast_week>40, 2017, 2018)
        ) %>%
    rename(Location = location, Target = target, 
        `Valid Bin_start_incl` = bin_start_incl, `Calendar Week` = forecast_week)

new_truths <- rbind(truthdata, truth_1718)
write.csv(new_truths, file="../../scores/target-multivals-20172018.csv", quote=F, row.names = F)
