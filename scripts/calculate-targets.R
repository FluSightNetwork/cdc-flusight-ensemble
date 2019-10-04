library("pipeR")
library("epiforecast")

## Different location naming schemes:
fluview.location.epidata.names = c("nat", paste0("hhs",1:10))
fluview.location.spreadsheet.names = c("US National", paste0("HHS Region ",1:10))

## Load in the baselines and epidata:
epidata.cache.dir = "~/.epiforecast-cache"
if (!dir.exists(epidata.cache.dir)) {
  dir.create(epidata.cache.dir)
}
fluview.baseline.info = fetchUpdatingResource(
  function() {
    LICENSE=RCurl::getURL("https://raw.githubusercontent.com/cdcepi/FluSight-forecasts/master/LICENSE")
    wILI_Baseline=read.csv(textConnection(RCurl::getURL("https://raw.githubusercontent.com/cdcepi/FluSight-forecasts/master/wILI_Baseline.csv")), row.names=1L, check.names=FALSE, stringsAsFactors=FALSE)
    ## xxx extra comma in current file (2018-10-17) misaligns data! use fixup file for now & force cache invalidation:
    ## wILI_Baseline=read.csv("wILI_Baseline_fixup.csv", row.names=1L, check.names=FALSE, stringsAsFactors=FALSE)
    cat("LICENSE for wILI_Baseline.csv:")
    cat(LICENSE)
    return (list(
      LICENSE=LICENSE,
      wILI_Baseline=wILI_Baseline
    ))
  },
  function(fetch.response) {
    return ()
  },
  cache.file.prefix=file.path(epidata.cache.dir,"fluview_baselines"),
  cache.invalidation.period=as.difftime(1L, units="weeks"),
  force.cache.invalidation=TRUE # xxx remove when reading from net again
)
fluview.baseline.ls.mat =
  fluview.baseline.info[["wILI_Baseline"]] %>>%
  as.matrix() %>>%
  ## Adjust rownames to match 2016/2017 spreadsheet Location names:
  magrittr::set_rownames(rownames(.) %>>%
                         stringr::str_replace_all("Region", "HHS Region ") %>>%
                         dplyr::recode("National"="US National")
                         ) %>>%
  ## Re-order rows so HHS Region i is at index i and US National is at 11L:
  magrittr::extract(c(2:11,1L),) %>>%
  ## Set dimnames names:
  structure(dimnames=dimnames(.) %>>%
              setNames(c("Location", "Season"))) %>>%
  {.}
fluview.baseline.df =
  reshape2::melt(fluview.baseline.ls.mat, value.name="baseline") %>>%
  dplyr::mutate(season.int=Season %>>%
                  as.character() %>>%
                  stringr::str_replace_all("/.*","") %>>%
                  as.integer()) %>>%
  {.}
fluview.current.l.dfs = fluview.location.epidata.names %>>%
  setNames(fluview.location.spreadsheet.names) %>>%
  lapply(function(fluview.location.epidata.name) {
  fetchEpidataDF(
    "fluview", fluview.location.epidata.name,
    first.week.of.season=usa.flu.first.week.of.season,
    cache.file.prefix=file.path(epidata.cache.dir,paste0("fluview_",fluview.location.epidata.name,"_",Sys.Date()))
  )
})
fluview.history.l.dfs =
  fluview.location.epidata.names %>>%
  setNames(fluview.location.spreadsheet.names) %>>%
  lapply(function(fluview.location.epidata.name) {
    fetchEpidataHistoryDF(
      "fluview", fluview.location.epidata.name, 0:51,
      first.week.of.season=usa.flu.first.week.of.season,
      cache.file.prefix=file.path(epidata.cache.dir,paste0("fluview_",fluview.location.epidata.name))
    )
  })

##' Fetch settings needed for target calculations
##'
##' Get the baseline (onset threshold) wILI (length-1 numeric), flags for
##' in-season weeks (52/53-length logical vector), and "time of forecast"
##' (length-1 integer) --- time 1 is week 31, time 2 is week 32, etc.
flusight2016_settings = function(forecast.epiweek, forecast.Location) {
  forecast.smw = epiforecast:::yearWeekToSeasonModelWeekDF(
                                 forecast.epiweek%/%100L, forecast.epiweek%%100L,
                                 usa.flu.first.week.of.season, 3L)
  mimicked.baseline = epiforecast::mimicPastDF(
                                     fluview.baseline.df,
                                     "season.int", forecast.smw[["season"]],
                                     nontime.index.colnames="Location") %>>%
    with(baseline[Location==forecast.Location])
  n.weeks.in.season = epiforecast::lastWeekNumber(forecast.smw[["season"]], 3L)
  is.inseason = usa_flu_inseason_flags(n.weeks.in.season)
  mimicked.forecast.time = model_week_to_time(forecast.smw[["model.week"]],
                                                 usa.flu.first.week.of.season)
  flusight2016.settings = list(
    baseline=mimicked.baseline,
    is.inseason=is.inseason,
    forecast.time=mimicked.forecast.time
  )
  return (flusight2016.settings)
}

