#' Visualization of forecast target on ILI scale
#'
#' @param path_to_entry filepath to an entry file
#' @param path_to_baseline_entry filepath to baseline comparison entry file
#' @param target_str character string of which target to select
#' @param breaks breaks defining the bins to use for visualization
#'
#' @return just a plot
#' @export
#'
#' @examples
gridplot_ili_percentage <- function(path_to_entry, path_to_baseline_entry, target_str="Season peak percentage", breaks=c(0,4.5, 6.8, 8.6, Inf)) {
    require(FluSight)
    require(dplyr)
    require(ggplot2)
    require(gridExtra)
    theme_set(theme_minimal())
    baseline_dat<- read_entry(path_to_baseline_entry) %>%
        filter(target == target_str, type=="Bin") %>%
        mutate(
            bin_val = as.numeric(bin_end_notincl),
            bin_cat = cut(bin_val, breaks = breaks, right=FALSE)) %>%
        group_by(location, bin_cat) %>%
        summarize(baseline_prob = sum(value)) %>%
        ungroup()
    dat <- read_entry(path_to_entry) %>%
        filter(target == target_str, type=="Bin") %>%
        mutate(
            bin_val = as.numeric(bin_end_notincl),
            bin_cat = cut(bin_val, breaks = breaks, right=FALSE)) %>%
        group_by(location, bin_cat) %>%
        summarize(prob = sum(value)) %>% 
        ungroup() %>%
        left_join(baseline_dat) %>%
        mutate(RR = prob-baseline_prob)
    
    dat$location <- factor(dat$location, levels=rev(c("US National", paste("HHS Region", 1:10))))

    base_plot <- ggplot(dat, aes(x=bin_cat, y=location)) +
        scale_fill_gradient(low = "white", high="dodgerblue4", limits=c(0,1)) +
        ylab(NULL) + xlab(NULL) + theme(legend.position = "none") 
    p1 <- base_plot +
        geom_tile(aes(fill = baseline_prob)) +
        geom_text(aes(label = round(baseline_prob, 2))) +
        ggtitle("Baseline")

    p2 <- base_plot +
        geom_tile(aes(fill = prob)) +
        geom_text(aes(label = round(prob, 2))) +
        theme(axis.text.y = element_blank(), axis.ticks.y = element_blank()) +
        ggtitle("Current")
    
    p3 <- base_plot +
        geom_tile(aes(fill = RR)) +
        geom_text(aes(label = round(RR, 2))) +
        scale_fill_gradient2(low = "#998ec3", mid = "#f7f7f7",  high="#f1a340", midpoint=0) +
        theme(axis.text.y = element_blank(), axis.ticks.y = element_blank()) +
        ggtitle("Current - baseline")
    
    grid.arrange(p1, p2, p3, nrow=1, widths=c(.4, .3, .3))    
}

gridplot_ili_percentage(path_to_entry = "model-forecasts/submissions/target-type-based-weights/EW51-2017-FSNetwork-2018-01-03.csv", 
    path_to_baseline_entry = "model-forecasts/real-time-component-models/ReichLab_kde/EW05-2018-ReichLab_kde.csv", 
    target="Season peak percentage")

wk1 <- gridplot_ili_percentage(path_to_entry = "model-forecasts/submissions/target-type-based-weights/EW50-2017-FSNetwork-2017-12-27.csv", 
    path_to_baseline_entry = "model-forecasts/real-time-component-models/ReichLab_kde/EW05-2018-ReichLab_kde.csv", 
    target="1 wk ahead")
wk2 <- gridplot_ili_percentage(path_to_entry = "model-forecasts/submissions/target-type-based-weights/EW50-2017-FSNetwork-2017-12-27.csv", 
    path_to_baseline_entry = "model-forecasts/real-time-component-models/ReichLab_kde/EW05-2018-ReichLab_kde.csv", 
    target="2 wk ahead")
wk3 <- gridplot_ili_percentage(path_to_entry = "model-forecasts/submissions/target-type-based-weights/EW50-2017-FSNetwork-2017-12-27.csv", 
    path_to_baseline_entry = "model-forecasts/real-time-component-models/ReichLab_kde/EW05-2018-ReichLab_kde.csv", 
    target="3 wk ahead")
wk4 <- gridplot_ili_percentage(path_to_entry = "model-forecasts/submissions/target-type-based-weights/EW50-2017-FSNetwork-2017-12-27.csv", 
    path_to_baseline_entry = "model-forecasts/real-time-component-models/ReichLab_kde/EW05-2018-ReichLab_kde.csv", 
    target="4 wk ahead")

grid.arrange(wk1, wk2, wk3, wk4, nrow=4)

## loop through peak forecasts
fcast_files <- list.files("model-forecasts/submissions/target-type-based-weights/", full.names=TRUE)
fcast_files <- fcast_files[-grep("metadata.txt", fcast_files)]

pdf("model-forecasts/submissions/plots/peakdists.pdf", width=10, height=7)
for(fcast_file in fcast_files) {
    #grid.arrange(
        gridplot_ili_percentage(path_to_entry = fcast_file, 
        path_to_baseline_entry = "model-forecasts/real-time-component-models/ReichLab_kde/EW05-2018-ReichLab_kde.csv", 
        target="Season peak percentage")#,
    #    top=substr(fcast_file, 0, 4))
}
dev.off()
