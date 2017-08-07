const yaml = require('js-yaml')
const fs = require('fs-extra')
const path = require('path')
const md5 = require('js-md5')

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

const readModelMetadata = (modelDir) => {
  // Read any file matching metadata* as yaml
  let metaFile = fs.readdirSync(modelDir).filter(subItem => subItem.startsWith('metadata'))[0]
  return yaml.safeLoad(fs.readFileSync(path.join(modelDir, metaFile), 'utf8'))
}

const parseMetadata = (rootMetadata) => {
  // Return a flusight compatible metadata object
  return {
    name: rootMetadata.team_name,
    description: rootMetadata.methods,
    url: '#'
  }
}

const ensureMetadata = (filePath, data) => {
  if (!fs.existsSync(filePath)) {
    fs.writeFileSync(filePath, yaml.safeDump(data))
  }
}

const getModelIdentifier = (rootMetadata) => {
  // return rootMetadata.team_name.split(' ').map(name => name[0]).join('')
  return md5(rootMetadata.methods)
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
  let flusightMetadata = parseMetadata(rootMetadata)
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
