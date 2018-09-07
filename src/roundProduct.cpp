#include "RcppArmadillo.h"

// [[Rcpp::depends(RcppArmadillo)]]

using namespace Rcpp;

//' @export
// [[Rcpp::export]]
Rcpp::NumericMatrix roundProduct(arma::cube X, arma::vec beta) {

  int N = X.n_rows;
  arma::mat M = arma::zeros<arma::mat>(N,N);

  for (int k = 0; k < beta.size(); k++) {
    M += X.slice(k) * beta[k];
  }

  return Rcpp::wrap(M);
}

// Rcpp::NumericMatrix roundProduct_old(arma::cube X, arma::vec beta) {
//
//   int N = X.n_rows;
//   arma::mat M(N,N);
//
//   for(int i=0; i<N; i++) {
//       for (int j=0; j<N; j++) {
//         arma::vec param = X.tube(i,j);
//         M(i,j) = as_scalar(beta.t()*param);
//       }
//   }
//   return Rcpp::wrap(M);
// }
