library(plyr)
library(dplyr)
library(tidyr)
library(lubridate)
library(MMWRweek)
library(cdcFlu20172018) ## devtools::install_github("reichlab/2017-2018-cdc-flu-contest")
library(epiforecast) ## devtools::install_github("cmu-delphi/epiforecast-R", subdir="epiforecast")
## devtools::load_all("~/files/epiforecast-R/epiforecast")
library(FluSight) ## devtools::install_github("jarad/FluSight")

year_week_combos <- expand.grid(
    year = as.character(2010:2017),
    week = sprintf("%02d", c(1:19, 43:52)),
    stringsAsFactors = FALSE
) %>%
    mutate(epiweek = as.integer(paste0(year, week))) %>%
    filter(epiweek >= 201040 &
               epiweek <= 201719) %>%
    rbind(
        data.frame(year = "2014",
                   week = "53",
                   epiweek = 201453,
                   stringsAsFactors = FALSE)
    ) %>%
    arrange(epiweek)

all_methods <- c(
  #"CUBMA",
  #"CUEAKFC",
  "ReichLab_kde"#,
  #"ReichLab_kcde",
  #"ReichLab_sarima_seasonal_difference_TRUE",
  #"ReichLab_sarima_seasonal_difference_FALSE",
  #"Delphi_BasisRegression_PackageDefaults",
  #"Delphi_DeltaDensity_PackageDefaults",
  #"Delphi_EmpiricalBayes_PackageDefaults",
  #"Delphi_EmpiricalBayes_Cond4",
  #"Delphi_EmpiricalFutures_PackageDefaults",
  #"Delphi_EmpiricalTrajectories_PackageDefaults",
  #"Delphi_MarkovianDeltaDensity_PackageDefaults",
  #"Delphi_Stat_FewerComponentsNoBackcastNoNowcast",
  #"Delphi_Uniform"
)

for(ind in seq_len(nrow(year_week_combos))) {
    print(year_week_combos$epiweek[ind])
    for(method in all_methods) {
        res_file <- file.path(method,
                              paste0(
                                  "EW", year_week_combos$week[ind],
                                  "-", year_week_combos$year[ind],
                                  "-", method,
                                  ".csv"))
        cat(paste0(method, " ", year_week_combos$epiweek[ind]))
        cat("\n")
        tryCatch({
            FluSight::verify_entry_file(res_file)
                res_df =
                    read.csv(res_file, check.names=FALSE, stringsAsFactors=FALSE) %>%
                    stats::setNames(., tolower(names(.)))
                check_onset_point_pred_df =
                    data.frame(location=c("US National", paste0("HHS Region ",1:10)),
                               target="Season onset", type="Point", unit="week",
                               bin_start_incl=NA_character_, bin_end_notincl=NA_character_,
                               stringsAsFactors=FALSE)
                missing_onset_point_pred_df = dplyr::anti_join(check_onset_point_pred_df, res_df,
                                                               names(check_onset_point_pred_df))
                if (nrow(missing_onset_point_pred_df) != 0) {
                    warning(paste0("Missing Season onset Point predictions for the following Locations: ",
                                   paste(missing_onset_point_pred_df$location, collapse=", "),
                                   "."))
                }
                if (year_week_combos$epiweek[ind] %>% dplyr::between(201431L, 201530L)) {
                    check_week_53_df =
                        data.frame(location=rep(c("US National", paste0("HHS Region ",1:10)),each=2L),
                                   target=rep(c("Season onset", "Season peak week"), 11L),
                                   type="Bin", unit="week",
                                   bin_start_incl="53.0", bin_end_notincl="54.0",
                                   stringsAsFactors=FALSE)
                    missing_week_53_df = dplyr::anti_join(check_week_53_df, res_df,
                                                          names(check_week_53_df))
                    if (nrow(missing_week_53_df ) != 0) {
                        warning(paste0("Missing week 53 bin(s) for Season onset or Season peak week."))
                    }
                }
            },
            error = function(e) {print(e); stop("error")},
            warning = function(w) {
                if (any(grepl("Missing point predictions detected in .* Season onset.", w))) {
                    ## These could be missing rows or predictions of no onset ("none"
                    ## or NA). Ignore this warning and check for missing point
                    ## predictions separately.
                } else if (any(grepl("These extra bins for Season onset are ignored: 53.0", w)) &&
                           year_week_combos$epiweek[ind] %>% dplyr::between(201431L, 201530L)) {
                    ## For the 2014/2015 season, there should be week 53 bins. Ignore
                    ## this warning and check for missing week 53 bins separately.
                } else {
                    print(w)
                }
            })
    }
}

