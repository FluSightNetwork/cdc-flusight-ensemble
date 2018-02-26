#!/usr/bin/env node

// this script was used to create truth-with-lags.csv
// Needs flusight-csv-tools installed
// npm i flusight-csv-tools (in current dir)
// npm i -g flusight-csv-tools (for global installation)

const fct = require('flusight-csv-tools')
const fs = require('fs')

let stream = fs.createWriteStream('truth-with-lags.csv', { flags: 'a' })
stream.write(`epiweek,region,first-observed-wili,final-observed-wili\n`)

// A season 20xx-20yy is represented using just the first year 20xx
let seasons = [2010, 2011, 2012, 2013, 2014, 2015, 2016]
for (let season of seasons) {
  fct.truth.getSeasonData(season, 0).then(firstData => {
    // firstData is lag 0 data
    fct.truth.getSeasonData(season).then(latestData => {
      // without passing lag, most recent data is returned
      for (let region in firstData) {
        for (let fItem of firstData[region]) {
          let lItem = latestData[region].find(({ epiweek }) => epiweek == fItem.epiweek)
          if (lItem) {
            stream.write(`${fItem.epiweek},${region},${fItem.wili},${lItem.wili}\n`)
          } else {
            console.log(`For ${region} and ${fItem.epiweek}, lag 0 data is present but latest lag is not`)
          }
        }
      }
    })
  })
}