get_evaluation_trajectory = function(history.df, eval.season, signal.name, df_processor) {
    ## Use week 28 data for evaluation:
    eval.issue = (eval.season+1L)*100L+28L
    epidata.df = mimicPastEpidataDF(history.df, eval.issue)
    ## xxx Perhaps a different version of mimicking should be used for evaluation, favoring >= eval.issue data over < eval.issue data instead of the other way around, which is used for pseudo-prospective forecast input data.  It would potentially be necessary to expand the number of lags included in the history fetches to ensure that this type of mimicking fetches the closest future version rather than skipping to the current version.
    observed.trajectory = epidata.df %>>%
        df_processor() %>>%
        dplyr::filter(season == eval.season) %>>%
        ## check that we are only using eval.issue data + NA's for the in-season, except for seasons before 2013 where we might use week 20 data instead of week 28 due to backfill record availability issues:
        (~ stopifnot(. %>>%
                     dplyr::filter(!dplyr::between(epiweek%%100L, 21L,39L)) %>>%
                     dplyr::filter(!is.na(.[[signal.name]])) %>>%
                     {all(eval.season >= 2013L & .[["issue"]] == eval.issue |
                          eval.season < 2013L & .[["issue"]] %in% c((eval.season+1L)*100L+20L, eval.issue))}
                     )) %>>%
        (~ stopifnot(. %>>%
                     dplyr::filter(epiweek <= eval.issue) %>>%
                     {all(!is.na(.[[signal.name]]))}
                     )) %>>%
        {.[[signal.name]]} %>>%
        ## target calculation routines refuse to continue with NAs in the
        ## trajectory; trick them by filling in missing data (should only be for weeks 29 and 30)
        ## with -Inf:
        dplyr::coalesce(-Inf)
    return (observed.trajectory)
}

## Set weeks & locations & targets for which to perform calculations:
input.seasons = 2010:2018 # last year needs to be incremented when calculating for the most recent year
input.epiweeks = input.seasons %>>%
  epiforecast::DatesOfSeason(usa.flu.first.week.of.season,0L,3L) %>>%
  dplyr::combine() %>>%
  epiforecast::DateToYearWeekWdayDF(0L,3L) %>>%
  dplyr::filter(! week %>>% dplyr::between(21L,39L)) %>>%
  with(year*100L+week)
input.Locations = fluview.location.spreadsheet.names
input.target.specs = flusight2016.target.specs

## This is slow for some reason, so set up parallelism:
options(mc.cores=parallel::detectCores()-1L)

ls.evaluation.trajectories =
    epiforecast:::map_join(get_evaluation_trajectory,
                           fluview.history.l.dfs %>>% with_dimnamesnames("Location"),
                           input.seasons %>>% with_dimnames(list(Season=paste0(.,"/",.+1L))),
                           "wili",
                           identity
                           )

target.multival.df =
  ## for each input epiweek...
  input.epiweeks %>>%
  lapply(function(input.epiweek) {
    print(input.epiweek) # progress indicator
    ## calculate other types of timing information:
    input.year = input.epiweek %/% 100L
    input.week = input.epiweek %% 100L
    input.smw = epiforecast:::yearWeekToSeasonModelWeekDF(input.year, input.week, usa.flu.first.week.of.season, 3L)
    input.season = input.smw[["season"]]
    input.model.week = input.smw[["model.week"]]
    input.Season = paste0(input.season, "/", input.season+1L)
    ## for each input Location...
    input.Locations %>>% stats::setNames(input.Locations) %>>%
      lapply(function(input.Location) {
        ## get trajectory, round it, get Season & Location specific settings:
        trajectory = ls.evaluation.trajectories[[input.Location, input.Season]]
        rounded.trajectory = flusight2016ilinet_target_trajectory_preprocessor(trajectory)
        target.settings = flusight2016_settings(input.epiweek, input.Location)
        ## calculate the valid target values, convert to Bin_start_incl string
        ## representations with some indexing information:
        input.target.specs %>>%
          lapply(function(input.target.spec) {
            ## multival: list of valid value(s) using target-specific class:
            multival = do.call(input.target.spec[["for_processed_trajectory"]],
                               c(list(rounded.trajectory),
                                 target.settings))
            ## valid.bin.starts: corresponding Bin_start_incl string(s)
            valid.bin.starts = do.call(input.target.spec[["unit"]][["to_binlabelstart"]],
                                       c(list(multival),
                                         target.settings))
            ## put in tibble with some indexing information
            tibble::tibble(
                      Year = input.year,
                      `Calendar Week` = input.week,
                      Season = input.Season,
                      `Model Week` = input.model.week,
                      `Valid Bin_start_incl` = valid.bin.starts
                    )
            ## bind everything together into a single tibble:
          }) %>>% dplyr::bind_rows(.id="Target")
      }) %>>% dplyr::bind_rows(.id="Location")
  }) %>>% dplyr::bind_rows() %>>%
  ## reorder columns:
  dplyr::select(Year, `Calendar Week`, Season, `Model Week`, Location, Target, `Valid Bin_start_incl`) %>>%
  {.}

## write the results:
readr::write_csv(target.multival.df, "../scores/target-multivals.csv")
