/**
 * Script for generating model-id to directory name mappings
 */

const models = require('./modules/models')
const util = require('./modules/util')
const path = require('path')
const fs = require('fs')
const mmwr = require('mmwr-week')

// NOTE: We only generate mappings for component models as others are not used
const modelParents = [
  'component-models'
]

/**
 * Return season string
 */
const epiweekToSeason = (timeData) => {
  // HACK: Should fix main int-str thingy
  let year = parseInt(timeData.year)
  let epiweek = parseInt(timeData.epiweek)
  return (epiweek < 40) ? `${year-1}/${year}` : `${year}/${year+1}`
}

/**
 * Return unique seasons represented in all the model directories
 */
const getSeasons = modelDirs => {
  let seasons = []
  modelDirs.forEach(md => {
    seasons = seasons.concat(models.getModelCsvs(md).map(models.getCsvTime).map(epiweekToSeason))
  })

  return util.unique(seasons)
}

/**
 * Return number of expected weeks to look in a season
 */
const weeksInSeason = season => {
  let firstYear = parseInt(season.split('/')[0])
  let totalWeeks = (new mmwr.MMWRDate(firstYear)).nWeeks
  // Subtract the weeks not used
  return totalWeeks - 19
}

/**
 * Tell if the model has complete number of files
 */
const isModelComplete = (modelDir, season) => {
  return weeksInSeason(season) === models.getModelCsvs(modelDir)
    .map(models.getCsvTime)
    .map(epiweekToSeason)
    .filter(s => s === season).length
}

const getModelIdPair = modelDir => {
  return [models.getModelId(modelDir), path.basename(modelDir)]
}

const writeCSV = (header, lines, filename) => {
  fs.writeFile(filename, [header, ...lines].join('\n'), err => {
    if (err) { throw err }
  })
}

modelParents.forEach(parentDir => {
  let rootPath = './model-forecasts'
  let modelDirs = models.getModelDirs(rootPath, [parentDir])
  let seasons = getSeasons(modelDirs)

  let header = 'season,model-id,model-dir'
  let lines = []
  seasons.forEach(season => {
    // Filter models
    let filteredModelDirs = modelDirs.filter(md => isModelComplete(md, season))
    console.log(`Skipping ${modelDirs.length - filteredModelDirs.length} models for season ${season}, parent dir ${parentDir}`)
    let pairs = filteredModelDirs.map(getModelIdPair)
    pairs.forEach(pair => {
      lines.push(`${season},${pair[0]},${pair[1]}`)
    })
  })

  let outputFile = path.join(rootPath, parentDir, 'complete-modelids\.csv')
  writeCSV(header, lines, outputFile)
})
