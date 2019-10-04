## script to move last year's forecast files from `real-time-component-models` into `component-models`
## Nicholas Reich
## October 2019


## decide to move all models over and they can be over-written later
toplevel_dir_to_move_files_from <- "model-forecasts/real-time-component-models"
toplevel_dir_to_move_files_to <- "model-forecasts/component-models"
dirs_to_move_files_from <- list.dirs(toplevel_dir_to_move_files_from, full.name = FALSE, recursive=FALSE)
dirs_to_move_files_to <- list.dirs(toplevel_dir_to_move_files_to, full.name = FALSE, recursive=FALSE)

## check that all source directories have a destination, then move files
for(dir in dirs_to_move_files_from) {
    if(!(dir %in% dirs_to_move_files_to)){
        warning(paste("the directory", dir, "is not in the destination directory"))
        next()
    }
    cmd <- paste0("mv ", 
        file.path(toplevel_dir_to_move_files_from, dir), "/*.csv ", 
        file.path(toplevel_dir_to_move_files_to, dir))
    system(cmd)
}
