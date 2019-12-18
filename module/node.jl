using ForneyLab
using LinearAlgebra
import ForneyLab: SoftFactor, @ensureVariables, generateId, addNode!, associate!,
                  averageEnergy, Interface, Variable, slug, ProbabilityDistribution,
                  differentialEntropy, unsafeLogMean, unsafeMean, unsafeCov, unsafePrecision, unsafeMeanCov
import SpecialFunctions: polygamma, digamma
export Autoregressive, AR, averageEnergy, slug

"""
Description:

    A Gaussian mixture with mean-precision parameterization:

    f(y, θ, x, γ) = 𝒩(out|A(θ)x, V(γ)),

    where A(θ) =  θᵀ
                I	0

Interfaces:

    1. y (output vector)
    2. θ (autoregression coefficients)
    3. x (input vector)
    4. γ (precision)

Construction:

    Autoregressive(out, θ, in, γ, id=:some_id)
"""

mutable struct Autoregressive <: SoftFactor
    id::Symbol
    interfaces::Vector{Interface}
    i::Dict{Symbol,Interface}

    function Autoregressive(y, θ, x, γ; id=generateId(Autoregressive))
        @ensureVariables(y, x, θ, γ)
        self = new(id, Array{Interface}(undef, 4), Dict{Symbol,Interface}())
        addNode!(currentGraph(), self)
        self.i[:y] = self.interfaces[1] = associate!(Interface(self), y)
        self.i[:x] = self.interfaces[2] = associate!(Interface(self), x)
        self.i[:θ] = self.interfaces[3] = associate!(Interface(self), θ)
        self.i[:γ] = self.interfaces[4] = associate!(Interface(self), γ)
        return self
    end
end

slug(::Type{Autoregressive}) = "AR"

function averageEnergy(::Type{Autoregressive},
                       marg_y::ProbabilityDistribution{Multivariate},
                       marg_θ::ProbabilityDistribution{Multivariate},
                       marg_x::ProbabilityDistribution{Multivariate},
                       marg_γ::ProbabilityDistribution{Univariate})
    mθ, Vθ = unsafeMeanCov(marg_θ)
    my, Vy = unsafeMeanCov(marg_y)
    mx, Vx = unsafeMeanCov(marg_x)
    mγ = unsafeMean(marg_γ)
    -0.5*(unsafeLogMean(marg_γ)) +
    0.5*log(2*pi) + 0.5*mγ*(Vy[1]+(my[1])^2 - 2*mθ'*mx*my[1] +
    tr(Vθ*Vx) + mx'*Vθ*mx + mθ'*(Vx + mx*mx')*mθ)
end
