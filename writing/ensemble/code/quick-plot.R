## 2017-2018 score analysis

library(ggplot2)
library(dplyr)

scores_aggr <- eval_scores_1718 %>%
    group_by(team, target) %>%
    summarize(
        avg_score = mean(score),
        skill = exp(avg_score)
    ) %>%
    ungroup() %>%
    mutate(Model = reorder(team, avg_score))


midpt <- exp(mean(filter(scores_aggr, team=="ReichLab_kde")$avg_score))
ggplot(scores_aggr, aes(x=target, y=Model, fill=skill)) +
    geom_tile() + ylab(NULL) + xlab(NULL) +
    geom_text(aes(label=round(skill, 2))) +
    scale_fill_gradient2(midpoint = midpt) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
    ggtitle("Average model scores by target, 2017-2018")

