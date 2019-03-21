#' Inference of an SBM with missing data
#'
#' Perform variational inference of a Stochastic Block Model from a sampled adjacency matrix
#'
#' @param adjacencyMatrix The adjacency matrix of the network
#' @param vBlocks The vector of number of blocks considered in the collection
#' @param sampling The sampling design for missing data modeling : "dyad", "double_standard", "node", "snowball", "degree", "block" by default "undirected" is choosen
#' @param covarMatrix An optional matrix of covariates with dimension N x M (M covariates per node).
#' @param covarSimilarity An optional R x R -> R function  to compute similarity between node covariates. Default is #'
#' @param clusterInit Initial method for clustering: either a character in "hierarchical", "spectral" or "kmeans", or a list with \code{length(vBlocks)} vectors, each with size \code{ncol(adjacencyMatrix)} providing a user-defined clustering
#' @param trace logical, control the verbosity. Default to \code{TRUE}.
#' @param mc.cores integer, the number of cores to use when multiply model are fitted
#' @param smoothing character indicating what kind of ICL smoothing should be use among "none", "forward", "backward" or "both"
#' @param iter_both integer for the number of iteration in case of foward-backward (aka both) smoothing
#' @param control_VEM a list controlling the variational EM algorithm. See details.
#' @param Robject an object with class \code{missSBMcollection}
#' @return Returns an S3 object with class \code{missSBMcollection}, which is a list with all models estimated for all Q in vBlocks. \code{missSBMcollection} owns a couple of S3 methods: \code{is.missSBMcollection} to test the class of the object, a method \code{ICL} to extract the values of the Integrated Classification Criteria for each model, a method \code{getBestModel} which extract from the list the best model (and object of class \code{missSBM-fit}) according to the ICL, and a method \code{optimizationStatus} to monitor the objective function a convergence of the VEM algorithm.
#' @seealso \code{\link{sample}}, \code{\link{simulate}} and \code{\link{missingSBM_fit}}.
#' @examples
#' ## SBM parameters
#' directed <- FALSE
#' N <- 300 # number of nodes
#' Q <- 3   # number of clusters
#' alpha <- rep(1,Q)/Q     # mixture parameter
#' pi <- diag(.45,Q) + .05 # connectivity matrix
#'
#' ## simulate a SBM without covariates
#' sbm <- missSBM::simulate(N, alpha, pi, directed)
#'
#' ## Sample network data
#' samplingParameters <- .5 # the sampling rate
#' sampling <- "dyad"       # the sampling design
#' sampledNet <- missSBM::sample(sbm$adjMatrix, sampling, samplingParameters)
#'
#' ## Inference :
#' vBlocks <- 1:5 # number of classes
#' sbm <- missSBM::estimate(sampledNet$adjMatrix, vBlocks, sampling)
#' @import R6 parallel
#' @include utils_smoothing.R
#' @export
estimate <- function(
  adjacencyMatrix,
  vBlocks,
  sampling,
  clusterInit = ifelse(is.null(covarMatrix), "hierarchical", "spectral"),
  covarMatrix = NULL,
  covarSimilarity = l1_similarity,
  trace     = TRUE,
  smoothing = c("none", "forward", "backward", "both"),
  mc.cores = 1,
  iter_both = 1,
  control_VEM = list()) {

  ## some sanity checks
  try(
    !all.equal(unique(as.numeric(adjacencyMatrix[!is.na(adjacencyMatrix)])), c(0,1)),
    stop("Only binary graphs are supported.")
  )

  ## Create the sampledNetwork object
  sampledNet <- sampledNetwork$new(adjacencyMatrix)

  ## Compute the array of covariates, used in all SBM-related computations
  covarArray  <- getCovarArray(covarMatrix, covarSimilarity)

  if (!is.list(clusterInit)) clusterInit <- rep(list(clusterInit), length(vBlocks))

  if (trace) cat("\n")
  if (trace) cat("\n Adjusting Variational EM for Stochastic Block Model\n")
  if (trace) cat("\n\tImputation assumes a '", sampling,"' network-sampling process\n", sep = "")
  if (trace) cat("\n")
  models <- mcmapply(
    function(nBlock, clInit) {
      if (trace) cat(" Initialization of model with", nBlock,"blocks.", "\r")
      missingSBM_fit$new(sampledNet, nBlock, sampling, clInit, covarMatrix, covarArray)
    }, nBlock = vBlocks, clInit = clusterInit, mc.cores = mc.cores
  )

  ## defaut control parameter for VEM, overwritten by user specification
  control <- list(threshold = 1e-4, maxIter = 200, fixPointIter = 5, trace = FALSE)
  control[names(control_VEM)] <- control_VEM
  cat("\n")
  mclapply(models,
    function(model) {
      if (trace) cat(" Performing VEM inference for model with", model$fittedSBM$nBlocks,"blocks.\r")
      model$doVEM(control)
    }, mc.cores = mc.cores
  )

  smoothing <- match.arg(smoothing)
  if (smoothing != "none") {
    if (trace) cat("\n Smoothing ICL\n")
    smoothing_fn <- switch(smoothing,
                           "forward"  = smoothingForward ,
                           "backward" = smoothingBackward,
                           "both"     = smoothingForBackWard
    )
    if (!is.character(clusterInit)) {
      split_fn <- init_hierarchical
    } else {
      split_fn <- switch(clusterInit,
                         "spectral" = init_spectral,
                         "hierarchical" = init_hierarchical,
                         init_hierarchical)
    }
    control$trace <- FALSE # forcing no trace while smoothing
    models <- smoothing_fn(models, vBlocks, sampledNet, sampling, covarMatrix, covarSimilarity, split_fn, mc.cores, iter_both, control)

  }

  structure(setNames(models, vBlocks), class = "missSBMcollection")
}
