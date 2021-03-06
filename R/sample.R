#' Sampling of network data
#'
#' This function samples observations in an adjacency matrix according to a given sampling design.
#' The final results is an adjacency matrix with the dimension as the input, yet with additional NAs.
#'
#' @param adjacencyMatrix The N x N adjacency matrix of the network to sample. If \code{adjacencyMatrix} is symmetric,
#' we assume an undirected network with no loop; otherwise the network is assumed directed.
#' @param sampling The sampling design used to sample the adjacency matrix, see details
#' @param parameters The sampling parameters adapted to each sampling
#' @param clusters An optional clustering membership vector of the nodes, only necessary for block samplings
#' @param covariates A list with M entries (the M covariates). If the covariates are node-centred, each entry of \code{covariates}
#' must be a size-N vector;  if the covariates are dyad-centred, each entry of \code{covariates} must be N x N matrix.
#' @param similarity An optional function to compute similarities between node covariates. Default is \code{l1_similarity}, that is, -abs(x-y).
#' Only relevant when the covariates are node-centered (i.e. \code{covariates} is a list of size-N vectors).
#' @param intercept An optional intercept term to be added in case of the presence of covariates. Default is 0.
#'
#' @return an object with class \code{\link{sampledNetwork}} containing all the useful information about the sampling.
#' Can then feed the \code{\link{estimate}} function.
#' @seealso The class \code{\link{sampledNetwork}}
#'
#' @details The different sampling designs are split into two families in which we find dyad-centered and
#' node-centered samplings. See <doi:10.1080/01621459.2018.1562934> for complete description.
#' \itemize{
#' \item Missing at Random (MAR)
#'   \itemize{
#'     \item{"dyad": parameter = p \deqn{p = P(Dyad (i,j) is sampled)}}
#'     \item{"node": parameter = p and \deqn{p = P(Node i is sampled)}}
#'     \item{"covar-dyad": parameter = beta in R^M and \deqn{P(Dyad (i,j) is sampled) = logistic(parameter' covarArray (i,j, ))}}
#'     \item{"covar-node": parameter = nu in R^M and \deqn{P(Node i is sampled)  = logistic(parameter' covarMatrix (i,)}}
#'   }
#' \item Not Missing At Random (NMAR)
#'   \itemize{
#'     \item{"double-standard": parameter = (p0,p1) and \deqn{p0 = P(Dyad (i,j) is sampled | the dyad is equal to 0)=}, p1 = P(Dyad (i,j) is sampled | the dyad is equal to 1)}
#'     \item{"block-node": parameter = c(p(1),...,p(Q)) and \deqn{p(q) = P(Node i is sampled | node i is in cluster q)}}
#'     \item{"block-dyad": parameter = c(p(1,1),...,p(Q,Q)) and \deqn{p(q,l) = P(Edge (i,j) is sampled | node i is in cluster q and node j is in cluster l)}}
#'     \item{"degree": parameter = c(a,b) and \deqn{logit(a+b*Degree(i)) = P(Node i is sampled | Degree(i))}}
#'   }
#' }
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
#'
#' # some sampling design and their associated parameters
#' sampling_parameters <- list(
#'    "dyad" = .3,
#'    "node" = .3,
#'    "double-standard" = c(0.4, 0.8),
#'    "block-node" = c(.3, .8, .5),
#'    "block-dyad" = pi,
#'    "degree" = c(.01, .01)
#'  )
#'
#' sampled_networks <- list()
#'
#' for (sampling in names(sampling_parameters)) {
#'   sampled_networks[[sampling]] <-
#'      missSBM::sample(
#'        adjacencyMatrix = sbm$adjacencyMatrix,
#'        sampling        = sampling,
#'        parameters      = sampling_parameters[[sampling]],
#'        cluster         = sbm$memberships
#'      )
#' }
#' \donttest{
#' ## SSOOOO long, but fancy
#' old_par <- par(mfrow = c(2,3))
#' for (sampling in names(sampling_parameters)) {
#'   plot(sampled_networks[[sampling]],
#'     clustering = sbm$memberships, main = paste(sampling, "sampling"))
#' }
#' par(old_par)
#' }
#' @export
sample <- function(adjacencyMatrix, sampling, parameters, clusters = NULL, covariates = NULL, similarity = l1_similarity, intercept = 0) {

  ## Sanity check
  stopifnot(sampling %in% available_samplings)

  ## general network parameters
  nNodes   <- ncol(adjacencyMatrix)
  directed <- !isSymmetric(adjacencyMatrix)

  ## Prepare the covariates
  covar <- format_covariates(covariates, similarity)
  if (!is.null(covar$Array)) stopifnot(sampling %in% available_samplings_covariates)

  ## instantiate the sampler
  mySampler <-
    switch(sampling,
      "dyad"       = simpleDyadSampler$new(
        parameters = parameters, nNodes = nNodes, directed = directed),
      "node"       = simpleNodeSampler$new(
        parameters = parameters, nNodes = nNodes, directed = directed),
      "covar-dyad" = simpleDyadSampler$new(
        parameters = parameters, nNodes = nNodes, directed = directed, covarArray  = covar$Array, intercept = intercept),
      "covar-node" = simpleNodeSampler$new(
        parameters = parameters, nNodes = nNodes, directed = directed, covarMatrix = covar$Matrix, intercept = intercept),
      "double-standard" = doubleStandardSampler$new(
        parameters = parameters, adjMatrix = adjacencyMatrix, directed = directed),
      "block-dyad" = blockDyadSampler$new(
        parameters = parameters, nNodes = nNodes, directed = directed, clusters = clusters),
      "block-node" = blockNodeSampler$new(
        parameters = parameters, nNodes = nNodes, directed = directed, clusters = clusters),
      "degree"     = degreeSampler$new(
        parameters = parameters, degrees = rowSums(adjacencyMatrix), directed = directed)
  )

  ## draw a sampling matrix R
  mySampler$rSamplingMatrix()

  ## turn this matrix to a sampled Network object
  adjacencyMatrix[mySampler$samplingMatrix == 0] <- NA
  sampledNet <- sampledNetwork$new(adjacencyMatrix, covar$Matrix, covar$Array)
  sampledNet
}
