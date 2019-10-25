## check all files for completeness
## October 2019
## Nicholas Reich

library(tidyverse)
theme_set(theme_bw())


year_week_combos <- expand.grid(
    year = as.character(2010:2019),
    week = sprintf("%02d", c(1:20, 40:52)),
    stringsAsFactors = FALSE
) %>%
    mutate(epiweek = as.integer(paste0(year, week))) %>%
    filter(epiweek >= 201040 &
            epiweek <= 201919) %>%
    rbind(
        data.frame(year = "2014",
            week = "53",
            epiweek = 201453,
            stringsAsFactors = FALSE)
    ) %>%
    arrange(epiweek)

all_methods <- list.dirs("model-forecasts/component-models", recursive=FALSE, full.names = FALSE)

## make big matrix to check presence of all files
file_presence_data <- cbind(year_week_combos, matrix(nrow=nrow(year_week_combos),ncol=length(all_methods)))
names(file_presence_data)[4:ncol(file_presence_data)] <- all_methods
    
## loop through all files to check presence/absence
VERBOSE <- FALSE
for(ind in 1:nrow(year_week_combos)) {
    if(VERBOSE) print(year_week_combos$epiweek[ind])
    for(method in all_methods) {
        res_file <- file.path("model-forecasts", "component-models", 
            method,
            paste0(
                "EW", year_week_combos$week[ind],
                "-", year_week_combos$year[ind],
                "-", method,
                ".csv"))
        file_presence_data[ind, method] <- file.exists(res_file)
        if(VERBOSE) cat(paste0(method, " ", year_week_combos$epiweek[ind], " exists: ", file.exists(res_file)))
        if(VERBOSE) cat("\n")
    }
}

## make data long
file_data_long <- gather(file_presence_data, key="model", value="file_exists", -c("year", "week", "epiweek")) %>%
    mutate(epiweek = as.Date(paste0(epiweek,"00"), "%Y%W%w"))

## plot data
ggplot(file_data_long, aes(x=epiweek, y=model, fill=file_exists)) + 
    geom_tile() +
    scale_fill_brewer(palette = "Dark2")



