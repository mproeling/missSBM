
# missSBM: Handling missing data in Stochastic Block Models

[![Travis build
status](https://travis-ci.org/jchiquet/missSBM.svg?branch=master)](https://travis-ci.org/jchiquet/missSBM)
[![AppVeyor build
status](https://ci.appveyor.com/api/projects/status/github/jchiquet/missSBM?branch=master&svg=true)](https://ci.appveyor.com/project/jchiquet/missSBM)
[![Coverage
status](https://codecov.io/gh/jchiquet/missSBM/branch/master/graph/badge.svg)](https://codecov.io/github/jchiquet/missSBM?branch=master)
[![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/missSBM)](https://cran.r-project.org/package=missSBM)

> When a network is partially observed (here, NAs in the adjacency
> matrix rather than 1 or 0 due to missing information between node
> pairs), it is possible to account for the underlying process that
> generates those NAs. ‘missSBM’ adjusts the popular stochastic block
> model from network data sampled under various missing data conditions,
> as described in Tabouy, Barbillon and Chiquet (2019)
> [10.1080/01621459.2018.1562934](https://doi.org/10.1080/01621459.2018.1562934).

## Installation

The Last CRAN version is available via

``` r
install.packages("missSBM")
```

The development version is available via

``` r
devtools::install_github("jchiquet/missSBM")
```

## Reference

Please cite our work using the following reference:

Timothée Tabouy, Pierre Barbillon & Julien Chiquet (2019) “Variational
Inference for Stochastic Block Models from Sampled Data”, *Journal of
the American Statistical Association*, DOI:
[10.1080/01621459.2018.1562934](https://doi.org/10.1080/01621459.2018.1562934)
