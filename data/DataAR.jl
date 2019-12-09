module DataAR

using DataFrames
import PolynomialRoots.roots
using Distributions

export generateAR, generateHAR, generateSIN


function generate_coefficients(order::Int)
    stable = false
    true_a = []
    # Keep generating coefficients until we come across a set of coefficients
    # that correspond to stable poles
    while !stable
        true_a = randn(order)
        coefs =  append!([1.0], -true_a)
        #reverse!(coefs)
        if false in ([abs(root) for root in roots(coefs)] .> 1)
            continue
        else
            stable = true
        end
    end
    return true_a
end

function generateAR(num::Int, order::Int; nvar=1, stat=true, coefs=nothing)
    d = Normal()
    if isnothing(coefs) && stat
        coefs = generate_coefficients(order)
    else
        coefs = randn(order)
    end
    inits = randn(order)
    data = Vector{Vector{Float64}}(undef, num+3*order)
    data[1] = inits
    for i in 2:num+3*order
        data[i] = insert!(data[i-1][1:end-1], 1, rand(Distributions.Normal(coefs'data[i-1], sqrt(nvar)), 1)[1])
    end
    data = data[1+3*order:end]
    return coefs, data
end

function generateHAR(num::Int, order::Int; levels=2, nvars=[], stat=true)
    # generate first layer
    if isempty(nvars)
        nvars = ones(levels)
    elseif length(nvars) != levels
        throw(DimensionMismatch("size of variances is not equal to number of levels"))
    end
    θ1, θ2 = generateAR(num, order; nvar=nvars[1], stat=stat)
    data = [θ1, θ2]
    for level in 2:levels
        states = Vector{Vector{Float64}}(undef, num)
        states[1] = randn(order)
        for i in 2:num
            states[i] = insert!(states[i-1][1:end-1], 1, rand(Distributions.Normal(data[level][i]'states[i-1], sqrt(nvars[2])), 1)[1])
        end
        push!(data, states)
    end
    return data
end

function generateSIN(num::Int, noise_variance=1/5)
    coefs = [2cos(1), -1]
    order = length(coefs)
    inits = [sin(1), sin(0)]
    data = Vector{Vector{Float64}}(undef, num+10*order)
    data[1] = inits
    for i in 2:num+10*order
        data[i] = insert!(data[i-1][1:end-1], 1, coefs'data[i-1])
        data[i][1] += sqrt(noise_variance)*randn()
    end
    data = data[1+10*order:end]
    return coefs, data
end

end  # module
