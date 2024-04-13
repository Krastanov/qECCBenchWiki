module Helpers

logrange(eᵐⁱⁿ, eᵐᵃˣ, steps) = exp.(range(log(eᵐⁱⁿ), log(eᵐᵃˣ), length=steps))

typenameof(t) = nameof(t)

function instancenameof(x)
    t = typeof(x)
    str = string(nameof(t))*"("
    nf = nfields(x)
    nb = sizeof(x)
    if nf != 0 || nb == 0
        for i in 1:nf
            f = fieldname(t, i)
            str *= string(getfield(x, i))
            if i < nf
                str *= ", "
            end
        end
    end
    str *= ")"
    return str
end

function skipredundantprefix(x)
    x = string(x)
    return chopprefix(chopprefix(x, "QuantumClifford.ECC."), "Main.")
end

function skipredundantsuffix(x)
    x = string(x)
    xs = split(x, "(")
    xs = [
        chopsuffix(chopsuffix(x, "Decoder"), "ECCSetup")
        for x in xs
    ]
    return join(xs, "(")
end

function skipredundantfix(x)
    x = string(x)
    return skipredundantsuffix(skipredundantprefix(x))
end


struct KWFun
    f
    kwargs
end

function (f::KWFun)(c)
    f.f(c; f.kwargs...)
end

typenameof(t::KWFun) = nameof(t.f)

function skipredundantfix(x::KWFun)
    f = skipredundantfix(x.f)
    return "$f($(join(["$k=$v" for (k,v) in pairs(x.kwargs)], ", ")))"
end

function Base.string(x::KWFun)
    f = string(x.f)
    return "$f(_;$(join(["$k=$v" for (k,v) in pairs(x.kwargs)], ", ")))"
end

end
