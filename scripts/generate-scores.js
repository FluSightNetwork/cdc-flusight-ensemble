/**
 * Script for generating scores spreadsheet using the ground truth file
 */

const d3 = require('d3')
const Papa = require('papaparse')
const fs = require('fs')
const path = require('path')
const yaml = require('js-yaml')

const truthFile = './scores/target-multivals.csv'
const outputFile = './scores/scores.csv'

const whitelisted_directories = [
  '.git',
  'plots',
  'scores',
  'scripts',
  'templates',
  'flusight-deploy',
  'node_modules'
]

const regions = [
  'US National',
  'HHS Region 1',
  'HHS Region 2',
  'HHS Region 3',
  'HHS Region 4',
  'HHS Region 5',
  'HHS Region 6',
  'HHS Region 7',
  'HHS Region 8',
  'HHS Region 9',
  'HHS Region 10'
]

const targets = [
  'Season onset',
  'Season peak week',
  'Season peak percentage',
  '1 wk ahead',
  '2 wk ahead',
  '3 wk ahead',
  '4 wk ahead'
]

/**
 * Return model directories
 */
const getModelDirs = rootDir => {
  return fs.readdirSync(rootDir).filter(item => {
    return (fs.statSync(item).isDirectory() && whitelisted_directories.indexOf(item) === -1)
  })
}

/**
 * Return model id from modelDir
 */
const getModelId = modelDir => {
  let config = yaml.load(fs.readFileSync(path.join(modelDir, 'metadata.txt'), 'utf8'))
  return `${config.team_name}-${config.model_abbr}`
}

/**
 * Return timing information about the csv
 */
const getCsvTime = csvFile => {
  let baseName = path.basename(csvFile)
  let [week, year, ] = baseName.split('-')
  return {
    week: parseInt(week.slice(2)) + '',
    year: year
  }
}

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

  // Year,, Calendar Week, ,Season, Model Week, Location, Target, Valid Bin_start_incl
  return d3.nest()
    .key(d => d[0]) // year
    .key(d => d[1]) // week
    .key(d => d[4]) // region
    .key(d => d[5]) // target
    .object(data)
}

const getModelCsvs = modelDir => {
  return fs.readdirSync(modelDir)
    .filter(item => item.endsWith('csv'))
    .map(fileName => path.join(modelDir, fileName))
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
  'Location',
  'Target',
  'Score'
]

let outputLines = [header.join(', ')]
let trueData = getTrueData(truthFile)

getModelDirs('./').forEach(modelDir => {
  let modelId = getModelId(modelDir)
  console.log(` > Parsing model ${modelDir}`)
  let csvs = getModelCsvs(modelDir)
  console.log(`     Model provides ${csvs.length} CSVs`)

  csvs.forEach(csvFile => {
    let {year, week} = getCsvTime(csvFile)
    let csvData = getCsvData(csvFile)
    regions.forEach(region => {
      targets.forEach(target => {
        let trueTargets = trueData[year][week][region][target]
        let trueBinStarts = trueTargets.map(tt => parseFloat(tt[6]))
        let modelProbabilities = csvData[region][target]
        try {
          let binProbs = getBinProbabilities(modelProbabilities, trueBinStarts)
          let score = binProbs.map(Math.log).reduce((a, b) => a + b, 0)
          outputLines.push(`${modelId}, ${year}, ${week}, ${region}, ${target}, ${score === -Infinity ? 'NaN' : score}`)
        } catch (e) {
          console.log(` # Some error in ${modelId} ${year}-${week} for ${region}, ${target}`)
          process.exit(1)
        }
      })
    })
  })
})

fs.writeFile(outputFile, outputLines.join('\n'), err => {
  if (err) {
    throw err
  }
  console.log(' > Output written')
})