get_legend_grob <- function(x) {
    data <- ggplot2:::ggplot_build(x)
    
    plot <- data$plot
    panel <- data$panel
    data <- data$data
    theme <- ggplot2:::plot_theme(plot)
    position <- theme$legend.position
    if (length(position) == 2) {
        position <- "manual"
    }
    
    legend_box <- if (position != "none") {
        ggplot2:::build_guides(plot$scales, plot$layers, plot$mapping,
                               position, theme, plot$guides, plot$labels)
    } else {
        ggplot2:::zeroGrob()
    }
    if (ggplot2:::is.zero(legend_box)) {
        position <- "none"
    }
    else {
        legend_width <- gtable:::gtable_width(legend_box) + theme$legend.margin
        legend_height <- gtable:::gtable_height(legend_box) + theme$legend.margin
        just <- valid.just(theme$legend.justification)
        xjust <- just[1]
        yjust <- just[2]
        if (position == "manual") {
            xpos <- theme$legend.position[1]
            ypos <- theme$legend.position[2]
            legend_box <- editGrob(legend_box, vp = viewport(x = xpos,
                                                             y = ypos, just = c(xjust, yjust), height = legend_height,
                                                             width = legend_width))
        }
        else {
            legend_box <- editGrob(legend_box, vp = viewport(x = xjust,
                                                             y = yjust, just = c(xjust, yjust)))
        }
    }
    return(legend_box)
}


