## checking point estimate accuracy

## want file with following columns:
## Year,Calendar Week,Season,Location,Target,PointEst


#' Extract point estimates from CDC format file
#'
#' @param filename character string path to a CDC format forecast file
#'
#' @return a data.frame with Year, Calendar Week, Location, model_name, Target, Value
#'
extract_point_ests <- function(filename){
    require(dplyr)
    require(FluSight)
    file_parts <- strsplit(filename, split = "/")[[1]]
    file_only <- file_parts[length(file_parts)]
    message(paste("file:", filename, Sys.time()))
    dat <- read_entry(filename)
    if(grepl("weights", filename)){ ## tests for whether filename belongs to ensemble
        point_ests <- generate_point_forecasts(dat, method="Median") %>%
            ungroup() %>%
            dplyr::select(location, target, value)
    } else {
        point_ests <- dat %>% 
            dplyr::filter(type=="Point") %>%
            dplyr::select(location, target, value)
    }
    point_ests$year <- as.numeric(substr(file_only, 6, 9))
    point_ests$calendar_week <- as.numeric(substr(file_only, 3, 4))
    point_ests$model_name <- substr(file_only, 11, gregexpr("\\.", file_only)[[1]]-1)
    return(point_ests)
}

ew_to_seasonweek <- function(EW, year, season_start_week=30){
  require(MMWRweek)
  num_days <- ifelse(MMWRweek::MMWRweek(as.Date(paste0(as.character(year),"-12-28")))[2] == 53, 53, 52)
  return(ifelse(EW > season_start_week, EW - season_start_week, (EW + num_days) - season_start_week))
}

## get all model files without the metadata
some_files <- c(list.files("model-forecasts/component-models/", full.names=TRUE, recursive = TRUE),
    list.files("model-forecasts/cv-ensemble-models/", full.names=TRUE, recursive = TRUE))
some_files <- some_files[-grep("metadata.txt", some_files)]
some_files <- some_files[-grep("model-id-map", some_files)]
some_files <- some_files[-grep("complete-modelids", some_files)]

## extract point estimates and put into one dataframe
tmp <- lapply(some_files, FUN=extract_point_ests)
tmp.df <- do.call(rbind.data.frame, tmp)

## join with truths
truths <- read.csv("scores/target-multivals-20172018.csv") %>%
    dplyr::rename(
        location=Location,
        target=Target,
        year=Year,
        calendar_week=Calendar.Week
    )
ests_with_truth <- tmp.df %>% 
    left_join(truths) %>%
    mutate(
        target_type = ifelse(target %in% c("Season peak week", "Season onset"), "Week", "wILI"),
        obs_value = as.numeric(as.character(Valid.Bin_start_incl)),
        err = ifelse(target_type == "wILI", value - obs_value, 
                     ew_to_seasonweek(value, year) - ew_to_seasonweek(obs_value, year))
        )
    

write.csv(ests_with_truth, file="scores/point_ests_adj-w20172018.csv", quote = FALSE, row.names = FALSE)
