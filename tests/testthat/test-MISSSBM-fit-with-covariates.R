context("test missSBM-fit with covariates")

library(aricode)
source("utils_test.R")

## ========================================================================
## A SBM model with covariates

set.seed(178303)
N <- 300
Q <- 3
alpha <- rep(1,Q)/Q                     # mixture parameter
pi <- diag(.45, Q, Q) + .05                 # connectivity matrix
gamma <- missSBM:::logit(pi)
directed <- FALSE

### Draw a SBM model (Bernoulli, undirected) with covariates
M <- 2
covarMatrix <- matrix(rnorm(N*M,mean = 0, sd = 1), N, M)
covarArray  <- missSBM:::getCovarArray(covarMatrix, missSBM:::l1_similarity)
covarParam  <- rnorm(M, -1, 1)


sbm <- missSBM::simulate(N, alpha, gamma, directed, covarMatrix, covarParam)

## control parameter for the VEM
control <- list(threshold = 1e-4, maxIter = 100, fixPointIter = 3, trace = TRUE)

## Consistency
tol_truth <- 1e-2
tol_ARI   <- .9

test_that("missSBM with covariates and dyad sampling works", {

  ## sampled the network
  sampledNet <- missSBM::sample(sbm$adjMatrix, "dyad", covarParam, covarMatrix = covarMatrix)

  ## Perform inference
  missSBM <- missSBM:::missingSBM_fit$new(sampledNet, Q, "dyad", covarMatrix = covarMatrix, covarArray = covarArray, clusterInit = "spectral")
  out <- missSBM$doVEM(control)

  ## Sanity check
  expect_is(missSBM, "missingSBM_fit")
  expect_is(missSBM$fittedSBM, "SBM_fit_covariates")
  expect_is(missSBM$fittedSampling, "dyadSampling_fit_covariates")
  expect_is(missSBM$sampledNetwork, "sampledNetwork")
  expect_equal(out, missSBM$monitoring)

  ## Optimization success
  expect_gte(diff(range(out$objective, na.rm = TRUE)), 0)

  ## SBM: parameters estimation
  expect_lt(error(missSBM$fittedSBM$mixtureParam, sbm$mixtureParam, sort = TRUE), tol_truth)

  expect_lt(error(logistic(missSBM$fittedSBM$connectParam), pi), tol_truth)

  ## sampling design: parameters estimation
  expect_lt(error(missSBM$fittedSBM$covarParam, sbm$covarParam), tol_truth)

  ## clustering
  expect_gt(aricode::ARI(missSBM$fittedSBM$memberships, sbm$memberships), tol_ARI)

})

test_that("miss SBM with covariates and node sampling works", {

  ## sampled the network
  sampledNet <- missSBM::sample(sbm$adjMatrix, "node", covarParam, covarMatrix = covarMatrix)

  ## Perform inference
  missSBM <- missSBM:::missingSBM_fit$new(sampledNet, Q, "node", covarMatrix = covarMatrix, covarArray = covarArray)
  out <- missSBM$doVEM(control)

  ## Sanity check
  expect_is(missSBM, "missingSBM_fit")
  expect_is(missSBM$fittedSBM, "SBM_fit_covariates")
  expect_is(missSBM$fittedSampling, "nodeSampling_fit_covariates")
  expect_is(missSBM$sampledNetwork, "sampledNetwork")

  ## Optimization success
  expect_gte(diff(range(out$objective, na.rm = TRUE)), 0)

  ## SBM: parameters estimation
  expect_lt(error(missSBM$fittedSBM$mixtureParam, sbm$mixtureParam, sort = TRUE), tol_truth)

  expect_lt(error(logistic(missSBM$fittedSBM$connectParam), pi), tol_truth)

  ## sampling design: parameters estimation
  expect_lt(error(missSBM$fittedSampling$parameters, sbm$covarParam), tol_truth*10)

  ## clustering
  expect_gt(aricode::ARI(missSBM$fittedSBM$memberships, sbm$memberships), tol_ARI)

})