using SafeTestsets, Test

@testset "SparseBandedMatrices" begin
    @safetestset "Constructors" begin
        using SparseBandedMatrices

        A = SparseBandedMatrix{Float64}(undef, 5, 5)
        A[1, 1] = 2
        @test A[1, 1] == 2.0
        A[4, 1] = 0
        @test A[4, 1] == 0.0
        A[1, 3] = 5
        @test A[1, 3] == 5.0

        @test size(A) == (4,4)
    end

    @safetestset "Multiplication" begin
        
    end

    

end