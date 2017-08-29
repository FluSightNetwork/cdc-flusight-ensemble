library(ggplot2)
library(dplyr)
library(plotly)

scores <- read.csv("scores.csv")

## one-week ahead
(p <- ggplot(filter(scores, score=="log")) +
    geom_line(aes(x=as.numeric(season), y=oneWk, color=model)) +
    facet_wrap(~region))
ggplotly(p)

## two-week ahead
(p <- ggplot(filter(scores, score=="log")) +
        geom_line(aes(x=as.numeric(season), y=twoWk, color=model)) +
        facet_wrap(~region))
ggplotly(p)

## two-week ahead
(p <- ggplot(filter(scores, score=="mae")) +
        geom_line(aes(x=as.numeric(season), y=twoWk, color=model)) +
        facet_wrap(~region))
ggplotly(p)