#' Make plots of prediction submissions for flu contest: so far, seasonal targets only
#'
#' @param preds_save_files vector of paths to files with predictions in csv submission format
#' @param plots_save_file path to a pdf file where plots should go
#' @param data data observed so far this season
make_predictions_plots <- function(
    preds_save_files,
    plots_save_file,
    data
) {
    require("grid")
    require("ggplot2")
    
    predictions <- rbind.fill(lapply(seq_along(preds_save_files),
                                     function(i) {
                                         read.csv(preds_save_files[i]) %>%
                                             mutate(model = names(preds_save_files)[i])
                                     }))
    
    preds_region_map <- data.frame(
        internal_region = c("National", paste0("Region ", 1:10)),
        preds_region = c("US National", paste0("HHS Region ", 1:10))
    )
    
    current_season <- tail(data$season, 1)
    
    pdf(plots_save_file)
    
    for(region in unique(data$region)) {
        preds_region <- preds_region_map$preds_region[preds_region_map$internal_region == region]
        
        ## Observed incidence
        p_obs <- ggplot(data[data$region == region & data$season == current_season, ]) +
            expand_limits(x = c(0, 42), y = c(0, 13)) +
            geom_line(aes(x = season_week, y = weighted_ili)) +
            geom_hline(yintercept = get_onset_baseline(region, season = current_season), colour = "red") +
            ggtitle("Observed incidence") +
            theme_bw()
        
        ## Onset
        reduced_preds <- predictions[predictions$Location == preds_region & predictions$Target == "Season onset" & predictions$Type == "Bin", ] %>%
            mutate(
                season_week = year_week_to_season_week(as.numeric(as.character(Bin_start_incl)), 2016)
            )
        point_pred <- predictions[predictions$Location == preds_region & predictions$Target == "Season onset" & predictions$Type == "Point", , drop = FALSE] %>%
            mutate(
                season_week = year_week_to_season_week(Value, 2016)
            )
        point_pred$season_week[is.na(point_pred$season_week)] <- 0
        p_onset <- ggplot(reduced_preds) +
            geom_line(aes(x = season_week, y = Value, color = model)) +
            geom_vline(aes(xintercept = season_week, color = model), data = point_pred) +
            expand_limits(x = c(0, 42)) +
            ylab("predicted probability of onset") +
            ggtitle("Onset") +
            theme_bw()
        
        legend_grob <- get_legend_grob(p_onset)
        
        p_onset <- p_onset +
            theme(legend.position = "none")
        
        
        ## Peak Timing
        reduced_preds <- predictions[predictions$Location == preds_region & predictions$Target == "Season peak week" & predictions$Type == "Bin", ] %>%
            mutate(
                season_week = year_week_to_season_week(as.numeric(as.character(Bin_start_incl)), 2016)
            )
        point_pred <- predictions[predictions$Location == preds_region & predictions$Target == "Season peak week" & predictions$Type == "Point", , drop = FALSE] %>%
            mutate(
                season_week = year_week_to_season_week(Value, 2016)
            )
        p_peak_timing <- ggplot(reduced_preds) +
            geom_line(aes(x = season_week, y = Value, color = model)) +
            geom_vline(aes(xintercept = season_week, color = model), data = point_pred) +
            expand_limits(x = c(0, 42)) +
            ylab("predicted probability of peak") +
            ggtitle("Peak timing") +
            theme_bw() +
            theme(legend.position = "none")
        
        
        ## Peak Incidence
        reduced_preds <- predictions[predictions$Location == preds_region & predictions$Target == "Season peak percentage" & predictions$Type == "Bin", ] %>%
            mutate(inc_bin = as.numeric(as.character(Bin_start_incl)))
        point_pred <- predictions[predictions$Location == preds_region & predictions$Target == "Season peak percentage" & predictions$Type == "Point", , drop = FALSE] %>%
            mutate(inc_bin = Value)
        p_peak_inc <- ggplot(reduced_preds) +
            geom_line(aes(x = inc_bin, y = Value, color = model)) +
            geom_vline(aes(xintercept = inc_bin, color = model), data = point_pred) +
            expand_limits(x = c(0, 13)) +
            ylab("predicted probability of peak incidence") +
            coord_flip() +
            ggtitle("Peak incidence") +
            theme_bw() +
            theme(legend.position = "none")
        
        grid.newpage()
        pushViewport(viewport(layout =
                                  grid.layout(nrow = 4,
                                              ncol = 2,
                                              heights = unit(c(2, 1, 1, 1), c("lines", "null", "null", "null")))))
        
        grid.text(preds_region,
                  gp = gpar(fontsize = 20),
                  vp = viewport(layout.pos.col = 1:2, layout.pos.row = 1))
        print(p_onset, vp = viewport(layout.pos.col = 1, layout.pos.row = 2))
        print(p_obs, vp = viewport(layout.pos.col = 1, layout.pos.row = 3))
        print(p_peak_timing, vp = viewport(layout.pos.col = 1, layout.pos.row = 4))
        print(p_peak_inc, vp = viewport(layout.pos.col = 2, layout.pos.row = 3))
        
        pushViewport(viewport(layout.pos.row = 2, layout.pos.col = 2))
        grid.draw(legend_grob)
        upViewport()
    }
    
    dev.off()
}


