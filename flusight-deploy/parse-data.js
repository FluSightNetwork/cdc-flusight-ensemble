const yaml = require('js-yaml')
const fs = require('fs-extra')
const path = require('path')


/**
 * Return model directories
 */
const getModelDirs = rootDir => {
  // NOTE: We only consider these two directories for visualizations
  return ['component-models', 'real-time-ensemble-models'].reduce(function (acc, subDir) {
    return acc.concat(fs.readdirSync(path.join(rootDir, subDir)).map(function (it) { return path.join(rootDir, subDir, it) } ))
  }, [])
    .filter(function (it) { return fs.statSync(it).isDirectory() })
}

const readModelMetadata = (modelDir) => {
  return yaml.safeLoad(fs.readFileSync(path.join(modelDir, 'metadata.txt'), 'utf8'))
}

const parseMetadata = (rootMetadata, modelDir) => {
  // Return a flusight compatible metadata object
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

const getModelIdentifier = (rootMetadata) => {
  return rootMetadata.team_name + '-' + rootMetadata.model_abbr
}

const getCSVs = (modelDir) => {
  return fs.readdirSync(modelDir).filter(file => file.endsWith('.csv'))
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
let modelDirs = getModelDirs('../model-forecasts')

modelDirs.forEach(modelDir => {
  // Read metadata and parse to usable form
  let rootMetadata = readModelMetadata(modelDir)
  let flusightMetadata = parseMetadata(rootMetadata, modelDir)
  let modelId = getModelIdentifier(rootMetadata)

  getCSVs(modelDir).forEach(csvFile => {
    let info = parseCSVInfo(path.basename(csvFile))

    // CSV target path
    let csvTargetDir = path.join('./data', info.season, modelId)
    fs.ensureDirSync(csvTargetDir)

    // Copy csv
    fs.copySync(path.join(modelDir, csvFile), path.join(csvTargetDir, info.name))

    // Write metadata
    ensureMetadata(path.join(csvTargetDir, 'meta.yml'), flusightMetadata)
  })
})
