## look at point estimate errors

library(dplyr)
library(readr)
library(ggplot2)

theme_set(theme_minimal())


ests <- read_csv("scores/point_ests.csv")

tab1 <- tbl_df(ests) %>% group_by(model_name, Target, Season) %>%
    dplyr::filter(!(Target %in% c("Season onset", "Season peak week"))) %>%
    summarize(
        nobs = n(),
        bias = mean(err, na.rm=TRUE),
        mse = mean(err^2, na.rm=TRUE))

ggplot(tab1, aes(x=reorder(model_name, X = bias), y=bias, color=factor(Season))) + 
    geom_point() + 
    facet_wrap(~Target) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5)) +
    ggtitle("Bias for ILI targets")

ggplot(tab1, aes(x=reorder(model_name, X=mse), y=mse, color=factor(Season))) + 
    geom_point() + 
    facet_wrap(~Target) +
    scale_y_log10() +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5)) +
    ggtitle("MSE for ILI targets")
