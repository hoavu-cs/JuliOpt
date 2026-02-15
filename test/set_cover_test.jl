using Test
using JuliOpt
using Combinatorics

# helper to validate a set cover solution
function validate_set_cover(subsets, costs, selected, total_cost)
    # indices valid
    @test all(1 .<= selected .<= length(subsets))
    # no duplicate sets
    @test length(selected) == length(unique(selected))
    # total cost matches
    @test total_cost ≈ sum(costs[i] for i in selected)
    # all elements covered
    all_elements = Set{Int}()
    for s in subsets
        union!(all_elements, s)
    end
    covered = Set{Int}()
    for i in selected
        union!(covered, subsets[i])
    end
    @test all_elements ⊆ covered
end

@testset "Set Cover" begin
    @testset "basic example" begin
        subsets = [Int[1, 2, 3], Int[2, 4], Int[3, 4, 5], Int[5]]
        costs = Float64[3.0, 2.0, 3.0, 1.0]
        total_cost, selected = set_cover(subsets, costs)
        validate_set_cover(subsets, costs, selected, total_cost)
    end

    @testset "single set covers all" begin
        subsets = [Int[1, 2, 3], Int[1], Int[2, 3]]
        costs = Float64[1.0, 5.0, 5.0]
        total_cost, selected = set_cover(subsets, costs)
        @test total_cost == 1.0
        @test selected == Int[1]
        validate_set_cover(subsets, costs, selected, total_cost)
    end

    @testset "disjoint sets" begin
        subsets = [Int[1, 2], Int[3, 4], Int[5, 6]]
        costs = Float64[1.0, 1.0, 1.0]
        total_cost, selected = set_cover(subsets, costs)
        @test total_cost == 3.0
        @test sort(selected) == Int[1, 2, 3]
        validate_set_cover(subsets, costs, selected, total_cost)
    end

    @testset "greedy picks cost-effective sets" begin
        # set 1 covers all 4 elements for cost 4 (ratio 1.0)
        # sets 2,3 each cover 2 elements for cost 1 (ratio 2.0) and together cover all
        subsets = [Int[1, 2, 3, 4], Int[1, 2], Int[3, 4]]
        costs = Float64[4.0, 1.0, 1.0]
        total_cost, selected = set_cover(subsets, costs)
        @test total_cost == 2.0
        @test sort(selected) == Int[2, 3]
        validate_set_cover(subsets, costs, selected, total_cost)
    end

    @testset "unit costs" begin
        subsets = [Int[1, 2, 3], Int[4, 5], Int[1, 4], Int[2, 3, 5]]
        costs = Float64[1.0, 1.0, 1.0, 1.0]
        total_cost, selected = set_cover(subsets, costs)
        @test length(selected) <= 3
        validate_set_cover(subsets, costs, selected, total_cost)
    end

    @testset "identical sets picks cheapest" begin
        subsets = [Int[1, 2], Int[1, 2], Int[1, 2]]
        costs = Float64[5.0, 2.0, 3.0]
        total_cost, selected = set_cover(subsets, costs)
        @test total_cost == 2.0
        @test selected == Int[2]
    end

    @testset "large overlapping sets" begin
        subsets = [
            Int[1, 2, 3, 4, 5],
            Int[4, 5, 6, 7, 8],
            Int[7, 8, 9, 10],
            Int[1, 6, 9],
            Int[2, 3, 10]
        ]
        costs = Float64[5.0, 5.0, 4.0, 3.0, 3.0]
        total_cost, selected = set_cover(subsets, costs)
        validate_set_cover(subsets, costs, selected, total_cost)
    end

    @testset "approximation quality vs brute force" begin
        subsets = [
            Int[1, 2],
            Int[3, 4],
            Int[5, 6],
            Int[1, 3, 5],
            Int[2, 4, 6],
            Int[1, 2, 3, 4, 5, 6]
        ]
        costs = Float64[2.0, 2.0, 2.0, 3.0, 3.0, 7.0]
        m = length(subsets)

        # derive universe from subsets
        univ_set = Set{Int}()
        for s in subsets
            union!(univ_set, s)
        end

        # brute force optimal
        best_cost = Inf
        for r in 1:m
            for combo in combinations(1:m, r)
                covered = Set{Int}()
                for i in combo
                    union!(covered, subsets[i])
                end
                if univ_set ⊆ covered
                    c = sum(costs[i] for i in combo)
                    best_cost = min(best_cost, c)
                end
            end
        end

        greedy_cost, selected = set_cover(subsets, costs)
        # greedy should achieve within O(ln n) of optimal
        n = length(univ_set)
        harmonic = sum(1.0 / k for k in 1:n)
        @test greedy_cost <= harmonic * best_cost + 1e-9
        validate_set_cover(subsets, costs, selected, greedy_cost)
    end

    # @testset "approximation quality vs brute-force for large subsets" begin
    #     # 1. Setup a large universe
    #     n = 1_000_000
    #     m = 15
        
    #     # Create large subsets with specific overlaps to ensure the greedy
    #     # choice isn't just "pick the biggest one."
    #     # We'll create a "cheap" optimal path and an "expensive" greedy trap.
        
    #     subsets = Vector{Vector{Int}}(undef, m)
        
    #     # The Optimal Path: 5 sets covering 200k each, cost 2.0 each (Total 10.0)
    #     for i in 1:5
    #         subsets[i] = collect(((i-1)*200_000 + 1) : (i*200_000))
    #     end
        
    #     # The Greedy Trap: 1 set covering 900k elements, but cost 15.0
    #     # It has a better initial ratio (15/900k) than the optimal sets (2/200k),
    #     # but picking it makes the remaining 100k very expensive to cover.
    #     subsets[6] = collect(1:900_000)
        
    #     # Fill remaining with random large overlaps
    #     for i in 7:m
    #         subsets[i] = unique(rand(1:n, 300_000))
    #     end
        
    #     costs = rand(10.0:0.1:20.0, m)
    #     costs[1:5] .= 2.0   # Optimal sets are cheap
    #     costs[6] = 15.0     # Trap set
        
    #     univ_set = Set(1:n)

    #     # 2. Brute Force Optimal (O(2^m))
    #     # We use a simple loop over combinations. Since m=15, this is 32,768 iterations.
    #     best_cost = Inf
    #     for r in 1:m
    #         for combo in combinations(1:m, r)
    #             current_cost = sum(costs[i] for i in combo)
    #             current_cost >= best_cost && continue # Pruning
                
    #             # Use a BitVector for the brute force coverage check for speed
    #             check_bits = falses(n)
    #             for idx in combo
    #                 # Optimization: for large sets, this is the bottleneck
    #                 for el in subsets[idx]; check_bits[el] = true; end
    #             end
                
    #             if all(check_bits)
    #                 best_cost = current_cost
    #             end
    #         end
    #     end

    #     # 3. Run your BitVector set_cover
    #     greedy_cost, selected = set_cover(subsets, costs)

    #     # 4. Assertions
    #     harmonic = sum(1.0 / k for k in 1:n)
        
    #     # Theoretical Check
    #     @test greedy_cost <= (harmonic * best_cost) + 1e-9
        
    #     # Correctness Check
    #     covered_check = falses(n)
    #     for idx in selected
    #         for el in subsets[idx]; covered_check[el] = true; end
    #     end
    #     @test all(covered_check)
    # end

    @testset "single element per set" begin
        subsets = [Int[1], Int[2], Int[3]]
        costs = Float64[10.0, 20.0, 30.0]
        total_cost, selected = set_cover(subsets, costs)
        @test total_cost == 60.0
        @test sort(selected) == Int[1, 2, 3]
        validate_set_cover(subsets, costs, selected, total_cost)
    end
end
