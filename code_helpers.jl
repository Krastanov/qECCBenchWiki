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

function skipredundantsuffix(x)
    x = string(x)
    xs = split(x, "(")
    xs = [chopsuffix(chopsuffix(x, "Decoder"), "ECCSetup") for x in xs]
    return join(xs, "(")
end

struct KWFun
    f
    kwargs
end

function (f::KWFun)(c)
    f.f(c; f.kwargs...)
end

function skipredundantsuffix(x::KWFun)
    f = skipredundantsuffix(x.f)
    return "$f($(join(["$k=$v" for (k,v) in pairs(x.kwargs)], ", ")))"
end

function Base.string(x::KWFun)
    f = string(x.f)
    return "$f(_;$(join(["$k=$v" for (k,v) in pairs(x.kwargs)], ", ")))"
end

typename(t) = nameof(t)
typename(t::KWFun) = nameof(t.f)
