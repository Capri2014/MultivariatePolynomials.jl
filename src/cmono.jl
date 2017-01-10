export PolyVar, Monomial, MonomialVector, @polyvar

# Variable vector x returned garanteed to be sorted so that if p is built with x then vars(p) == x
macro polyvar(args...)
    reduce((x,y) -> :($x; $y), :(), [buildpolyvar(arg, true) for arg in args])
end

# TODO equality should be between name ?
immutable PolyVar <: PolyType
    name::AbstractString
end
copy(x::PolyVar) = x

vars(x::PolyVar) = [x]
nvars(::PolyVar) = 1

# Invariant:
# vars is increasing
# z may contain 0's (otherwise, getindex of MonomialVector would be inefficient)
type Monomial <: PolyType
    vars::Vector{PolyVar}
    z::Vector{Int}

    function Monomial(vars::Vector{PolyVar}, z::Vector{Int})
        if length(vars) != length(z)
            throw(ArgumentError("There should be as many vars than exponents"))
        end
        new(vars, z)
    end
end
Monomial() = Monomial(PolyVar[], Int[])
deg(x::Monomial) = sum(x.z)

nvars(x::Monomial) = length(x.vars)

Base.convert(::Type{Monomial}, x::PolyVar) = Monomial([x], [1])

copy(m::Monomial) = Monomial(copy(m.vars), copy(m.z))

isconstant(x::Monomial) = sum(x.z) == 0

# Invariant: Always sorted and no zero vector
type MonomialVector <: PolyType
    vars::Vector{PolyVar}
    Z::Vector{Vector{Int}}

    function MonomialVector(vars::Vector{PolyVar}, Z::Vector{Vector{Int}})
        for z in Z
            if length(vars) != length(z)
                error("There should be as many vars than exponents")
            end
        end
        @assert issorted(Z, rev=true)
        new(vars, Z)
    end
end
MonomialVector() = MonomialVector(PolyVar[], Vector{Int}[])

copy(m::MonomialVector) = MonomialVector(copy(m.vars), copy(m.Z))

function getindex(x::MonomialVector, I)
    MonomialVector(x.vars, x.Z[I])
end
function getindex(x::MonomialVector, i::Integer)
    Monomial(x.vars, x.Z[i])
end
length(x::MonomialVector) = length(x.Z)
isempty(x::MonomialVector) = length(x) == 0
start(::MonomialVector) = 1
done(x::MonomialVector, state) = length(x) < state
next(x::MonomialVector, state) = (Monomial(x.vars, x.Z[state]), state+1)

extdeg(x::MonomialVector) = extrema(sum.(x.Z))
mindeg(x::MonomialVector) = minimum(sum.(x.Z))
maxdeg(x::MonomialVector) = maximum(sum.(x.Z))

vars{T<:Union{Monomial,MonomialVector}}(x::T) = x.vars

# list them in decreasing Graded Lexicographic Order
function getZfordegs(n, degs, filter::Function)
    Z = Vector{Vector{Int}}()
    for deg in sort(degs, rev=true)
        z = zeros(Int, n)
        z[1] = deg
        while true
            if filter(z)
                push!(Z, z)
                z = copy(z)
            end
            if z[end] == deg
                break
            end
            sum = 1
            for j in (n-1):-1:1
                if z[j] != 0
                    z[j] -= 1
                    z[j+1] += sum
                    break
                else
                    sum += z[j+1]
                    z[j+1] = 0
                end
            end
        end
    end
    @assert issorted(Z, rev=true)
    Z
end

function MonomialVector(vars::Vector{PolyVar}, degs, filter::Function = x->true)
    MonomialVector(vars, getZfordegs(length(vars), degs, filter))
end
MonomialVector(vars::Vector{PolyVar}, degs::Int, filter::Function = x->true) = MonomialVector(vars, [degs], filter)
function monomials(vars::Vector{PolyVar}, degs, filter::Function = x->true)
    Z = getZfordegs(length(vars), degs, filter)
    [Monomial(vars, z) for z in Z]
end
monomials(vars::Vector{PolyVar}, degs::Int, filter::Function = x->true) = monomials(vars, [degs], filter)

#function MonomialVector{T<:Union{PolyVar,Monomial,Term,Int}}(X::Vector{T})
function buildZvarsvec{T<:Union{PolyType,Int}}(X::Vector{T})
    varsvec = Vector{PolyVar}[ (isa(x, PolyType) ? vars(x) : PolyVar[]) for x in X ]
    allvars, maps = myunion(varsvec)
    nvars = length(allvars)
    Z = [zeros(Int, nvars) for i in 1:length(X)]
    offset = 0
    for (i, x) in enumerate(X)
        if isa(x, PolyVar)
            @assert length(maps[i]) == 1
            z = [1]
        elseif isa(x, Monomial)
            z = x.z
        elseif isa(x, Term)
            z = x.x.z
        else
            @assert isa(x, Int)
            z = Int[]
        end
        Z[i][maps[i]] = z
    end
    allvars, Z
end
function sortmonovec{T<:Union{PolyType,Int}}(X::Vector{T})
    allvars, Z = buildZvarsvec(X)
    perm = sortperm(Z, rev=true)
    perm, MonomialVector(allvars, Z[perm])
end
function MonomialVector{T<:Union{PolyType,Int}}(X::Vector{T})
    allvars, Z = buildZvarsvec(X)
    sort!(Z, rev=true)
    MonomialVector(allvars, Z)
end