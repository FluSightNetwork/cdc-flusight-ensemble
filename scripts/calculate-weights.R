library("pipeR")
library("dplyr")
library("epiforecast") 
library("cdcfluview")
## devtools::install_github("cmu-delphi/epiforecast-R", subdir="epiforecast")

## make equal weights file separately
source("make-equal-weights.R")

## set column to use for calculating weights
SCORE_COL <- quo(`Multi bin score`)

## Set up parallel:
options(mc.cores=parallel::detectCores()-1L)

## Specify target types:
target.types.list = list(
  "seasonal"=c("Season onset", "Season peak week", "Season peak percentage"),
  "weekly"=paste0(1:4," wk ahead")
)

## Specify portions of cv_apply indexer lists corresponding to Location, Target:
weighting.scheme.partial.indexer.lists = list(
  "constant" = list(all=NULL, all=NULL),
  "target-type-based" = list(all=NULL, subsets=target.types.list),
  "target-based" = list(all=NULL, each=NULL),
  "target-and-region-based" = list(each=NULL, each=NULL)
)

## Read in & tweak scores.csv
component.score.df = read.csv("../scores/scores.csv", check.names=FALSE, stringsAsFactors=FALSE) %>>%
  tibble::as_tibble() %>>%
  dplyr::filter(!grepl('FSNetwork', Model)) %>>% ## drop ensemble models!
  dplyr::mutate(score_to_optimize = dplyr::if_else(is.nan(!!SCORE_COL), -10, !!SCORE_COL)) %>>%
  dplyr::mutate(score_to_optimize = dplyr::if_else(score_to_optimize < -10 , -10, score_to_optimize)) %>>%
  dplyr::mutate(Metric = "some log score") %>>%
  {.}

## Create data.frame of boundary weeks of scores to keep for each target/season
source("create-scoring-period.R")
all.target.bounds = create_scoring_period()

## Remove scores that fall outside of evaluation period for a given target/season
component.score.df.trim <- component.score.df %>%
  dplyr::left_join(all.target.bounds, by = c("Season", "Target", "Location")) %>%
  dplyr::filter(`Model Week` >= start_week_seq, `Model Week` <= end_week_seq)

## Perform some checks:
if (any(is.na(component.score.df.trim[["score_to_optimize"]]))) {
  stop ("No NA's are allowed for the component")
}
multiple.entry.df =
  component.score.df.trim %>>%
  dplyr::group_by(Season, `Model Week`, Location, Target, Metric, Model) %>>%
  dplyr::filter(n()!=1L) %>>%
  dplyr::mutate(`Entry Count`=n()) %>>%
  dplyr::ungroup() %>>%
  {.}
if (nrow(multiple.entry.df) != 0L) {
  stop ("There should not be multiple Score's for the same Season, `Model Week`, Location, Target, Metric, and Model.")
}

## Cast to array, introducing NA's for missing entries in Cartesian product:
component.score.array =
  component.score.df.trim %>>%
  reshape2::acast(Season ~ `Model Week` ~ Location ~ Target ~ Metric ~ Model, value.var="score_to_optimize") %>>%
  {names(dimnames(.)) <- c("Season", "Model Week", "Location", "Target", "Metric", "Model"); .}

## Replace NA's corresponding to incomplete sets of forecasts with -10's:
n.models = length(dimnames(component.score.array)[["Model"]])
na.score.counts = apply(is.na(component.score.array), 1:5, sum)
incomplete.forecast.set.flags = ! na.score.counts %in% c(0L, n.models)
if (any(incomplete.forecast.set.flags)) {
  warning("Some models have incomplete sets of forecasts; assigning them scores of -10 for those weeks.")
  incomplete.forecast.score.flags =
    rep(incomplete.forecast.set.flags, n.models) &
    is.na(component.score.array)
  dim(incomplete.forecast.score.flags) <- dim(component.score.array)
  dimnames(incomplete.forecast.score.flags) <- dimnames(component.score.array)
  print(apply(incomplete.forecast.score.flags, 6L, sum))
  component.score.array[incomplete.forecast.score.flags] <- -10
}
## All NA's should now correspond to missing model week 73 scores for seasons
## the don't include a model week 73.

neginf.score.counts = apply(!is.na(component.score.array) &
                            component.score.array == -Inf, 1:5, sum)
neginf.forecast.set.flags = neginf.score.counts == n.models
if (any(neginf.forecast.set.flags)) {
  apply(neginf.forecast.set.flags, 2L, sum)
  stop ("Either there is some instance where all models received a log score of -Inf, or there was a bug in preparing the component score array.")
}

## na.score.countsp = apply(is.na(component.score.array), 1:5, sum)
## na.forecast.set.flagsp = na.score.countsp != 0L
## apply(na.forecast.set.flagsp, 2L, sum)

## Indexer lists for prospective forecasts:
weighting.scheme.prospective.indexer.lists =
  weighting.scheme.partial.indexer.lists %>>%
  lapply(function(partial.indexer.list) {
    c(list(all=NULL, all=NULL), # Season, Model Week
      partial.indexer.list, # Location, Target
      list(all=NULL), # Metric
      list(all=NULL) # Model should always be all=NULL
      )
  })

