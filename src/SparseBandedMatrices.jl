module SparseBandedMatrices

using LinearAlgebra, .Threads

struct SparseBandedMatrix{T} <: AbstractMatrix{T}
    size :: Tuple{Int, Int}
    indices :: Vector{Int}
    diags :: Vector{Vector{T}}
    function SparseBandedMatrix{T}(::UndefInitializer, N, M) where T
        size = (N, M)
        indices = Int[]
        diags = Vector{T}[]
        new(size, indices, diags)
    end
    function SparseBandedMatrix{T}(ind_vals, diag_vals, N, M) where T
        size = (N, M)
        perm = sortperm(ind_vals)
        indices = ind_vals[perm]
        for i in 1 : length(indices) - 1
            @assert indices[i] != indices[i + 1]
        end
        diags = diag_vals[perm]
        new(size, indices, diags)
    end
end

function Base.size(M :: SparseBandedMatrix) 
    M.size
end

function Base.getindex(M :: SparseBandedMatrix{T}, i :: Int, j :: Int, I :: Int...) where T
    @boundscheck checkbounds(M, i, j, I...)
    rows, cols = size(M)
    wanted_ind = rows - i + j
    ind = searchsortedfirst(M.indices, wanted_ind)
    if (ind <= length(M.indices) && M.indices[ind] == wanted_ind)
        if (i > j)
            return M.diags[ind][j]
        else
            return M.diags[ind][i]
        end
    end
    zero(T)
end

function Base.setindex!(M :: SparseBandedMatrix{T}, val, i :: Int, j :: Int, I :: Int...) where T 
    @boundscheck checkbounds(M, i, j, I...) 
    rows = size(M, 1)
    wanted_ind = rows - i + j
    ind = searchsortedfirst(M.indices, wanted_ind)
    if (ind > length(M.indices) || M.indices[ind] != wanted_ind)
        insert!(M.indices, ind, wanted_ind)
        insert!(M.diags, ind, zeros(T, rows - abs(wanted_ind - rows)))
    end
    if (i > j)
        M.diags[ind][j] = val isa T ? val : convert(T, val)::T
    else
        M.diags[ind][i] = val isa T ? val : convert(T, val)::T
    end
    val
 end

 function setdiagonal!(M :: SparseBandedMatrix{T}, diagvals, lower :: Bool) where T
    rows, cols = size(M) 
    if length(diagvals) > rows
        error("size of diagonal is too big for the matrix")
    end
    if lower
        wanted_ind = length(diagvals)
    else
        wanted_ind = 2 * rows - length(diagvals)
    end

    ind = searchsortedfirst(M.indices, wanted_ind)
    if (ind > length(M.indices) || M.indices[ind] != wanted_ind)
        insert!(M.indices, ind, wanted_ind)
        insert!(M.diags, ind, diagvals isa Vector{T} ? diagvals : convert(Vector{T}, diagvals)::Vector{T}) 
    else
        for i in eachindex(diagvals)
            M.diags[ind][i] = diagvals[i] isa T ? diagvals[i] : convert(T, diagvals[i])::T
        end
    end
    diagvals
end

# C = Cb + aAB
function LinearAlgebra.mul!(C :: Matrix{T}, A:: SparseBandedMatrix{T}, B :: Matrix{T}, a :: Number, b :: Number) where T
    @assert size(A, 2) == size(B, 1)
    @assert size(A, 1) == size(C, 1)
    @assert size(B, 2) == size(C, 2)
    C.*=b

    rows, cols = size(A)
    @inbounds for (ind, location) in enumerate(A.indices)
        @threads for i in 1:length(A.diags[ind])
            # value: diag[i]
            # index in array: 
            #       if ind < rows(A), then index = (rows - loc + i, i)
            #       else index = (i, loc - cols + i)
            val = A.diags[ind][i] * a
            if location < rows 
                index_i = rows - location + i 
                index_j = i 
            else
                index_i = i 
                index_j = location - cols + i 
            end
            #A[index_i, index_j] * B[index_j, j] = C[index_i, j]
            for j in 1 : size(B, 2)
                C[index_i, j] = fma(val, B[index_j, j], C[index_i, j])
            end
        end
    end
    C
end

