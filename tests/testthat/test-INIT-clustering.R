context("test clustering function used in initialization")

library(aricode)
### A SBM model used for all tests
set.seed(178303)
N <- 400
Q <- 5
alpha <- rep(1, Q)/Q       # mixture parameter
pi <- diag(.45, Q, Q) + .05   # connectivity matrix
directed <- FALSE         # if the network is directed or not

### Draw a SBM model
sbm <- missSBM::simulate(N, alpha, pi, directed) # simulation of a Bernoulli non-directed SBM

A_full <- sbm$adjMatrix             # the adjacency matrix

## Draw random missing entries: MAR case (dyads)
psi <- 0.3
sampledNet <- missSBM::sample(A_full, "dyad", psi)
A_dyad <- sampledNet$adjMatrix

psi <- 0.3
sampledNet <- missSBM::sample(A_full, "node", psi)
A_node <- sampledNet$adjMatrix

test_that("Spectral clustering is consistent", {

  for (A in list(A_full, A_dyad, A_node)) {

    ## internal function
    cl_spectral_internal <- missSBM:::init_spectral(A, Q)
    expect_is(cl_spectral_internal, "integer")
    expect_equal(length(cl_spectral_internal), N)

    ## top level function
    cl_spectral <-
      missSBM:::init_clustering(
        adjacencyMatrix = A,
        nBlocks = Q,
        clusterInit = "spectral"
      )
    expect_is(cl_spectral, "integer")
    expect_equal(length(cl_spectral), N)

    ## must be equivalent (up to label switching)
    expect_equal(ARI(cl_spectral, cl_spectral_internal), 1.0)
  }

})

test_that("Kmeans clustering is consistent", {

  for (A in list(A_full, A_dyad, A_node)) {

    ## internal function
    cl_kmeans_internal <- missSBM:::init_kmeans(A, Q)
    expect_is(cl_kmeans_internal, "integer")
    expect_equal(length(cl_kmeans_internal), N)

    ## top level function
    cl_kmeans <-
      missSBM:::init_clustering(
        adjacencyMatrix = A,
        nBlocks = Q,
        clusterInit = "kmeans"
      )
    expect_is(cl_kmeans, "integer")
    expect_equal(length(cl_kmeans), N)

    ## must be equivalent (up to label switching)
    expect_equal(ARI(cl_kmeans, cl_kmeans_internal), 1.0)

  }
})

test_that("Hierarchical clustering is consistent", {

  for (A in list(A_full, A_dyad, A_node)) {
    ## internal function
    cl_hierarchical_internal <- missSBM:::init_hierarchical(A, Q)
    expect_is(cl_hierarchical_internal, "integer")
    expect_equal(length(cl_hierarchical_internal), N)

    ## top level function
    cl_hierarchical <-
      missSBM:::init_clustering(
        adjacencyMatrix = A,
        nBlocks = Q,
        clusterInit = "hierarchical"
      )
    expect_is(cl_hierarchical, "integer")
    expect_equal(length(cl_hierarchical), N)

    ## must be equivalent (up to label switching)
    expect_equal(ARI(cl_hierarchical, cl_hierarchical_internal), 1.0)
  }
})


test_that("Clustering initializations are relevant", {

  for (A in list(A_full, A_dyad, A_node)) {

    for (method in c("spectral", "kmeans", "hierarchical")) {

      ## top level function
      cl <-
        missSBM:::init_clustering(
          adjacencyMatrix = A,
          nBlocks = Q,
          clusterInit = method
        )

      relevance <- .6
      expect_gt(ARI(cl, sbm$memberships), relevance)

    }
  }
})


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
covarParam  <- rnorm(M, -1, 1)

sbm <- missSBM::simulate(N, alpha, gamma, directed, covarMatrix, covarParam)

test_that("Init clustering with covariate is consistent", {

  A_full <- sbm$adjMatrix
  psi <- runif(M, -5, 5)
  A_dyad <- missSBM::sample(A_full, "dyad", psi, covarMatrix = covarMatrix)$adjMatrix
  A_node <- missSBM::sample(A_full, "node", psi, covarMatrix = covarMatrix)$adjMatrix

  for (A in list(A_full, A_dyad, A_node)) {
    for (method in c("hierarchical", "spectral", "kmeans")) {
    cl <-
      missSBM:::init_clustering(
        adjacencyMatrix = A,
        nBlocks = Q,
        covarArray = sbm$covarArray,
        clusterInit = method
      )
      relevance <- .4
      expect_is(cl, "integer")
      expect_equal(length(cl), N)
      expect_gt(ARI(cl, sbm$memberships), relevance)
    }
  }
})
