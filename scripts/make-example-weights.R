## example weights data-frame

library(dplyr)

model_names <- system("ls model-forecasts/component-models", intern=TRUE)
seasons <- paste0(2010:2016, "/", 2011:2017)

weights <- expand.grid(
    component_model_id = model_names,
    season = seasons,
    weight = 1/length(model_names)
    ) # Season * Model

write.csv(weights, file="scores/example-weights.csv", 
    quote = FALSE, row.names = FALSE)
