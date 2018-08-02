## Create data.frame of boundary weeks of scores to keep for each target/season
source("../../scripts/create-scoring-period.R")
all_target_bounds = create_scoring_period(
    baselinefile = "../../baselines/wILI_Baseline.csv",
    scoresfile = "../../scores/target-multivals-20172018.csv")

write.csv(all_target_bounds, file="data/all-target-bounds.csv", row.names = FALSE, quote=FALSE)
