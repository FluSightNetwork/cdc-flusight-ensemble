const yaml = require('js-yaml')
const fs = require('fs-extra')
const path = require('path')
const rimraf = require('rimraf')

const getModelDirs = (rootPath) => {
  return fs.readdirSync(rootPath)
    .filter(item => fs.lstatSync(path.join(rootPath, item)).isDirectory())
    .filter(item => {
      // Check if the directory has a metadata* type file
      let subItems = fs.readdirSync(path.join(rootPath, item)).filter(subItem => subItem.startsWith('metadata'))
      return subItems.length > 0
    })
    .filter(item => item !== 'templates')
}

const getModelMetaFile = (modelDir) => {
  return fs.readdirSync(modelDir).filter(subItem => subItem.startsWith('metadata'))[0]
}

const readModelMetadata = (modelDir) => {
  // Read any file matching metadata* as yaml
  let metaFile = getModelMetaFile(modelDir)
  return yaml.safeLoad(fs.readFileSync(path.join(modelDir, metaFile), 'utf8'))
}

const parseMetadata = (rootMetadata, modelDir) => {
  // Return a flusight compatible metadata object
  let desc = rootMetadata.methods
  let descMaxLen = 150
  if (desc.length > descMaxLen) {
    desc = desc.slice(0, descMaxLen) + '...'
  }
  let metaFile = getModelMetaFile(modelDir)
  let repoUrl = 'https://github.com/FluSightNetwork/cdc-flusight-ensemble'
  let metaPath = repoUrl + '/blob/master/' + path.join(path.basename(modelDir), metaFile)
  return {
    name: rootMetadata.team_name,
    description: desc,
    url: metaPath
  }
}

const ensureMetadata = (filePath, data) => {
  if (!fs.existsSync(filePath)) {
    fs.writeFileSync(filePath, yaml.safeDump(data))
  }
}

const getModelIdentifier = (modelDirName) => {
  let modelIdMap = {
    'ReichLab_sarima_seasonal_difference_FALSE': 'ReichLab-SARIMA1',
    'ReichLab_sarima_seasonal_difference_TRUE': 'ReichLab-SARIMA2'
  }
  if (modelDirName in modelIdMap) {
    return modelIdMap[modelDirName]
  } else {
    return modelDirName
  }
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
let rootDir = '../'
let modelDirs = getModelDirs(rootDir)

modelDirs.forEach(md => {
  // Read metadata and parse to usable form
  let rootMetadata = readModelMetadata(path.join(rootDir, md))
  let flusightMetadata = parseMetadata(rootMetadata, path.join(rootDir, md))
  let modelId = getModelIdentifier(md)

  getCSVs(path.join(rootDir, md)).forEach(csvFile => {
    let info = parseCSVInfo(path.basename(csvFile))

    // CSV target path
    let csvTargetDir = path.join('./data', info.season, modelId)
    fs.ensureDirSync(csvTargetDir)

    // Copy csv
    fs.copySync(path.join(rootDir, md, csvFile), path.join(csvTargetDir, info.name))

    // Write metadata
    ensureMetadata(path.join(csvTargetDir, 'meta.yml'), flusightMetadata)
  })
})

// Remove future? data
rimraf.sync('./data/2017-2018')
