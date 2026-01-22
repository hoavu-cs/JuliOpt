using Test
using JuliOpt

# helper to validate correctness
function validate_bin_packing(items, bin_capacity, num_bins, bins)
    # all bins used should be non-empty
    @test all(!isempty(b) for b in bins)
    @test length(bins) == num_bins
    
    # each item appears exactly once
    all_items = Int64[]
    for bin in bins
        append!(all_items, bin)
    end
    @test sort(all_items) == collect(1:length(items))
    @test length(all_items) == length(unique(all_items))
    
    # no bin exceeds capacity
    for bin in bins
        total = sum(items[i] for i in bin)
        @test total <= bin_capacity
    end
end

# helper to compute lower bound (sum of items / capacity, rounded up)
function lower_bound(items, bin_capacity)
    return div(sum(items) + bin_capacity - 1, bin_capacity)
end

@testset "Bin Packing" begin
    @testset "exact fit single bin" begin
        items = Int64[3, 2, 5]
        capacity = 10
        num_bins, bins = bin_packing(items, capacity)
        @test num_bins == 1
        validate_bin_packing(items, capacity, num_bins, bins)
    end
    
    @testset "single item per bin" begin
        items = Int64[10, 10, 10]
        capacity = 10
        num_bins, bins = bin_packing(items, capacity)
        @test num_bins == 3
        validate_bin_packing(items, capacity, num_bins, bins)
    end
    
    @testset "simple two bins" begin
        items = Int64[7, 5, 8, 3]
        capacity = 10
        num_bins, bins = bin_packing(items, capacity)
        @test num_bins == 3
        validate_bin_packing(items, capacity, num_bins, bins)
    end
    
    @testset "all items fit one bin" begin
        items = Int64[1, 2, 3, 4]
        capacity = 20
        num_bins, bins = bin_packing(items, capacity)
        @test num_bins == 1
        validate_bin_packing(items, capacity, num_bins, bins)
    end
    
    @testset "empty items" begin
        items = Int64[]
        capacity = 10
        num_bins, bins = bin_packing(items, capacity)
        @test num_bins == 0
        @test isempty(bins)
    end
    
    @testset "single item fits" begin
        items = Int64[5]
        capacity = 10
        num_bins, bins = bin_packing(items, capacity)
        @test num_bins == 1
        @test bins[1] == [1]
    end
    
    @testset "decreasing order advantage" begin
        items = Int64[6, 6, 5, 5, 5, 4, 4, 4, 4]
        capacity = 10
        num_bins, bins = bin_packing(items, capacity)
        lb = lower_bound(items, capacity)
        @test num_bins <= ceil(Int, 11/9 * lb) + 1
        validate_bin_packing(items, capacity, num_bins, bins)
    end
    
    @testset "identical items" begin
        items = Int64[3, 3, 3, 3, 3, 3]
        capacity = 10
        num_bins, bins = bin_packing(items, capacity)
        @test num_bins == 2
        validate_bin_packing(items, capacity, num_bins, bins)
    end
    
    @testset "many small items" begin
        items = Int64[1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        capacity = 5
        num_bins, bins = bin_packing(items, capacity)
        @test num_bins == 2
        validate_bin_packing(items, capacity, num_bins, bins)
    end
    
    @testset "near lower bound" begin
        items = Int64[4, 4, 4, 4, 3, 3, 3, 3]
        capacity = 10
        num_bins, bins = bin_packing(items, capacity)
        lb = lower_bound(items, capacity)
        @test num_bins >= lb
        # Only fail if solution exceeds BFD theoretical guarantee: 11/9 * OPT + 1
        @test num_bins <= ceil(Int, 11/9 * lb) + 1
        validate_bin_packing(items, capacity, num_bins, bins)
    end
    
    @testset "classic example" begin
        items = Int64[6, 12, 3, 7, 5, 8, 2, 9]
        capacity = 15
        num_bins, bins = bin_packing(items, capacity)
        lb = lower_bound(items, capacity)
        @test num_bins <= ceil(Int, 11/9 * lb) + 1
        validate_bin_packing(items, capacity, num_bins, bins)
    end
    
    @testset "worst case for FFD" begin
        items = Int64[7, 7, 6, 6, 5, 5, 4, 4]
        capacity = 13
        num_bins, bins = bin_packing(items, capacity)
        lb = lower_bound(items, capacity)
        @test num_bins <= ceil(Int, 11/9 * lb) + 1
        validate_bin_packing(items, capacity, num_bins, bins)
    end
end

