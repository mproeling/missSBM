context("test-test-top-level-function-misssbm")

library(aricode)

set.seed(1890718)
### A SBM model : ###
N <- 300
Q <- 3
alpha <- rep(1, Q)/Q       # mixture parameter
pi <- diag(.45, Q, Q) + .05   # connectivity matrix
directed <- FALSE         # if the network is directed or not

### Draw a SBM model
mySBM <- missSBM::simulate(N, alpha, pi, directed) # simulation of ad Bernoulli non-directed SBM
A <- mySBM$adjMatrix # the adjacency matrix

test_that("missSBM and class missSBM-fit are coherent", {

  l_psi <- list(
    "dyad" = c(.3),
    "node" = c(.3),
    "double-standard" = c(0.4, 0.8),
    "block-node" = c(.3, .8, .5),
    "block-dyad" = mySBM$connectParam,
    "degree" = c(.01, .01)
  )

  for (k in seq_along(l_psi)) {

    sampling <- names(l_psi)[k]

    sampledNet <- missSBM::sample(A, sampling, l_psi[[k]], clusters = mySBM$memberships)

    ## control parameter for the VEM
    control <- list(threshold = 1e-4, maxIter = 200, fixPointIter = 5, trace = FALSE)

    ## Perform inference with internal classes
    missSBM <- missSBM:::missingSBM_fit$new(sampledNet, Q, sampling)
    out_missSBM <- missSBM$doVEM(control)

    ## Perform inference with the top level function
    collection <- missSBM::estimate(
      adjacencyMatrix = sampledNet$adjMatrix,
      vBlocks         = Q,
      sampling        = sampling,
      control_VEM     = control,
      trace           = FALSE
    )

    expect_is(collection, "missSBM_collection")
    expect_equivalent(collection$models[[1]], missSBM)

  }

})

test_that("missSBM with a collection of models", {

  l_psi <- list(
    "dyad" = c(.75),
    "node" = c(.75),
    "double-standard" = c(0.4, 0.8),
    "block-node" = c(.3, .8, .5),
    "block-dyad" = mySBM$connectParam#,
#    "degree" = c(.01, .01)
  )

  for (k in seq_along(l_psi)) {

    sampling <- names(l_psi)[k]
    sampledNet <- missSBM::sample(A, sampling, l_psi[[k]], clusters = mySBM$memberships)
    control <- list(threshold = 1e-4, maxIter = 200, fixPointIter = 5, trace = FALSE)

    ## Perform inference with the top level function
    collection <- missSBM::estimate(
      adjacencyMatrix = sampledNet$adjMatrix,
      vBlocks         = 1:5,
      sampling        = "dyad",
      control_VEM     = control,
      trace           = FALSE
    )

    expect_is(collection, "missSBM_collection")
    expect_equal(collection$bestModel$fittedSBM$nBlocks, Q)
    expect_true(which.min(collection$ICL) == Q)
    expect_true(is.data.frame(collection$optimizationStatus))
  }
})