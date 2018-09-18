## look at point estimate errors

library(dplyr)
library(readr)
library(ggplot2)

theme_set(theme_minimal())


ests <- read_csv("scores/point_ests_adj-w20172018.csv")
names(ests) <- tolower(names(ests))

### check how many observations for each location/season
tbl_df(ests) %>% 
    group_by(season, location) %>%
    summarize(tot_obs = n()) %>% 
    print(n=Inf)

tbl_df(ests) %>% 
    group_by(season, target) %>%
    summarize(tot_obs = n()) %>% print(n=Inf)

### analysis by season
tab1 <- tbl_df(ests) %>% group_by(model_name, target, season) %>%
    dplyr::filter(!(target %in% c("Season onset", "Season peak week")), !is.na(season)) %>%
    summarize(
        nobs = n(),
        bias = mean(err, na.rm=TRUE),
        mse = mean(err^2, na.rm=TRUE),
        rmse = sqrt(mse))

ggplot(tab1, aes(x=reorder(model_name, X = abs(bias)), y=bias, color=factor(season))) + 
    geom_point() + 
    facet_wrap(~target) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5)) +
    ggtitle("Bias for ILI targets")

ggplot(tab1, aes(x=reorder(model_name, X=mse), y=mse, color=factor(season))) + 
    geom_point() + 
    facet_wrap(~target) +
    scale_y_log10() +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5)) +
    ggtitle("MSE for ILI targets")

ggplot(tab1, aes(x=reorder(model_name, X=rmse), y=rmse, color=factor(season))) + 
    geom_point() + 
    facet_wrap(~target) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5)) +
    ggtitle("RMSE for ILI targets")


### analysis by region
tab_by_reg <- tbl_df(ests) %>% 
    group_by(model_name, target, location) %>%
    dplyr::filter(!(target %in% c("Season onset", "Season peak week"))) %>%
    summarize(
        nobs = n(),
        bias = mean(err, na.rm=TRUE),
        mse = mean(err^2, na.rm=TRUE))

ggplot(tab_by_reg, aes(x=reorder(model_name, X = abs(bias)), y=bias, color=factor(location))) + 
    geom_point() + 
    facet_wrap(~target) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5)) +
    ggtitle("Bias for ILI targets")

ggplot(tab_by_reg, aes(x=reorder(model_name, X=mse), y=mse, color=factor(location))) + 
    geom_point() + 
    facet_wrap(~target) +
    scale_y_log10() +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5)) +
    ggtitle("MSE for ILI targets")
