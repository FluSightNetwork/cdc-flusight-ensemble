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

  it('Team-model abbreviations should be unique', function (done) {
    let abbreviations = metadataFiles.map(function (metaFile) {
      let meta = yaml.safeLoad(fs.readFileSync(metaFile, 'utf8'))
      return meta.team_name + '-' + meta.model_abbr
    })

    // Count number of times the names are present
    let counts = abbreviations.reduce(function (acc, y) {
      if (acc[y]) {
        acc[y] += 1
      } else {
        acc[y] = 1
      }
      return acc
    }, {})

    for (let name in counts) {
      if (counts[name] > 1) {
        done(new Error(`Non unique model abbreviation found for ${name}`))
      }
    }
  })
})
