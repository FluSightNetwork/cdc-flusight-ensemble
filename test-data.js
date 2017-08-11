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
  let modelDirs = fs.readdirSync('./').filter(function (item) {
    return (fs.statSync(item).isDirectory() && whitelisted_directories.indexOf(item) === -1)
  })

  modelDirs.forEach(function (modelDir) {
    it('should be present for ' + modelDir, function () {
      fs.existsSync(path.join(modelDir, 'metadata.txt')).should.be.true
    })
  })

  let metadataFiles = fs.readdirSync('./').filter(function (item) {
    return (fs.statSync(item).isDirectory() && whitelisted_directories.indexOf(item) === -1)
  }).map(function (modelDir) {
    return path.join(modelDir, 'metadata.txt')
  })

  metadataFiles.forEach(function (metaFile) {
    it(metaFile + ' should be yaml readable', function (done) {
      try {
        yaml.safeLoad(fs.readFileSync(metaFile, 'utf8'))
        done()
      } catch (e) {
        done(e)
      }
    })
  })
})
