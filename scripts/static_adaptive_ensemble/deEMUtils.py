#mcandrew

import numpy as np

def computeLL(dataProbs,pis):
    return np.sum(np.log(dataProbs.dot(pis)))

def randomWeights(N):
    weights = np.random.random(N)
    return weights/sum(weights)

if __name__ == "__main__":
    pass
