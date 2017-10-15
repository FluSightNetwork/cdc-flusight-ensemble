/**
 * Script for generating model-id to directory name mappings
 */

const models = require('./modules/models')
const path = require('path')
const fs = require('fs')

const modelParents = [
  'component-models',
  'cv-ensemble-models',
  'real-time-ensemble-models'
]

const getModelIdPair = modelDir => {
  return [models.getModelId(modelDir), path.basename(modelDir)]
}

const writeModelIdPairs = (pairs, filename) => {
  let header = 'model-id,model-dir'
  let content = [header, ...(pairs.map(pair => pair.join(',')))].join('\n')
  fs.writeFile(filename, content, err => {
    if (err) { throw err }
  })
}

modelParents.forEach(parentDir => {
  let rootPath = './model-forecasts'
  let modelDirs = models.getModelDirs(rootPath, [parentDir])
  let pairs = modelDirs.map(getModelIdPair)
  let outputFile = path.join(rootPath, parentDir, 'model-id-map.csv')
  writeModelIdPairs(pairs, outputFile)
})
