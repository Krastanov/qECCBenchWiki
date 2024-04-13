module CodeBenchmark

using QuantumClifford
using QuantumClifford.ECC

using ProgressLogging: @withprogress, @logprogress

include("../_0.helpers_and_metadata/helpers.jl")
include("../_0.helpers_and_metadata/db_helpers.jl")

using .Helpers: logrange, instancenameof, skipredundantfix, typenameof
using .DBHelpers: dbrow, dbnarray, dbrow!

isreusableandthreadsafe(_) = false
isreusableandthreadsafe(::Type{TableDecoder}) = true

goodnsamples(m) = get(ENV,"ECCBENCHWIKI_QUICKCHECK", "")=="" ? Int(ceil(40/m)) : 10

function evaluate_codes_decoders_setups(codes,decoders,setups;
    errrange=(eᵐⁱⁿ, eᵐᵃˣ, steps), # the default from globals defined in code_metadata.jl
)
    errors = logrange(errrange...)
    nsamples = goodnsamples.(errors)
    total_samples = sum(nsamples)
    results = zeros(length(errors), 2, length(codes), length(decoders), length(setups))
    nᶜᵈˢ = length(codes)*length(decoders)*length(setups)
    doneᶜᵈˢ = Threads.Atomic{Int}(0)
    Threads.@sync @withprogress name="code⊗decoder⊗setup" for iᶜ in eachindex(codes)
        c = codes[iᶜ]
        cname = skipredundantfix(instancenameof(c))
        H = parity_checks(c)
        for iᵈ in eachindex(decoders)
            d = decoders[iᵈ]
            dname = skipredundantfix(d)
            decoder = isreusableandthreadsafe(d) ? d(c) : nothing
            for iˢ in eachindex(setups)
                s = setups[iˢ]
                sname = skipredundantfix(s)
                #Threads.@spawn begin
                    #@show (c, d, s, Threads.threadid())
                    done_samples = 0
                    @withprogress name="$(cname) $(dname) $(sname)" for iᵉ in reverse(eachindex(errors)) # reverse to get the smaller tasks first, to populate the progress bar
                        e = errors[iᵉ]
                        decoder = isnothing(decoder) ? d(c) : decoder
                        setup = s(e)
                        samples = goodnsamples(e)
                        r = evaluate_decoder(decoder, setup, samples)
                        _,_,_,_,_, logx, logz = dbrow!(c,d,s,e,samples,r...)
                        results[iᵉ,:,iᶜ,iᵈ,iˢ] .= (logx, logz)
                        done_samples += samples
                        @logprogress done_samples/total_samples
                    end
                    Threads.atomic_add!(doneᶜᵈˢ, 1)
                    @logprogress doneᶜᵈˢ[]/nᶜᵈˢ
                #end
            end
        end
    end
    return errors, nsamples, results
end

end