/**
 * Some utilities
 */

const fs = require('fs')
const yaml = require('js-yaml')

/**
 * Check if a is subset of b
 */
const isSubset = (a, b) => {
  if (a.length <= b.length) {
    for(let i = 0; i < a.length; i++) {
      if (b.indexOf(a[i]) === -1) {
        return false
      }
    }
    return true
  } else {
    return false
  }
}

/**
 * Return unique of array
 */
const unique = a => {
  return a.reduce(function (acc, it) {
    if (acc.indexOf(it) === -1) {
      acc.push(it)
    }
    return acc
  }, [])
}

const writeLines = (lines, fileName) => {
  fs.writeFile(fileName, lines.join('\n'), err => {
    if (err) { throw err }
    console.log(` > ${fileName} written`)
  })
}

const readYamlFile = fileName => {
  return yaml.safeLoad(fs.readFileSync(fileName, 'utf8'))
}

module.exports.isSubset = isSubset
module.exports.unique = unique
module.exports.writeLines = writeLines
module.exports.readYamlFile = readYamlFile
