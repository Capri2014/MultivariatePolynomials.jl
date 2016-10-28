function show(io::IO, x::PolyVar)
  print(io, x.name)
end

function show(io::IO, x::Monomial)
  if sum(abs(x.z)) == 0
    show(io, 1)
  else
    needsep = false
    for i in 1:nvars(x)
      if x.z[i] > 0
        if needsep
          print(io, '*')
        end
        show(io, x.vars[i])
        if x.z[i] > 1
          print(io, '^')
          print(io, x.z[i])
        else
          needsep = true
        end
      end
    end
  end
end

function show(io::IO, x::MonomialVector)
  print(io, typeof(x))
  print(io, "[ ")
  for (i, m) in enumerate(x)
    print(io, m)
    if i != length(x)
      print(io, ", ")
    end
  end
  print(io, " ]")
end

function Base.show(io::IO, t::Term)
  cst = sum(abs(t.x.z)) == 0
  if t.α != 1 || cst
    print(io, t.α)
  end
  if !cst
    print(io, t.x)
  end
end

function Base.show(io::IO, p::VecPolynomial)
  for (i, t) in enumerate(p)
    print(io, t)
    if i != length(p)
      print(io, " + ")
    end
  end
end

function Base.show(io::IO, p::SOSDecomposition)
  for (i, q) in enumerate(p)
    print(io, "(")
    print(io, q)
    print(io, ")^2")
    if i != length(p)
      print(io, " + ")
    end
  end
end

function Base.show(io::IO, p::RationalPoly)
  print(io, p.num)
  print(io, " / ")
  print(io, p.den)
end
