#mcandrew

import numpy as np
from deEMUtils import *
from deEM import *
from deviMMUtils import *

def deviMM(dataLogScores
           ,priorPis = []
           ,maxIters = 10**4
           ,relDiffThreshold = 10**-2):

    dataProbs = np.exp(dataLogScores)

    nObs,numComponentModels = dataProbs.shape
    pis,Z,LLs  = em(dataLogScores = dataLogScores
                    ,pis           = np.array([1./numComponentModels]*numComponentModels)
                    ,maxIters = 1*10**3
                    ,relDiffThreshold = -1
    )
    pis+=np.finfo(np.float32).eps
    pis/=sum(pis)
    priorPis = priorPis.reshape(-1,1)

    alphas = nObs*pis
    ELBOs = [computeELBO( dataLogScores, alphas, priorPis, Z+np.finfo(np.float32).eps)]
    for _ in range(maxIters):
        #update Z
        qZ = np.exp(dataLogScores + computeE(alphas).T)
        qZ = qZ/qZ.sum(1).reshape(-1,1)

        # update pi
        alphas = qZ.sum(0).reshape(-1,1) + priorPis

        ELBOs.append(computeELBO(dataLogScores, alphas, priorPis,qZ))
        if 1 - ELBOs[-1]/ELBOs[-2] < relDiffThreshold:
            break
    return alphas, ELBOs

if __name__ == "__main__":
    pass
