/**
 * Download and save historical data
 */

const fct = require('flusight-csv-tools')
const fs = require('fs-extra')

const OUTPUT_FILE = './scripts/assets/history.json'

// Get the ending year of the current season.
// Example: for season 2019/2020, the ending year is 2020
// Note: if the current month is July or later, it's considered the current season, otherwise it's the previous season.
var today = new Date()
var currentYear = today.getFullYear()
var currentMonth = today.getMonth()
var pad = currentMonth < 6 ? 0 : 1
var numberOfSeasonsSince2003 = currentYear - 2003 + pad

// Download history for seasons 2003 to the season before this current season
let seasonIds = [...Array(numberOfSeasonsSince2003).keys()].map(i => 2003 + i)

console.log(` Downloading historical data for the following seasons\n${seasonIds.join(', ')}`)

/**
 * Convert data returned from fct to the structure used by flusight
 * TODO Make the fct structure standard
 */
function parseHistoryData (seasonData) {
  let output = {}
  fct.meta.regionIds.forEach(rid => {
    output[rid] = seasonIds.map((sid, idx) => {
      return {
        season: `${sid}-${sid + 1}`,
        data: seasonData[idx][rid].map(({
          epiweek,
          wili
        }) => {
          return {
            week: epiweek,
            data: wili
          }
        })
      }
    })
  })
  return output
}

fct.truth.getSeasonsData(seasonIds).then(d => {
  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(parseHistoryData(d)))
  console.log(` Output written at ${OUTPUT_FILE}`)
}).catch(e => {
  console.log(e)
  process.exit(1)
})
