## equal weights data-frame

library(dplyr)

model_names <- read.csv("../model-forecasts/component-models/model-id-map.csv",
    stringsAsFactors = FALSE)
seasons <- paste0(2010:2016, "/", 2011:2017)

weights <- expand.grid(
    component_model_id = model_names$model.id,
    season = seasons,
    weight = 1/nrow(model_names)
    ) # Season * Model

write.csv(weights, file="../scores/equal-weights.csv", 
    quote = FALSE, row.names = FALSE)
