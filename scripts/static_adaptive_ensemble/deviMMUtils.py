#mcandrew

import numpy as np

def computeE(pis):
    from scipy.special import digamma
    #pis+=np.finfo(np.float64).eps
    sumPi = sum(pis)
    return np.array([digamma(pi) - digamma(sumPi) for pi in pis]).reshape(-1,1)

def C(alphas):
    from scipy.special import gammaln
    return gammaln(alphas.sum()) - gammaln(alphas).sum()

def computeELBO(dataLogScores
                ,alphas
                ,priorPis
                ,qZ
):
    from numpy import log
    nObs,numModels = dataLogScores.shape

    eps_alphas = alphas + np.finfo(np.float64).eps

    eps_qZ =qZ + np.finfo(np.float64).eps
    eps_qZ/=eps_qZ.sum(1).reshape(-1,1)
    
    ePis = computeE(eps_alphas)

    a = sum(sum(dataLogScores*eps_qZ))
    b = sum(sum(eps_qZ*ePis.T))
    c = ePis.T.dot(priorPis-1) + C(priorPis)

    e = sum(sum(eps_qZ*log(eps_qZ)))
    f = ePis.T.dot(eps_alphas-1) + C(eps_alphas)

    return float(a+b-f+c-e)

if __name__ == "__main__":
    pass