## Indexer lists for CV forecasts:
weighting.scheme.cv.indexer.lists =
  weighting.scheme.partial.indexer.lists %>>%
  lapply(function(partial.indexer.list) {
    c(list(loo=NULL, all=NULL), # Season, Model Week
      partial.indexer.list, # Location, Target
      list(all=NULL), # Metric
      list(all=NULL) # Model should always be all=NULL
      )
  })

generate_indexer_list_weights = function(component.score.array, indexer.list) {
  component.score.array %>>%
    cv_apply(
      indexer.list,
      function(train, test) {
        if (!identical(dimnames(train)[[5L]], "some log score")) {
          stop ('Weighting routine only supports optimizing for "some log score".')
        }
        instance.method.score.mat =
          R.utils::wrap(train, list(1:5,6L))
        na.counts = rowSums(is.na(instance.method.score.mat))
        if (any(! na.counts %in% c(0L, ncol(instance.method.score.mat)))) {
          stop ("NA appeared in probability matrix, but not from nonexistent EW53.")
        }
        instance.method.score.mat <- instance.method.score.mat[na.counts==0L,,drop=FALSE]
        neginf.counts = rowSums(instance.method.score.mat==-Inf)
        if (any(neginf.counts == ncol(instance.method.score.mat))) {
          print(names(neginf.counts)[neginf.counts==ncol(instance.method.score.mat)])
          stop ("All methods assigned a log score of -Inf for some instance.")
        }
        degenerate.em.weights = epiforecast:::degenerate_em_weights(exp(instance.method.score.mat))
        return (degenerate.em.weights)
      },
      parallel_dim_i=1L # use parallelism across seasons (only helps for LOSOCV)
    ) %>>%
    ## --- Fix up dim, dimnames: ---
    {
      d = dim(.)
      dn = dimnames(.)
      ## Remove Model="all" dimension:
      stopifnot(identical(tail(dn, 1L), list(Model="all")))
      new.d = head(d, -1L)
      new.dn = head(dn, -1L)
      ## Call the new, unnamed dim 1 "Model":
      stopifnot(identical(
        head(dn, 1L),
        stats::setNames(dimnames(component.score.array)["Model"], "")))
      names(new.dn)[[1L]] <- "Model"
      dim(.) <- new.d
      dimnames(.) <- new.dn
      .
    } %>>%
    ## --- Convert to data.frame with desired format: ---
    {
      ## Rename dimensions:
      stopifnot(identical(
        names(dimnames(.)),
        c("Model", "Season", "Model Week", "Location", "Target", "Metric")
      ))
      names(dimnames(.)) <-
        c("component_model_id","season","Model Week","location","target","Metric")
      ## Drop ="all" dimensions:
      d = dim(.)
      dn = dimnames(.)
      keep.dim.flags = !sapply(dn, identical, "all")
      dim(.) <- d[keep.dim.flags]
      dimnames(.) <- dn[keep.dim.flags]
      .
    } %>>%
    ## Melt into tibble:
    reshape2::melt(value.name="weight") %>>% tibble::as_tibble() %>>%
    dplyr::mutate_if(is.factor, as.character) %>>%
    {.}
}

## Target-type df:
target.types.df =
  lapply(target.types.list, tibble::as_tibble) %>>%
  dplyr::bind_rows(.id="target.type") %>>%
  dplyr::rename(target=value)

## Generate the weight files:
for (weighting.scheme.i in seq_along(weighting.scheme.partial.indexer.lists)) {
  ## extract info from lists:
  weighting.scheme.name = names(weighting.scheme.partial.indexer.lists)[[weighting.scheme.i]]
  weighting.scheme.cv.indexer.list = weighting.scheme.cv.indexer.lists[[weighting.scheme.i]]
  weighting.scheme.prospective.indexer.list = weighting.scheme.prospective.indexer.lists[[weighting.scheme.i]]
  print(weighting.scheme.name)
  ## determine season label for next season:
  cv.season.ints = as.integer(gsub("/.*","",dimnames(component.score.array)[["Season"]]))
  prospective.season.int = max(cv.season.ints) + 1L
  prospective.season.label = prospective.season.int %>>% paste0("/",.+1L)
  ## generate weight df's and bind together:
  cv.weight.df = generate_indexer_list_weights(
    component.score.array, weighting.scheme.cv.indexer.list
  )
  prospective.weight.df = generate_indexer_list_weights(
    component.score.array, weighting.scheme.prospective.indexer.list
  ) %>>%
    dplyr::mutate(season=prospective.season.label)
  combined.weight.df =
    dplyr::bind_rows(cv.weight.df, prospective.weight.df)
  ## expand out target types if applicable:
  if ("target" %in% names(combined.weight.df)) {
    combined.weight.df <-
      combined.weight.df %>>%
      dplyr::rename(target.type=target) %>>%
      dplyr::left_join(
               dimnames(component.score.array)[["Target"]] %>>%
               {tibble::tibble(target.type=., target=.)} %>>%
               dplyr::bind_rows(target.types.df),
               by = "target.type"
             ) %>>%
      dplyr::select(-target.type) %>>%
      ## restore original column order:
      magrittr::extract(names(combined.weight.df))
  }
  ## print weight df and write to csv file:
  print(combined.weight.df)
  write.csv(combined.weight.df, file.path("..","weights",paste0(weighting.scheme.name,"-weights.csv")), row.names = FALSE, quote=FALSE)
}
