/**
 * Script for generating scores spreadsheet using the ground truth file
 */

const d3 = require('d3')
const Papa = require('papaparse')
const fs = require('fs')
const meta = require('./modules/meta')
const models = require('./modules/models')
const util = require('./modules/util')

const truthFile = './scores/target-multivals.csv'
const outputFile = './scores/scores.csv'
const errorBlacklistFile = './csv-blacklist.yaml'
const errorLogFile = './csv-error.log'

/**
 * Return csv data nested using d3.nest
 */
const getCsvData = (csvFile) => {
  let csvData = Papa.parse(fs.readFileSync(csvFile, 'utf8')).data
      .slice(1)
      .filter(d => !(d.length === 1 && d[0] === ''))

  // Location, Target, Type, Unit, Bin_start_incl, Bin_end_notincl, Value
  return d3.nest()
    .key(d => d[0]) // region
    .key(d => d[1]) // target
    .object(csvData)
}

/**
 * Return nested ground truth data
 */
const getTrueData = truthFile => {
  let data = Papa.parse(fs.readFileSync(truthFile, 'utf8')).data
      .slice(1)
      .filter(d => !(d.length === 1 && d[0] === ''))

  // Year, Calendar Week, Season, Model Week, Location, Target, Valid Bin_start_incl
  return d3.nest()
    .key(d => d[0]) // year
    .key(d => d[1]) // epiweek
    .key(d => d[4]) // region
    .key(d => d[5]) // target
    .object(data)
}

/**
 * Return probability assigned by model for given binStarts
 */
const getBinProbabilities = (csvDataSubset, binStarts) => {
  return binStarts.map(bs => {
    // Assuming we have a bin here
    let filteredRows = csvDataSubset.filter(row => parseFloat(row[4]) === bs)
    if (filteredRows.length === 0) {
      // This is mostly due to week 53 issue, the truth file has week 53 allowed,
      // while the models might not use a bin start using week 53.
      // We jump to week 1 here
      filteredRows = csvDataSubset.filter(row => parseFloat(row[4]) === 1.0)
    }
    return parseFloat(filteredRows[0][6])
  })
}

// E N T R Y  P O I N T
// For each model, for each csv (year, week), for each region, get the 7 targets
// and find log scores, append those to the output file.

// Clear output file
let header = [
  'Model',
  'Year',
  'Epiweek',
  'Season',
  'Model Week',
  'Location',
  'Target',
  'Score'
]

let outputLines = [header.join(',')]
let errorLogLines = []
let errorBlacklistLines = []
let trueData = getTrueData(truthFile)

// NOTE: For scores, we only consider these two directories
models.getModelDirs(
  './model-forecasts',
  ['component-models', 'cv-ensemble-models']
).forEach(modelDir => {
  let modelId = models.getModelId(modelDir)
  console.log(` > Parsing model ${modelDir}`)
  let csvs = models.getModelCsvs(modelDir)
  console.log(`     Model provides ${csvs.length} CSVs`)

  csvs.forEach(csvFile => {
    let {year, epiweek} = models.getCsvTime(csvFile)
    try {
      let csvData = getCsvData(csvFile)
      meta.regions.forEach(region => {
        meta.targets.forEach(target => {
          let trueTargets = trueData[year][epiweek][region][target]
          let trueBinStarts = trueTargets.map(tt => parseFloat(tt[6]))
          let season = trueTargets[0][2]
          let modelWeek = trueTargets[0][3]
          let modelProbabilities = csvData[region][target]
          try {
            let binProbs = getBinProbabilities(modelProbabilities, trueBinStarts)
            let score = binProbs.map(Math.log).reduce((a, b) => a + b, 0)
            outputLines.push(
              `${modelId},${year},${epiweek},${season},${modelWeek},${region},${target},${score === -Infinity ? 'NaN' : score}`
            )
          } catch (e) {
            errorLogLines.push(`Error in ${modelId} ${year}-${epiweek} for ${region}, ${target}`)
            errorLogLines.push(e.name)
            errorLogLines.push(e.message)
            errorLogLines.push('')
            errorBlacklistLines.push(`- ${csvFile}`)
            console.log(` # Error in ${modelId} ${year}-${epiweek} for ${region}, ${target}`)
            console.log(e)
          }
        })
      })
    } catch (e) {
      errorLogLines.push(`Error in ${csvFile}`)
      errorLogLines.push(e.name)
      errorLogLines.push(e.message)
      errorLogLines.push('')
      errorBlacklistLines.push(`- ${csvFile}`)
      console.log(` # Error in ${csvFile}`)
      console.log(e)
    }
  })
})

// The main scores.csv
util.writeLines(outputLines, outputFile)

// Error logs
util.writeLines(util.unique(errorBlacklistLines), errorBlacklistFile)
util.writeLines(errorLogLines, errorLogFile)
