/**
 * Module for handling `yarn run parse`
 * Generate following data files in ./src/assets/data/
 * - history.json :: historical data for regions
 * - metadata.json :: metadata for regions with season prediction availability
 * - season-*.json :: file with main season data
 * - scores-*.json :: file with model scores
 * - distributions/season-*-*.json :: file with distribution data
 */

const utils = require('./utils')
const fs = require('fs-extra')
const fct = require('flusight-csv-tools')
const { exec } = require('child-process-promise')

// Setup variables
const DATA_DIR = './data' // Place with the CSVs
const HISTORY_IN_FILE = './scripts/assets/history.json'
const HISTORY_OUT_FILE = './src/assets/data/history.json'
const METADATA_OUT_FILE = './src/assets/data/metadata.json'
const SEASONS = utils.getSubDirectories(DATA_DIR)

console.log(' Generating data files for flusight')
console.log(' ----------------------------------\n')

/**
 * Write history.json
 */
async function writeHistory () {
  if (!(await fs.exists(HISTORY_IN_FILE))) {
    console.log(' ✕ History file not found. Downloading...')
    await exec('node scripts/get-history.js')
  }
  await fs.copy(HISTORY_IN_FILE, HISTORY_OUT_FILE)
  console.log(' ✓ Wrote history.json\n')
}

/**
 * Write metadata.json
 */
async function writeMetaData () {
  let regionData = fct.meta.regionIds.map(regionId => {
    return {
      id: regionId,
      subId: fct.meta.regionFullName[regionId],
      states: fct.meta.regionStates[regionId]
    }
  })

  await fs.writeFile(METADATA_OUT_FILE, JSON.stringify({
    regionData,
    seasonIds: SEASONS, // NOTE: These seasonIds are full xxxx-yyyy type ids
    updateTime: (new Date()).toUTCString()
  }))
  console.log(' ✓ Wrote metadata.json\n')
}

/**
 * Run node subprocesses to parse seasons
 */
async function parseSeasons (seasons) {
  if (seasons.length === 0) {
    console.log('\n ✓ All done')
  } else {
    console.log(`   Running parse-season for ${seasons[0]}`)
    await exec(`node scripts/parse-season.js ${seasons[0]}`)
    await parseSeasons(seasons.slice(1))
  }
}

writeHistory()
  .then(() => writeMetaData())
  .then(() => parseSeasons(SEASONS))
  .catch(e => {
    console.log(e)
    process.exit(1)
  })