#' Make plots of prediction submissions for flu contest: so far, seasonal targets only
#'
#' @param preds_save_files vector of paths to files with predictions in csv submission format
#' @param plots_save_file path to a pdf file where plots should go
#' @param data data observed so far this season
make_predictions_plots_individual_weeks <- function(
    preds_save_files,
    plots_save_file,
    data
) {
    require("grid")
    require("ggplot2")
    
    predictions <- rbind.fill(lapply(seq_along(preds_save_files),
                                     function(i) {
                                         read.csv(preds_save_files[i]) %>%
                                             mutate(model = names(preds_save_files)[i])
                                     }))
    
    preds_region_map <- data.frame(
        internal_region = c("National", paste0("Region ", 1:10)),
        preds_region = c("US National", paste0("HHS Region ", 1:10))
    )
    
    current_season <- tail(data$season, 1)
    
    pdf(plots_save_file)
    
    for(region in unique(data$region)) {
        preds_region <- preds_region_map$preds_region[preds_region_map$internal_region == region]
        
        ## Observed incidence
        p_obs <- ggplot(data[data$region == region & data$season == current_season, ]) +
            expand_limits(x = c(0, 42), y = c(0, 13)) +
            geom_line(aes(x = season_week, y = weighted_ili)) +
            geom_hline(yintercept = get_onset_baseline(region, season = current_season), colour = "red") +
            ggtitle("Observed incidence") +
            theme_bw()
        
        grid.newpage()
        pushViewport(viewport(layout =
                                  grid.layout(nrow = 3,
                                              ncol = 5,
                                              heights = unit(c(2, 0.5, 1), c("lines", "null", "null")),
                                              widths = unit(c(1, 0.5, 0.5, 0.5, 0.5), rep("null", 5)))))
        
        grid.text(preds_region,
                  gp = gpar(fontsize = 20),
                  vp = viewport(layout.pos.col = 1:5, layout.pos.row = 1))
        print(p_obs, vp = viewport(layout.pos.col = 1, layout.pos.row = 3))
        
        ## Each prediction horizon 1 - 4
        for(ph in 1:4) {
            reduced_preds <- predictions[predictions$Location == preds_region & predictions$Target == paste0(ph, " wk ahead") & predictions$Type == "Bin", ] %>%
                mutate(inc_bin = as.numeric(as.character(Bin_start_incl)))
            point_pred <- predictions[predictions$Location == preds_region & predictions$Target == paste0(ph, " wk ahead") & predictions$Type == "Point", , drop = FALSE] %>%
                mutate(inc_bin = Value)
            p_ph <- ggplot(reduced_preds) +
                geom_line(aes(x = inc_bin, y = Value, color = model)) +
                geom_vline(aes(xintercept = inc_bin, color = model), data = point_pred) +
                expand_limits(x = c(0, 13)) +
                ylab("predicted probability of peak incidence") +
                coord_flip() +
                ggtitle(paste0("Horizon ", ph)) +
                theme_bw()
            
            legend_grob <- get_legend_grob(p_ph)
            
            p_ph <- p_ph +
                theme(legend.position = "none")
            
            print(p_ph, vp = viewport(layout.pos.col = 1 + ph, layout.pos.row = 3))
        }
        
        pushViewport(viewport(layout.pos.row = 2, layout.pos.col = 1:2))
        grid.draw(legend_grob)
        upViewport()
    }
    
    dev.off()
}



