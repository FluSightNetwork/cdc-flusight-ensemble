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
  cache.invalidation.period=as.difftime(1L, units="weeks")
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
## fluview.history.l.dfs =
##   fluview.location.epidata.names %>>%
##   setNames(fluview.location.spreadsheet.names) %>>%
##   lapply(function(fluview.location.epidata.name) {
##     fetchEpidataHistoryDF(
##       "fluview", fluview.location.epidata.name, 0:51,
##       first.week.of.season=usa.flu.first.week.of.season,
##       cache.file.prefix=file.path(epidata.cache.dir,paste0("fluview_",fluview.location.epidata.name))
##     )
##   })

##' Fetch settings needed for target calculations
##'
##' Get the baseline (onset threshold) wILI (length-1 numeric), flags for
##' in-season weeks (52/53-length logical vector), and "time of forecast"
##' (length-1 integer) --- time 1 is week 31, time 2 is week 32, etc.
flusight2016_settings = function(forecast.epiweek, forecast.Location) {
  forecast.smw = epiforecast:::yearWeekToSeasonModelWeekDF(
                                 forecast.epiweek%/%100L, forecast.epiweek%%100L,
                                 40L, 3L)
  mimicked.baseline = epiforecast::mimicPastDF(
                                     fluview.baseline.df,
                                     "season.int", forecast.smw[["season"]],
                                     nontime.index.colnames="Location") %>>%
    with(baseline[Location==forecast.Location])
  n.weeks.in.season = epiforecast::lastWeekNumber(forecast.smw[["season"]], 3L)
  is.inseason = usa_flu_inseason_flags(n.weeks.in.season)
  mimicked.time.of.forecast = model_week_to_time(forecast.smw[["model.week"]],
                                                 usa.flu.first.week.of.season)
  flusight2016.settings = list(
    baseline=mimicked.baseline,
    is.inseason=is.inseason,
    target.time.of.forecast=mimicked.time.of.forecast
  )
  return (flusight2016.settings)
}

## Set weeks & locations & targets for which to perform calculations:
input.epiweeks = 2010:2016 %>>%
  epiforecast::DatesOfSeason(40L,0L,3L) %>>%
  dplyr::combine() %>>%
  epiforecast::DateToYearWeekWdayDF(0L,3L) %>>%
  dplyr::filter(! week %>>% dplyr::between(21L,39L)) %>>%
  with(year*100L+week)
input.Locations = fluview.location.spreadsheet.names
input.targets = epiforecast:::flusight2016.targets

## This is slow for some reason, so set up parallelism:
options(mc.cores=parallel::detectCores()-1L)

target.multival.df =
  ## for each input epiweek...
  input.epiweeks %>>%
  parallel::mclapply(function(input.epiweek) {
    print(input.epiweek) # progress indicator
    ## calculate other types of timing information:
    input.year = input.epiweek %/% 100L
    input.week = input.epiweek %% 100L
    input.smw = epiforecast:::yearWeekToSeasonModelWeekDF(input.year, input.week, 40L, 3L)
    input.season = input.smw[["season"]]
    input.model.week = input.smw[["model.week"]]
    input.Season = paste0(input.season, "/", input.season+1L)
    ## for each input Location...
    input.Locations %>>% stats::setNames(input.Locations) %>>%
      lapply(function(input.Location) {
        ## get trajectory, round it, get Season & Location specific settings:
        trajectory = fluview.current.l.dfs[[input.Location]] %>>%
          with(wili[season==input.season])
        rounded.trajectory = epiforecast:::flusight2016_target_trajectory_preprocessor(trajectory)
        target.settings = flusight2016_settings(input.epiweek, input.Location)
        ## calculate the valid target values, convert to Bin_start_incl string
        ## representations with some indexing information:
        input.targets %>>%
          lapply(function(input.target) {
            ## multival: list of valid value(s) using target-specific class:
            multival = do.call(input.target[["for_processed_trajectory"]],
                               c(list(rounded.trajectory),
                                 target.settings))
            ## valid.bin.starts: corresponding Bin_start_incl string(s)
            valid.bin.starts = do.call(input.target[["unit"]][["to_string"]],
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
