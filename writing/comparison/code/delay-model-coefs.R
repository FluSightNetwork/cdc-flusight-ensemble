## evaluating truth with lags for accuracy 

library(dplyr)
library(readr)
library(broom)
library(ggplot2)

dat <- read_csv("./data/truth-with-lags.csv")
scores <- read_csv("../../scores/scores.csv")

region_map <- data.frame(
    region = c("nat", "hhs1", "hhs2", "hhs3", "hhs4", "hhs5", "hhs6", "hhs7", "hhs8", "hhs9", "hhs10"),
    Location = c("US National", "HHS Region 1", "HHS Region 2", "HHS Region 3", "HHS Region 4",
        "HHS Region 5", "HHS Region 6", "HHS Region 7", "HHS Region 8", "HHS Region 9", "HHS Region 10"),
    stringsAsFactors = FALSE
)

lagged_truth <- dat %>% 
    mutate(
        epiweek_char = as.character(epiweek),
        year = as.numeric(substr(epiweek_char, 1, 4)),
        epiweek = as.numeric(substr(epiweek_char, 5, 6)),
        Season = ifelse(epiweek>35, paste0(year, "/", year+1), paste0(year-1, "/", year)),
        bias_first_report = (`first-observed-wili` - `final-observed-wili`),
        abs_bias_first_report = abs(bias_first_report),
        bias_first_report_factor = relevel(cut(bias_first_report, seq(-3.5, 3.5, by=1)), ref="(-0.5,0.5]"),
        pct_bias_first_report = bias_first_report/`final-observed-wili`,
        abs_pct_bias_first_report = abs(pct_bias_first_report),
        abs_pct_bias_factor = cut(abs_pct_bias_first_report, c(seq(0, 1, by=.05), Inf)),
        pct_bias_factor = cut(pct_bias_first_report, c(-Inf, seq(-1, 1, by=.05), Inf))
    ) %>%
    left_join(region_map) %>%
    select(-region, epiweek_char)

# ## Exploratory plots
# ggplot(lagged_truth) +
#     geom_bar(aes(x=abs_pct_bias_factor)) + facet_wrap(~Location)
# 
# ggplot(lagged_truth) +
#     geom_histogram(aes(x=pct_bias_first_report)) + facet_wrap(~Location)
#     



scores_by_delay <- scores %>%
    select(-Year, -Epiweek) %>%
    filter(Target %in% paste(1:4, "wk ahead")) %>%
    mutate(
        multi_bin_score = `Multi bin score`,
        forecast_step = as.numeric(substr(Target, 1, 2)),
        forecasted_modelweek = `Model Week` + forecast_step,
        long_season = as.numeric(Season=="2014/2015"),
        forecasted_epiweek =  ifelse(forecasted_modelweek-long_season>52, ## if forecasted modelweek is in next calendar year
            forecasted_modelweek - 52 - long_season, ## subtract off 52 if in regular season, 53 if in long season
            forecasted_modelweek) ## return modelweek if 
    ) %>%
    left_join(lagged_truth, by=c("Season"="Season", "Location"="Location", "forecasted_epiweek" = "epiweek")) 


scores_for_analysis <- filter(scores_by_delay, Model%in%c("ReichLab-KCDE", "LANL-DBM", "Delphi-DeltaDensity1", "CU-EKF_SIRS"))

## get total number of obs in each bin
n_legend <- table(scores_for_analysis$bias_first_report_factor)
n_legend_df <- data.frame(bias_range = names(n_legend), count_cat = n_legend) %>%
    mutate(bias_range = factor(bias_range, levels=c("(-3.5,-2.5]", "(-2.5,-1.5]", "(-1.5,-0.5]", "(-0.5,0.5]", "(0.5,1.5]", "(1.5,2.5]")))


# ggplot(scores_for_analysis, aes(x=bias_first_report, y=exp(multi_bin_score))) +
#     geom_point() +
#     geom_smooth(se=FALSE) +
#     facet_grid(Target~Model) +
#     geom_vline(xintercept=0, color="grey", linetype="dashed") +
#     scale_y_continuous(name = "forecast skill") +
#     scale_x_continuous(name = "first reported wILI% - final observed wILI%")

# fm <- glm(exp(multi_bin_score) ~ Model + Target + abs_bias_first_report, data=scores_for_analysis)
# summary(fm)

# fm2 <- mgcv::gam(exp(multi_bin_score) ~ Model + Target + s(abs_bias_first_report), data=scores_for_analysis)
# summary(fm2)
# 
# fm3 <- glm(exp(multi_bin_score)+.001 ~ Model + Target + abs_bias_first_report, data=scores_for_analysis, family=Gamma)
# summary(fm3)

fm4 <- glm(exp(multi_bin_score) ~ Model + Target + factor(forecasted_epiweek) + bias_first_report_factor, data=scores_for_analysis)
summary(fm4)


fm4_coefs <- tidy(fm4, conf.int = TRUE)

## make data.frame with regression results
fm4_coefs_fltr <- 
    filter(fm4_coefs, grepl("bias_first_report",term)) %>%
    mutate(bias_range = substr(term, start=25, stop=100)) %>%
    bind_rows(data.frame(estimate=0, conf.low=0, conf.high=0, bias_range="(-0.5,0.5]")) %>%
    mutate(bias_range = factor(bias_range, levels=c("(-3.5,-2.5]", "(-2.5,-1.5]", "(-1.5,-0.5]", "(-0.5,0.5]", "(0.5,1.5]", "(1.5,2.5]"))) %>%
    left_join(n_legend_df)


## ggsave("./figures/fig-delay-model-coefs.pdf", plot=p, device="pdf", width=6, height=5)

saveRDS(fm4_coefs_fltr, file="./data/delay-model-coefs.rds")
saveRDS(lagged_truth, file = "./data/lagged_truth.rds")
