// Test data files for inconsistencies

const chai = require('chai')
const path = require('path')
const fs = require('fs')
const yaml = require('js-yaml')
const Papa = require('papaparse')
const mmwr = require('mmwr-week')
const moment = require('moment')
const d3 = require('d3')
const aequal = require('array-equal')
const models = require('./scripts/modules/models')
const meta = require('./scripts/modules/meta')
const util = require('./scripts/modules/util')

chai.should()

// Metadata tests
describe('metadata.txt', function () {
  let modelDirs = models.getModelDirs(
    './model-forecasts',
    ['component-models', 'cv-ensemble-models', 'real-time-ensemble-models']
  )

  describe('should be present', function () {
    modelDirs.forEach(function (modelDir) {
      it(modelDir, function () {
        fs.existsSync(path.join(modelDir, 'metadata.txt')).should.be.true
      })
    })
  })

  let metadataFiles = modelDirs.map(function (modelDir) {
    return path.join(modelDir, 'metadata.txt')
  })

  describe('should be yaml readable', function () {
    metadataFiles.forEach(function (metaFile) {
      it(metaFile, function (done) {
        try {
          yaml.safeLoad(fs.readFileSync(metaFile, 'utf8'))
          done()
        } catch (e) {
          done(e)
        }
      })
    })
  })

  it('team-model abbreviations should be unique', function (done) {
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
    done()
  })

  describe('should have team_name withing 10 chars', function () {
    metadataFiles.forEach(function (metaFile) {
      it(metaFile, function () {
        let meta = yaml.safeLoad(fs.readFileSync(metaFile, 'utf8'))
        meta.team_name.length.should.be.below(11)
      })
    })
  })

  describe('should have model_abbr within 15 chars', function () {
    metadataFiles.forEach(function (metaFile) {
      it(metaFile, function () {
        let meta = yaml.safeLoad(fs.readFileSync(metaFile, 'utf8'))
        meta.model_abbr.length.should.be.below(16)
      })
    })
  })
})

// CSV tests
describe('CSV', function () {
  let modelDirs = models.getModelDirs(
    './model-forecasts',
    ['component-models', 'cv-ensemble-models', 'real-time-ensemble-models']
  )

  let csvFiles = modelDirs.map(function (modelDir) {
    return fs.readdirSync(modelDir).filter(function (item) {
      return item.endsWith('csv')
    }).map(csv => path.join(modelDir, csv))
  }).reduce(function (acc, item) {
    return acc.concat(item)
  }, [])

  let currentMoment = moment()
  describe('should have valid week number', function () {
    csvFiles.forEach(function (csvFile) {
      it(csvFile, function () {
        let splits = path.basename(csvFile).split('-')
        let week = parseInt(splits[0].slice(2))
        let year = parseInt(splits[1])
        let mdate = new mmwr.MMWRDate(year, week)
        currentMoment.isAfter(mdate.toMomentDate()).should.be.true
      })
    })
  })
})

// Test for ground truth file
describe('Ground truth file', function () {
  let truthFile = './scores/target-multivals.csv'

  it(`${truthFile} should exist`, function () {
    fs.existsSync(truthFile).should.be.true
  })

  // Test things inside csv
  let trueData = Papa.parse(fs.readFileSync(truthFile, 'utf8')).data
      .slice(1)
      .filter(d => !(d.length === 1 && d[0] === ''))

  let entries = d3.nest()
      .key(d => d[0]) // year
      .key(d => d[1]) // epiweek
      .key(d => d[4]) // region
      .key(d => d[5]) // target
      .entries(trueData)

  // Get all the year, week pairs over models
  // For each one, see if the entries in trueData have
  // 1. All regions
  // 2. All targets (at least one value for each)

  let modelDirs = models.getModelDirs(
    './model-forecasts',
    ['component-models', 'cv-ensemble-models', 'real-time-ensemble-models']
  )

  let yearWeekPairs = modelDirs.map(function (modelDir) {
    return fs.readdirSync(modelDir).filter(function (item) {
      return item.endsWith('csv')
    }).map(csv => {
      let [week, year, ] = csv.split('-')
      return [year, parseInt(week.slice(2)) + '']
    })
  }).reduce(function (acc, pairs) {
    pairs.forEach(p => {
      if (acc[p[0]]) {
        if (acc[p[0]].indexOf(p[1]) === -1) {
          acc[p[0]].push(p[1])
        }
      } else {
        acc[p[0]] = [p[1]]
      }
    })
    return acc
  }, {})

  // Check for years
  it('All years should be present in truth file', function () {
    let fileYears = Object.entries(yearWeekPairs).map(e => e[0]).sort()
    let scoreYears = entries.map(e => e.key).sort()
    util.isSubset(fileYears, scoreYears).should.be.true
  })

  // Check for weeks in each year
  describe('Year-week pair', function () {
    // For each year
    let scoreYears = entries.map(e => e.key)
    scoreYears.forEach(y => {
      let fileWeeks = yearWeekPairs[y]
      let scoreWeeks = entries[scoreYears.indexOf(y)].values.map(d => d.key)
      it(`All weeks for year ${y} should be present in truth file`, function () {
        util.isSubset(fileWeeks, scoreWeeks).should.be.true
      })
    })
  })

  // Check for all regions and targets to be present
  describe('Regions and targets', function () {
    let scoreYears = entries.map(e => e.key)
    scoreYears.forEach(y => {
      let yearEntry = entries[scoreYears.indexOf(y)]
      let scoreWeeks = yearEntry.values.map(d => d.key)
      scoreWeeks.forEach(w => {
        let weekEntry = yearEntry.values[scoreWeeks.indexOf(w)]
        let scoreRegions = weekEntry.values.map(d => d.key)
        it(`All regions for year ${y} and week ${w} should be present`, function () {
          aequal(scoreRegions, meta.regions).should.be.true
        })
        scoreRegions.forEach(r => {
          let regionEntry = weekEntry.values[scoreRegions.indexOf(r)]
          let scoreTargets = regionEntry.values.map(d => d.key)
          it(`All targets for year ${y}, week ${w} and region ${r} should be present`, function () {
            aequal(util.unique(scoreTargets), meta.targets).should.be.true
          })
        })
      })
    })
  })
})
