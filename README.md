# SparseBandedMatrices

[![Join the chat at https://julialang.zulipchat.com #sciml-bridged](https://img.shields.io/static/v1?label=Zulip&message=chat&color=9558b2&labelColor=389826)](https://julialang.zulipchat.com/#narrow/stream/279055-sciml-bridged)
[![Stable Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://docs.sciml.ai/SparseBandedMatrices/stable/)
[![Dev Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://docs.sciml.ai/SparseBandedMatrices/dev/)

[![CI](https://github.com/SciML/SparseBandedMatrices.jl/actions/workflows/Tests.yml/badge.svg)](https://github.com/SciML/SparseBandedMatrices.jl/actions/workflows/Tests.yml)
[![codecov](https://codecov.io/gh/SciML/SparseBandedMatrices.jl/branch/master/graph/badge.svg?)](https://codecov.io/gh/SciML/SparseBandedMatrices.jl)
[![Package Downloads](https://shields.io/endpoint?url=https://pkgs.genieframework.com/api/v1/badge/SparseBandedMatrices)](https://pkgs.genieframework.com?packages=SparseBandedMatrices)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor%27s%20Guide-blueviolet)](https://github.com/SciML/ColPrac)
[![SciML Code Style](https://img.shields.io/static/v1?label=code%20style&message=SciML&color=9558b2&labelColor=389826)](https://github.com/SciML/SciMLStyle)

A fast implementation of Sparse Banded Matrices in Julia. Primarily developed for use in a Butterfly LU factorization implemented in [RecursiveFactorization.jl](https://github.com/JuliaLinearAlgebra/RecursiveFactorization.jl) and [LinearSolve.jl](https://github.com/SciML/LinearSolve.jl).

## Examples
```julia
using SparseBandedMatrices

A = SparseBandedMatrix{Float64}(undef, 5, 5)
A[1,1] = 5
setdiagonal!(A, [3,4,5], true) # sets the third diagonal from the bottom to have the values 3, 4, and 5

B = SparseBandedMatrix{Float64}([1, 8], [[3], [-2, 5, 1, 3]], 6, 6)
```

## Intended Considerations
The implementation of SparseBandedMatrices is designed to be fast for matrix and vector multiplications. 