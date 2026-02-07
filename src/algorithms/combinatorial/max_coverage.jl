"""
    max_coverage(subsets::Vector{Vector{Int64}}, k::Int64)

    Greedy approximation for the maximum coverage problem.
    Selects at most `k` subsets to maximize the number of covered elements.
    Returns the number of covered elements and the indices of the selected subsets.
    Approximation guarantee: `(1 - 1/e)` ≈ 0.632.
"""
function max_coverage(subsets::Vector{Vector{Int64}}, k::Int64)
    m = length(subsets)
    k = min(k, m)

    subset_sets = [Set(s) for s in subsets]
    covered = Set{Int64}()
    selected = Int64[]
    used = falses(m)

    for _ in 1:k
        best_idx = 0
        best_gain = 0

        for i in 1:m
            used[i] && continue
            gain = length(setdiff(subset_sets[i], covered))
            if gain > best_gain
                best_gain = gain
                best_idx = i
            end
        end

        best_idx == 0 && break

        push!(selected, best_idx)
        used[best_idx] = true
        union!(covered, subset_sets[best_idx])
    end

    return length(covered), sort!(selected)
end

precompile(max_coverage, (Vector{Vector{Int64}}, Int64))