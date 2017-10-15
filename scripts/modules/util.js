/**
 * Some utilities
 */

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

module.exports.isSubset = isSubset
module.exports.unique = unique
