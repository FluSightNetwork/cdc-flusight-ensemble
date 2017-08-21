const yaml = require('js-yaml')
const fs = require('fs-extra')
const path = require('path')

const getModelDirs = (rootPath) => {
  return fs.readdirSync(rootPath)
    .filter(item => fs.lstatSync(path.join(rootPath, item)).isDirectory())
    .filter(item => {
      // Check if the directory has a metadata.txt
      return fs.existsSync(path.join(rootPath, item, 'metadata.txt'))
    })
    .filter(item => item !== 'templates')
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
  let metaPath = repoUrl + '/blob/master/' + path.join(path.basename(modelDir), 'metadata.txt')
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
let rootDir = '../'
let modelDirs = getModelDirs(rootDir)

modelDirs.forEach(md => {
  // Read metadata and parse to usable form
  let rootMetadata = readModelMetadata(path.join(rootDir, md))
  let flusightMetadata = parseMetadata(rootMetadata, path.join(rootDir, md))
  let modelId = getModelIdentifier(rootMetadata)

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
