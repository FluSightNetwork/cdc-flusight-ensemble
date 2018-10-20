library(dplyr)
library(readr)
library(ggplot2)
theme_set(theme_minimal())
library(cdcfluview)
library(fiftystater)
library(mapproj)

scores_by_model_targettype_region <- readRDS('./data/scores_by_model_season_targettype_region.rds')

data("fifty_states")

data(hhs_regions)
scores_by_region <- scores_by_model_targettype_region %>% 
    filter(Location != "US National")
scores_by_region$region_number <- gsub("[^0-9]", "", scores_by_region$Location)
not_50 <- c(9, 10, 12, 50:55)
hhs_regions <- hhs_regions[-(not_50),]
hhs_regions <- merge(hhs_regions, scores_by_region, by = "region_number")
hhs_regions$state <- tolower(hhs_regions$state_or_territory)

p1 <- hhs_regions %>% 
    filter(Model != "ReichLab-KDE", target_type == "k-week-ahead") %>% 
    ggplot(aes(map_id = state)) + 
    geom_map(aes(fill = skill), map = fifty_states) +
    scale_fill_gradient(low="#f7fbff", high="#084594", limits=c(0,1)) + 
    expand_limits(x = fifty_states$long, y = fifty_states$lat) +
    coord_map() +
    annotate("text", x = -118, y =  45, label = "10") +
    annotate("text", x = -119.48333, y =  40, label = "9") +
    annotate("text", x = -105.48333, y =  44, label = "8") +
    annotate("text", x = -92.1, y =  45, label = "5") +
    annotate("text", x = -97, y =  40, label = "7") +
    annotate("text", x = -101, y =  35, label = "6") +
    annotate("text", x = -85, y =  35, label = "4") +
    annotate("text", x = -78.4, y =  38.5, label = "3") +
    annotate("text", x = -76, y =  42.75, label = "2") +
    annotate("text", x = -69.5, y =  44.95, label = "1") +
    scale_x_continuous(breaks = NULL) + 
    scale_y_continuous(breaks = NULL) +
    labs(x = NULL, y = NULL) 
#theme(legend.position = "none", 
#     panel.background = element_blank())