for(ind in seq_len(nrow(year_week_combos))) {
    res_files <- sapply(all_methods, function(method) {
        file.path(method,
                  paste0(
                      "EW", year_week_combos$week[ind],
                      "-", year_week_combos$year[ind],
                      "-", method,
                      ".csv"))
    })
    
    all_regions <- c("nat", paste0("hhs", 1:10))
    data <- rbind.fill(lapply(all_regions,
                              function(region_str) {
                                  get_partially_revised_ilinet(
                                      region_str = region_str,
                                      epiweek_str = year_week_combos$epiweek[ind]) %>%
                                      mutate(region = region_str)
                              })) %>%
        mutate(
            region.type = ifelse(region == "nat", "National", "HHS Regions"),
            region = ifelse(region == "nat", "National", gsub("hhs", "Region ", region)),
            weighted_ili = wili,
            time = as.POSIXct(MMWRweek2Date(year, week))
        )
    
    ## Add time_index column: the number of days since some origin date (1970-1-1 in this case).
    ## The origin is arbitrary.
    data$time_index <- as.integer(data$time -  as.POSIXct(ymd(paste("1970", "01", "01", sep = "-"))))
    
    ## Season column: for example, weeks of 2010 up through and including week 30 get season 2009/2010;
    ## weeks after week 30 get season 2010/2011
    ## I am not sure where I got that the season as defined as starting on MMWR week 30 from...
    data$season <- ifelse(
        data$week <= 30,
        paste0(data$year - 1, "/", data$year),
        paste0(data$year, "/", data$year + 1)
    )
    
    ## Season week column: week number within season
    ## weeks after week 30 get season_week = week - 30
    ## weeks before week 30 get season_week = week + (number of weeks in previous year) - 30
    ## This computation relies on the start_date function in package MMWRweek,
    ## which is not exported from that package's namespace!!!
    data$season_week <- ifelse(
        data$week <= 30,
        data$week + MMWRweek(MMWRweek:::start_date(data$year) - 1)$MMWRweek - 30,
        data$week - 30
    )
    
    data <- as.data.frame(data)
    
    make_predictions_plots(
        preds_save_files = res_files,
        plots_save_file = paste0(
            "plots/",
            year_week_combos$epiweek[ind],
            "-plots.pdf"),
        data = data
    )
}






for(ind in seq_len(nrow(year_week_combos))) {
    res_files <- sapply(all_methods, function(method) {
        file.path(method,
                  paste0(
                      "EW", year_week_combos$week[ind],
                      "-", year_week_combos$year[ind],
                      "-", method,
                      ".csv"))
    })
    
    all_regions <- c("nat", paste0("hhs", 1:10))
    data <- rbind.fill(lapply(all_regions,
                              function(region_str) {
                                  get_partially_revised_ilinet(
                                      region_str = region_str,
                                      epiweek_str = year_week_combos$epiweek[ind]) %>%
                                      mutate(region = region_str)
                              })) %>%
        mutate(
            region.type = ifelse(region == "nat", "National", "HHS Regions"),
            region = ifelse(region == "nat", "National", gsub("hhs", "Region ", region)),
            weighted_ili = wili,
            time = as.POSIXct(MMWRweek2Date(year, week))
        )
    
    ## Add time_index column: the number of days since some origin date (1970-1-1 in this case).
    ## The origin is arbitrary.
    data$time_index <- as.integer(data$time -  as.POSIXct(ymd(paste("1970", "01", "01", sep = "-"))))
    
    ## Season column: for example, weeks of 2010 up through and including week 30 get season 2009/2010;
    ## weeks after week 30 get season 2010/2011
    ## I am not sure where I got that the season as defined as starting on MMWR week 30 from...
    data$season <- ifelse(
        data$week <= 30,
        paste0(data$year - 1, "/", data$year),
        paste0(data$year, "/", data$year + 1)
    )
    
    ## Season week column: week number within season
    ## weeks after week 30 get season_week = week - 30
    ## weeks before week 30 get season_week = week + (number of weeks in previous year) - 30
    ## This computation relies on the start_date function in package MMWRweek,
    ## which is not exported from that package's namespace!!!
    data$season_week <- ifelse(
        data$week <= 30,
        data$week + MMWRweek(MMWRweek:::start_date(data$year) - 1)$MMWRweek - 30,
        data$week - 30
    )
    
    data <- as.data.frame(data)
    
    make_predictions_plots_individual_weeks(
        preds_save_files = res_files,
        plots_save_file = paste0(
            "plots/",
            year_week_combos$epiweek[ind],
            "-plots-ph1-4.pdf"),
        data = data
    )
}
