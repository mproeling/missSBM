context("test network sampling fit (Class networkSampling_fit and chidren)")

set.seed(178303)
### A SBM model : ###
N <- 400
Q <- 5
alpha <- rep(1, Q)/Q                       # mixture parameter
pi <- diag(.45, Q, Q) + .05                   # connectivity matrix
directed <- FALSE                         # if the network is directed or not

### Draw a SBM undirected model
mySBM <- missSBM::simulate(N, alpha, pi, directed)
A <- mySBM$adjMatrix

### Draw a SBM model (Bernoulli, undirected) with covariates
M <- 10
covarMatrix <- matrix(rnorm(N*M,mean = 0, sd = 1), N, M)
covarParam  <- rnorm(M,0,1)
mySBM_cov <- missSBM::simulate(N, alpha, pi, directed, covarMatrix, covarParam)
A_cov <- mySBM$adjMatrix

test_that("Parameter estimation in dyad-centered sampling with covariates", {

  sampledNet <- missSBM::sample(A_cov, "dyad", covarParam, covarMatrix = covarMatrix)

  fittedSampling <- missSBM:::dyadSampling_fit_covariates$new(sampledNet, mySBM_cov$covarArray)
  expect_is(fittedSampling, "dyadSampling_fit_covariates")
  expect_true(all(fittedSampling$prob_obs > 0, fittedSampling$prob_obs < 1))

  tolerance <- 1e-2
  expect_lt(sum((fittedSampling$parameters - covarParam)^2), tolerance)
  expect_equal(fittedSampling$df, length(covarParam))
  expect_equal(fittedSampling$penalty, log(N * (N - 1)/2) * length(covarParam))
  expect_lt(fittedSampling$vExpec, 0)
})

test_that("Parameter estimation in node-centered sampling with covariates", {

  sampledNet <- missSBM::sample(A_cov, "node", covarParam, covarMatrix = covarMatrix)

  fittedSampling <- missSBM:::nodeSampling_fit_covariates$new(sampledNet, covarMatrix)
  expect_is(fittedSampling, "nodeSampling_fit_covariates")
  expect_true(all(fittedSampling$prob_obs > 0, fittedSampling$prob_obs < 1))

  tolerance <- .2
  expect_lt(sum((fittedSampling$parameters - covarParam)^2)/length(covarParam), tolerance)
  expect_equal(fittedSampling$df, length(covarParam))
  expect_equal(fittedSampling$penalty, log(N) * length(covarParam))
  expect_lt(fittedSampling$vExpec, 0)
})

test_that("Parameter estimation in degree sampling", {
  psi <- c(-.5,0.01)
  sampledNet <- missSBM::sample(A,"degree", psi)
  Z0 <- missSBM:::clustering_indicator(mySBM$memberships)
  fittedSampling <- missSBM:::degreeSampling_fit$new(sampledNet, Z0, mySBM$connectParam)

  # tolerance <- 1 ## not expected good after one iterate
  # expect_lt(sum((fittedSampling$parameters - psi)^2), tolerance)
  expect_equal(fittedSampling$df, length(psi))
  expect_equal(fittedSampling$penalty, log(N) * length(psi))
  expect_lt(fittedSampling$vExpec, 0)
})
