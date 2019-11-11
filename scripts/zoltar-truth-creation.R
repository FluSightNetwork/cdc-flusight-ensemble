## make truth file for zoltar projects
## Nicholas Reich
## November 2019

## final desired product: CSV files with columns `timezero,location,target,value`
## timezero should be in format YYYYMMDD
## timezero should be the MONDAY of each EW
## should include EW40 of season 1 through EW20 of season 2
## value for date targets should be a date in YYYYMMDD format

## one file for all EW in 2017/2018 - 2018/2019 targets
## one file for all EW in 2010/2011 - 2018/2019 targets

## TODO:
## 1) fix ILI values so they are full decimals, not rounded
## 2) make a proper fix to date-based target ties
## 3) add proper test to make sure every target-location-timezero is included

library(tidyverse)
library(MMWRweek)

targets <- c(paste(1:4, "wk ahead"), 
    "Season onset", "Season peak percentage", "Season peak week")
locations <- c("US National", paste("HHS Region", 1:10))

tgts <- read_csv("scores/target-multivals.csv") %>%
    rename(target=Target, value = `Valid Bin_start_incl`, location=Location) %>%
    mutate(
        timezero = MMWRweek2Date(Year, `Calendar Week`, 2),
        timezero = format(timezero, "%Y%m%d"),
        ) 

#####
### fix formatting of date-based targets

tgts$new_value <- tgts$value

## if week is late in calendar year, should use first year in season
num_hi_idx <- which(!is.na(tgts$value) & tgts$value>30 & tgts$target %in% c("Season onset", "Season peak week"))
tgts$new_value[num_hi_idx] <- format(MMWRweek2Date(as.numeric(substr(tgts$Season[num_hi_idx],1,4)), tgts$value[num_hi_idx], 2), "%Y%m%d")

## if week is early in calendar year, should use second year in season
num_low_idx <- which(!is.na(tgts$value) & tgts$value<=30 & tgts$target %in% c("Season onset", "Season peak week"))
tgts$new_value[num_low_idx] <- format(MMWRweek2Date(as.numeric(substr(tgts$Season[num_low_idx],6,9)), tgts$value[num_low_idx], 2), "%Y%m%d")

tgts$value <- tgts$new_value

tgts <- select(tgts, timezero, location, target, value)

#####
### check only one entry for each target-location-timezero

## this needs to be fixed: currently is just removing extra location-target pairs
tgts <- group_by(tgts, timezero, location, target) %>%
    mutate(tmp=row_number()) %>%
    ungroup() %>%
    filter(tmp==1) %>%
    select(-tmp)


## check that every target-location-timezero is included


## check that all targets are one of the 7 required
all(tgts$target %in% targets)

## check that all locations are one of the 11 required
all(tgts$location %in% locations)

write.csv(tgts, file="scores/zoltar_truths_all_seasons.csv", quote=FALSE, row.names = FALSE)
write.csv(filter(tgts, as.numeric(timezero)>20170801), file="scores/zoltar_truths_realtime_seasons.csv", quote=FALSE, row.names = FALSE)
