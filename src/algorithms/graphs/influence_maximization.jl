using Graphs

"""
    Simulate the Independent Cascade (IC) model of influence spread.
    Given a directed graph `g`, edge influence probabilities `weights`,
    and an initial seed set `seed_set`, runs `num_simulations` simulations
    and returns the average number of activated nodes.
"""
function simulate_ic(g::SimpleDiGraph, 
                     weights::Dict{Tuple{Int, Int}, Float64}, 
                     seed_set::Vector{Int}, 
                     num_simulations::Int = 10_000)

    total_activated = 0

    for _ ∈ 1:num_simulations
        activated = Set(seed_set)
        newly_activated = Set(seed_set)

        while !isempty(newly_activated)
            next_activated = Set{Int}()
            for u ∈ newly_activated
                for v ∈ outneighbors(g, u)
                    if v ∉ activated && rand() ≤ get(weights, (u, v), 0.0)
                        push!(next_activated, v)
                    end
                end
            end
            newly_activated = next_activated
            union!(activated, newly_activated)
        end

        total_activated += length(activated)
    end

    return total_activated / num_simulations
end


"""
    Influence Maximization in Directed Graphs in the Independent Cascade Model.
    Given a directed graph `g`, edge influence probabilities `weights`,
    and a budget `k`, selects `k` nodes to maximize the expected spread of influence.
    Returns a 1 - 1/e approximate solution using a greedy algorithm.
"""
function influence_maximization_ic(g::SimpleDiGraph, weights::Dict{Tuple{Int, Int}, Float64}, k::Int)
    
end