# C = Cb + aBA
function LinearAlgebra.mul!(C :: Matrix{T}, A:: Matrix{T}, B :: SparseBandedMatrix{T}, a :: Number, b :: Number) where T
    @assert size(A, 2) == size(B, 1)
    @assert size(A, 1) == size(C, 1)
    @assert size(B, 2) == size(C, 2)

    C.*=b

    rows, cols = size(B)
    @inbounds for (ind, location) in enumerate(B.indices)
        @threads for i in eachindex(B.diags[ind])
                val = B.diags[ind][i] * a
                if location < rows 
                    index_i = rows - location + i 
                    index_j = i 
                else
                    index_i = i 
                    index_j = location - cols + i 
                end
            @simd for j in 1 : size(A, 1)
                C[j, index_j] = fma(val, A[j, index_i], C[j, index_j])
            end
        end
    end
    C
end

function LinearAlgebra.mul!(C :: SparseBandedMatrix{T}, A:: SparseBandedMatrix{T}, B :: SparseBandedMatrix{T}, a :: Number, b :: Number) where T
    @assert size(A, 2) == size(B, 1)
    @assert size(A, 1) == size(C, 1)
    @assert size(B, 2) == size(C, 2)

    C.*=b

    rows_a, cols_a = size(A)
    rows_b, cols_b = size(B)
    @inbounds for (ind_a, location_a) in enumerate(A.indices)
        @threads for i in eachindex(A.diags[ind_a])
            val_a = A.diags[ind_a][i] * a
            if location_a < rows_a 
                index_ia = rows_a - location_a + i 
                index_ja = i 
            else
                index_ia = i 
                index_ja = location_a - cols_a + i 
            end
            min_loc = rows_b - index_ja + 1
            max_loc = 2 * rows_b - index_ja
            for (ind_b, location_b) in enumerate(B.indices)
                #index_ib = index_ja
                #       if ind < rows(A), then index = (rows - loc + i, i)
                #rows - loc + j = index_ja, j = index_ja - rows + loc
                #       else index = (i, loc - cols + i)
                # if location < rows(B), then 
                if location_b <= rows_b && location_b >= min_loc
                    j = index_ja - rows_b + location_b
                    index_jb = j
                    val_b = B.diags[ind_b][j]
                    C[index_ia, index_jb] = muladd(val_a, val_b, C[index_ia, index_jb])         
                elseif location_b > rows_b && location_b <= max_loc
                    j = index_ja
                    index_jb = location_b - cols_b + j 
                    val_b = B.diags[ind_b][j]
                    C[index_ia, index_jb] = muladd(val_a, val_b, C[index_ia, index_jb])         
                end           
            end
        end
    end
    C
end

function LinearAlgebra.mul!(C :: Matrix{T}, A:: SparseBandedMatrix{T}, B :: SparseBandedMatrix{T}, a :: Number, b :: Number) where T
    @assert size(A, 2) == size(B, 1)
    @assert size(A, 1) == size(C, 1)
    @assert size(B, 2) == size(C, 2)

    C.*=b

    rows_a, cols_a = size(A)
    rows_b, cols_b = size(B)
    @inbounds for (ind_a, location_a) in enumerate(A.indices)
        @threads for i in eachindex(A.diags[ind_a])
            val_a = A.diags[ind_a][i] * a
            if location_a < rows_a 
                index_ia = rows_a - location_a + i 
                index_ja = i 
            else
                index_ia = i 
                index_ja = location_a - cols_a + i 
            end
            min_loc = rows_b - index_ja + 1
            max_loc = 2 * rows_b - index_ja
            for (ind_b, location_b) in enumerate(B.indices)
                #index_ib = index_ja
                #       if ind < rows(A), then index = (rows - loc + i, i)
                #rows - loc + j = index_ja, j = index_ja - rows + loc
                #       else index = (i, loc - cols + i)
                # if location < rows(B), then 
                if location_b <= rows_b && location_b >= min_loc
                    j = index_ja - rows_b + location_b
                    index_jb = j
                    val_b = B.diags[ind_b][j]
                    C[index_ia, index_jb] = muladd(val_a, val_b, C[index_ia, index_jb])         
                elseif location_b > rows_b && location_b <= max_loc
                    j = index_ja
                    index_jb = location_b - cols_b + j 
                    val_b = B.diags[ind_b][j]
                    C[index_ia, index_jb] = muladd(val_a, val_b, C[index_ia, index_jb])         
                end           
            end
        end
    end
    C
end

export SparseBandedMatrix, size, getindex, setindex!, setdiagonal!, mul!

end