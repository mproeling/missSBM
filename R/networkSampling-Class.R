#' definition of R6 Class 'networkSampling'
#'
#' this virtual class is the mother of all subtypes of networkSampling (either sampler or fit)
#'
#' @include utils.R
#'
#' @import R6
#' @export
networkSampling <-
R6Class(classname = "networkSampling",
  ## fields
  private = list(
    name  = NULL, # type of sampling
    psi   = NULL  # vector of missing parameters
  ),
  public = list(
    ## methods
    initialize = function(type = NA) {
      stopifnot(type %in% available_samplings)
      private$name <- type
    }
  ),
  active = list(
    type = function(value) {private$name},
    parameters = function(value) {private$psi},
    ## degree of freedom are just the size of the vector of missing parameters
    df = function(value) {length(private$psi)}
  )
)