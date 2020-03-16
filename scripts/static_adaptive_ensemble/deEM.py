#mcandrew

from deEMUtils import *

def em(dataLogScores
       ,pis = []
       ,maxIters = 10**4
       ,relDiffThreshold = 10**-2):

    """
    dataLogScores    = a matrix containing model logScores across columns per dataPoint (row)
    maxIters         = maximum number of iterations for the EM algorithm
    relDiffThreshold = If the relative difference in logLikelihood falls below this value,stop
    """
    import numpy as np

    nObs,numModels = dataLogScores.shape
    dataProbs = np.exp(dataLogScores)#.reshape(nObs,numModels)
    if len(pis)==0:
        pis = np.array([1./numModels for i in range(numModels)]) #init even model weights     
        
    pis = pis.reshape(-1,1)
    ite,rDif = 0,1.
    logLiks  = [computeLL(dataProbs,pis)]
    while (ite < maxIters and rDif > relDiffThreshold):
        ite+=1

        # E step: update all probabilites
        Z = dataProbs * pis.T
        sumRows = Z.sum(axis=1).reshape(-1,1)
        Z       = Z/sumRows

        # M step: update all pis
        pis = Z.mean(axis=0).reshape(-1,1)

        logLiks.append(computeLL(dataProbs,pis))
        rDif = abs(logLiks[-1]/logLiks[-2] - 1.)
    return pis,Z,logLiks

if __name__ == "__main__":
    pass
 
