# SparseBandedMatrices.jl Documentation

## Overview

A fast implementation of Sparse Banded Matrices in Julia. Primarily developed for use in a Butterfly LU factorization implemented in [RecursiveFactorization.jl](https://github.com/JuliaLinearAlgebra/RecursiveFactorization.jl) and [LinearSolve.jl](https://github.com/SciML/LinearSolve.jl).

## Installation

```julia
using Pkg
Pkg.add("SparseBandedMatrices")
```

## Examples

```julia
using SparseBandedMatrices

A = SparseBandedMatrix{Float64}(undef, 5, 5)
A[1,1] = 5
setdiagonal!(A, [3,4,5], true) # sets the third diagonal from the bottom to have the values 3, 4, and 5

B = SparseBandedMatrix{Float64}([1, 8], [[3], [-2, 5, 1, 3]], 6, 6)
```

## API Reference

```@docs
SparseBandedMatrix
setdiagonal!
```