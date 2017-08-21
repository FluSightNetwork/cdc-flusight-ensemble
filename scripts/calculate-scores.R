library(jsonlite)
library(dplyr)

tt <- jsonlite::fromJSON("scores/2010-2011.json")


ttt <- do.call(rbind, tt[[2:length(tt)]])
