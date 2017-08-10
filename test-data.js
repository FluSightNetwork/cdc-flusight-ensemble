// Test data files for inconsistencies

const chai = require('chai')
const path = require('path')
const fs = require('fs')
const yaml = require('js-yaml')

chai.should()

const whitelisted_directories = [
  '.git',
  'plots',
  'scripts',
  'templates',
  'flusight-deploy',
  'node_modules'
]

describe('metadata.txt', function () {
  it('should be present', function (done) {
    let modelDirs = fs.readdirSync('./').filter(function (item) {
      return (fs.statSync(item).isDirectory() && whitelisted_directories.indexOf(item) === -1)
    })

    modelDirs.forEach(modelDir => {
      try {
        fs.readFileSync(path.join(modelDir, 'metadata.txt'))
      } catch (e) {
        done(e)
      }
    })
  })

  it('should be yaml readable', function (done) {
    let metadataFiles = fs.readdirSync('./').filter(function (item) {
      return (fs.statSync(item).isDirectory() && whitelisted_directories.indexOf(item) === -1)
    }).map(function (modelDir) {
      return path.join(modelDir, 'metadata.txt')
    })

    metadataFiles.forEach(function (metaFile) {
      try {
        yaml.safeLoad(fs.readFileSync(metaFile, 'utf8'))
      } catch (e) {
        done(e)
      }
    })
  })
})
