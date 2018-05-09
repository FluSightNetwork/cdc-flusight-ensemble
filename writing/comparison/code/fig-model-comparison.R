library(dplyr)
library(readr)
library(ggplot2)
theme_set(theme_minimal())


scores <- read_csv("../../scores/scores.csv")
models <- read_csv("../../model-forecasts/component-models/model-id-map.csv")
complete_models <- c(models$`model-id`[models$complete=="true"], "UTAustin-edm")

## define column with scores of interest
SCORE_COL <- quo(`Multi bin score`)

all_target_bounds <- read_csv("data/all-target-bounds.csv")

## Remove scores that fall outside of evaluation period for a given target/season
scores_trimmed <- scores %>%
  dplyr::left_join(all_target_bounds, by = c("Season", "Target", "Location")) %>%
  dplyr::filter(`Model Week` >= start_week_seq, `Model Week` <= end_week_seq)


scores_adj <- scores_trimmed %>%
  filter(Model %in% complete_models) %>%
  ## if NA, NaN or <-10, set score to -10
  mutate(score_adj = dplyr::if_else(is.nan(!!SCORE_COL) | is.na(!!SCORE_COL) , 
                                    -10, 
                                    !!SCORE_COL),
         target_type = dplyr::if_else(Target %in% c("Season onset", "Season peak week", "Season peak percentage"),
                                      "seasonal", "k-week-ahead")) %>%
  mutate(score_adj = dplyr::if_else(score_adj < -10 , -10, score_adj)) 

scores_by_region <- scores_adj %>%
  group_by(Model, Location, target_type) %>%
  dplyr::summarize(
    avg_score = mean(score_adj),
    skill = exp(avg_score)
  ) %>%
  ungroup() %>%
  mutate(
    Model = reorder(Model, skill),
    Location = factor(Location, levels=c("US National", paste("HHS Region", 1:10))))


library(cdcfluview)
library(fiftystater)
data("fifty_states")

data(hhs_regions)
scores_by_region <- scores_by_region %>% 
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
  scale_fill_gradient(low="lavender", high="navy") + 
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
  #ggtitle("K-week Ahead Targets") + 
  #theme(plot.title = element_text(hjust = 0.5))
  #theme(legend.position = "none", 
   #     panel.background = element_blank())

p2 <- hhs_regions %>% 
  filter(Model != "ReichLab-KDE", target_type == "seasonal") %>% 
  ggplot(aes(map_id = state)) + 
  geom_map(aes(fill = skill), map = fifty_states) +
  scale_fill_gradient(low="lavender", high="navy") + 
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
  #ggtitle("Seasonal Targets") + 
  #theme(plot.title = element_text(hjust = 0.5))
#theme(legend.position = "none", 
#     panel.background = element_blank())

p3 <- hhs_regions %>% 
  filter(Model == "ReichLab-KDE", target_type == "k-week-ahead") %>% 
  ggplot(aes(map_id = state)) + 
  geom_map(aes(fill = skill), map = fifty_states) +
  scale_fill_gradient(low="lavender", high="navy") + 
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

p4 <- hhs_regions %>% 
  filter(Model == "ReichLab-KDE", target_type == "seasonal") %>% 
  ggplot(aes(map_id = state)) + 
  geom_map(aes(fill = skill), map = fifty_states) +
  scale_fill_gradient(low="lavender", high="navy") + 
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

scores_by_season_region_and_target <- scores_adj %>%
  group_by(Model, Season, Location, target_type) %>%
  dplyr::summarize(
    avg_score = mean(score_adj),
    min_score = min(score_adj)
  ) %>%
  ungroup() %>%
  mutate(Model = reorder(Model, avg_score))

scores_kde <- scores_by_season_region_and_target %>% 
  filter(Model == "ReichLab-KDE")

scores_other <- scores_by_season_region_and_target %>% 
  filter(Model != "ReichLab-KDE") %>% 
  group_by(Location, Season, target_type) %>% 
  summarise(avg_score_other = mean(avg_score))

dat <- merge(scores_kde, scores_other)

p5 <- dat %>%
  filter(target_type == "k-week-ahead") %>% 
  ggplot(aes(x = exp(avg_score), y = exp(avg_score_other))) + 
  geom_point(aes(col = Season)) + 
  geom_smooth() +
  labs(x = "KDE Model Skill", y="Non-KDE Model Average Skill") + 
  #theme(legend.position = "none")

p6 <- dat %>%
  filter(target_type == "seasonal") %>% 
  ggplot(aes(x = exp(avg_score), y = exp(avg_score_other))) + 
  geom_point(aes(col = Season)) + 
  geom_smooth() + 
  labs(x = "KDE Model Skill", y="Non-KDE Model Average Skill")

## create fig - fix labeling and legend 
library(grid)
library(gridExtra)
library(cowplot)
library(ggpubr)
title <- ggdraw() + draw_label("Model Scores by Region", fontface='bold')

#legend but no labeling
gg1 <- ggarrange(p1, p2, p3, p4, ncol=2, nrow=2, common.legend = TRUE, 
                 legend="right", labels = labs, hjust = c(-0.5, -0.5, -0.6, -0.6), 
                 font.label = list(size = 12, face = "bold", color ="black"))
gg2 <- ggarrange(p5, p6, ncol=2, common.legend = TRUE, legend="right", 
                 labels = c("K-Week Ahead", "Seasonal"), hjust = c(-1, -1.3),
                 font.label = list(size = 12, face = "bold", color ="black"))
p.1 <- plot_grid(title, gg1, gg2, ncol = 1, rel_heights=c(0.1, 2, 1))
p.1

#labeling but no legend
g1 <- arrangeGrob(p1, top=textGrob("K-Week Ahead Targets", gp=gpar(fontsize=12,fontface="bold")), left = textGrob("Non-KDE", gp=gpar(fontsize=12,fontface="bold")))
g2 <- arrangeGrob(p2, top = textGrob("Seasonal Targets", gp=gpar(fontsize=12,fontface="bold")))
g3 <- arrangeGrob(p3, left = textGrob("KDE", gp=gpar(fontsize=12,fontface="bold")))
gg3 <- grid.arrange(g1, g2, g3, p4, ncol=2, nrow=2)
gg4 <- grid.arrange(p5, p6, ncol=2)
p.2 <- grid.arrange(title, gg3, gg4, heights=c(0.1, 2, 1))
p.2                
