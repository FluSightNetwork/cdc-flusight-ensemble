const yaml = require('js-yaml')
const fs = require('fs-extra')
const path = require('path')
const models = require('../scripts/modules/models')
const util = require('../scripts/modules/util')

const parseMetadata = (modelDir) => {
  // Return a flusight compatible metadata object
  let rootMetadata = models.getModelMetadata(modelDir)
  let desc = rootMetadata.methods
  let descMaxLen = 150
  if (desc.length > descMaxLen) {
    desc = desc.slice(0, descMaxLen) + '...'
  }
  let repoUrl = 'https://github.com/FluSightNetwork/cdc-flusight-ensemble'
  let metaPath = repoUrl + '/blob/master/' + path.join(modelDir.slice(3), 'metadata.txt')
  return {
    name: rootMetadata.team_name + ' - ' + rootMetadata.model_name,
    description: desc,
    url: metaPath
  }
}

const ensureMetadata = (filePath, data) => {
  if (!fs.existsSync(filePath)) {
    fs.writeFileSync(filePath, yaml.safeDump(data))
  }
}

const parseCSVInfo = (fileName) => {
  // Return season and formatted name for the csv
  let splits = fileName.split('-')
  let year = parseInt(splits[1])
  let epiweek = parseInt(splits[0].slice(2))

  // Week >=30 of year X are in season {X}-{X+1}
  // Week <30 of year Y are in season {Y-1}-{Y}
  return {
    name: `${year * 100 + epiweek}.csv`,
    season : epiweek >= 30 ? `${year}-${year+1}` : `${year-1}-${year}`
  }
}

// Main entry point
let modelDirs = models.getModelDirs(
  '../model-forecasts',
  ['component-models', 'real-time-ensemble-models']
)

// Load csv blacklist
let blacklistFile = '../csv-blacklist.yaml'
let blacklist = yaml.safeLoad(fs.readFileSync(blacklistFile, 'utf8'))
blacklist = blacklist ? blacklist.map(fn => '../' + fn) : []

modelDirs.forEach(modelDir => {
  // Read metadata and parse to usable form
  let flusightMetadata = parseMetadata(modelDir)
  let modelId = models.getModelId(modelDir)

  models.getModelCsvs(modelDir)
    .filter(csvFile => blacklist.indexOf(csvFile) === -1)
    .forEach(csvFile => {
      let info = parseCSVInfo(path.basename(csvFile))

      // CSV target path
      let csvTargetDir = path.join('./data', info.season, modelId)
      fs.ensureDirSync(csvTargetDir)

      // Copy csv
      fs.copySync(csvFile, path.join(csvTargetDir, info.name))

      // Write metadata
      ensureMetadata(path.join(csvTargetDir, 'meta.yml'), flusightMetadata)
    })
})
