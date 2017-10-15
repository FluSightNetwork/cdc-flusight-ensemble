/**
 * Module for model directory related functions
 */

const fs = require('fs')
const path = require('path')
const yaml = require('js-yaml')

/**
 * Return model directories
 */
const getModelDirs = (rootDir, modelTypes) => {
  return modelTypes.reduce(function (acc, subDir) {
    return acc.concat(fs.readdirSync(path.join(rootDir, subDir)).map(function (it) { return path.join(rootDir, subDir, it) } ))
  }, [])
    .filter(function (it) { return fs.statSync(it).isDirectory() })
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
module.exports.getModelId = getModelId
module.exports.getCsvTime = getCsvTime
module.exports.getModelCsvs = getModelCsvs
