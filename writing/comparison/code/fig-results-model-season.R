## scatterplot with models on x-axis, skill on y

library(dplyr)
library(readr)
library(ggplot2)
theme_set(theme_minimal())

scores_by_model_season <- readRDS("./data/scores_by_model_season.rds")
scores_by_model <- readRDS("./data/scores_by_model.rds")

compartment_models <- c("CU-EAKFC_SEIRS", "CU-EAKFC_SIRS", "CU-EKF_SEIRS", 
    "CU-EKF_SIRS", "CU-RHF_SEIRS", "CU-RHF_SIRS", "LANL-DBM")

p <- ggplot(scores_by_model_season, aes(x=Model, y=skill)) +
    geom_point(alpha=.5, aes(color=Season)) + 
    geom_point(data=scores_by_model, shape="x", size=1, stroke=5)+
    scale_color_brewer(palette="Dark2") +
    ylab("average forecast skill") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5,
        face=ifelse(
            levels(scores_by_model_season$Model)%in% compartment_models,
            "bold", 
            "plain"
        ))) 

ggsave("./figures/fig-results-model-season.pdf", plot=p, device="pdf", width=8, height=5.5)
