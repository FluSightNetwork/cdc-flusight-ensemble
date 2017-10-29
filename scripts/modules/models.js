/**
 * Module for model directory related functions
 */

const fs = require('fs')
const path = require('path')
const util = require('./util')

/**
 * Return model directories
 */
const getModelDirs = (rootDir, modelTypes) => {
  return modelTypes.reduce(function (acc, subDir) {
    return acc.concat(fs.readdirSync(path.join(rootDir, subDir)).map(function (it) { return path.join(rootDir, subDir, it) } ))
  }, [])
    .filter(function (it) { return fs.statSync(it).isDirectory() })
}

const getModelMetadata = modelDir => {
  return util.readYamlFile(path.join(modelDir, 'metadata.txt'))
}

const writeModelMetadata = (data, modelDir) => {
  util.writeYamlFile(data, path.join(modelDir, 'metadata.txt'))
}

/**
 * Return model id from modelDir
 */
const getModelId = modelDir => {
  let meta = getModelMetadata(modelDir)
  return `${meta.team_name}-${meta.model_abbr}`
}

/**
 * Return timing information about the csv
 */
const getCsvTime = csvFile => {
  let baseName = path.basename(csvFile)
  let [epiweek, year, ] = baseName.split('-')
  return {
    epiweek: parseInt(epiweek.slice(2)) + '',
    year: year
  }
}

const getModelCsvs = modelDir => {
  return fs.readdirSync(modelDir)
    .filter(item => item.endsWith('csv'))
    .map(fileName => path.join(modelDir, fileName))
}

module.exports.getModelDirs = getModelDirs
module.exports.getModelMetadata = getModelMetadata
module.exports.writeModelMetadata = writeModelMetadata
module.exports.getModelId = getModelId
module.exports.getCsvTime = getCsvTime
module.exports.getModelCsvs = getModelCsvs
