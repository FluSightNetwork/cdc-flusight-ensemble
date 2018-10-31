source("code/reformat_old_forecasts.R")

old_format_files <- list.files("../../../FluSight-forecasts-master/2015-2016/UnwghtAvg/", full.names = TRUE)
new_filepath <- "../../model-forecasts/component-models/FluSight_unweighted_avg/"

for(filename in old_format_files){
    tmp_new <- reformat_forecast(filename)
    this_ew <- substr(filename, nchar(filename)-26, nchar(filename)-25)
    this_year <- ifelse(as.numeric(this_ew)<35, 2016, 2015)
    new_filename <- paste0(new_filepath, "EW", this_ew, "-", this_year, "-FluSight_unweighted_avg.csv")
    write.csv(tmp_new, file=new_filename, row.names = FALSE)
}