using QuantumClifford
using QuantumClifford.ECC
using QuantumClifford.ECC: Surface # resolve name clashes

using CairoMakie

using Quantikz

using Mustache

using Logging
using TerminalLoggers
using ProgressLogging

using SQLite
using DBInterface

using DataFrames
using DataFramesMeta
using AlgebraOfGraphics

##

global_logger(TerminalLogger(right_justify=120))

##

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

##

include("code_metadata.jl")

include("code_markdown.jl")
include("code_figures.jl")
include("code_result_db.jl")
include("code_evaluation.jl")

#

function run_evaluations(code_metadata; include=nothing)
    for (codeentry, metadata) in code_metadata
        codeentryname = nameof(codeentry)
        !isnothing(include) && codeentry ∉ include && continue
        codes = [codeentry(instance_args...) for instance_args in metadata[:family]]
        decoders = metadata[:decoders]
        setups = metadata[:setups]
        errrange = metadata[:errrange]
        println("Evaluating $(codeentryname) ...")
        e, n, r = evaluate_codes_decoders_setups(codes, decoders, setups; errrange)
    end
end

function prep_folders(code_metada)
    for (codeentry, metadata) in code_metadata
        codeentryname = nameof(codeentry)
        isdir("codes/$codeentryname") || mkdir("codes/$codeentryname")
    end
end

function prep_figures(code_metada)
    for (codeentry, metadata) in code_metadata
        codeentryname = nameof(codeentry)
        println("Plotting $(codeentryname) ...")
        codes = [codeentry(instance_args...) for instance_args in metadata[:family]]
        decoders = metadata[:decoders]
        setups = metadata[:setups]
        errrange = metadata[:errrange]
        e = logrange(errrange...)
        r = dbnarray(codes, decoders, setups, e)

        single_error = length(decoders)>1 || decoders==[TableDecoder]

        # Plotting summary fig
        f = make_decoder_figure(e, r;
            title="$(codeentryname)",
            colorlabels=instancenameof.(codes),
            linestylelabels=skipredundantsuffix.(decoders),
            markerlabels=skipredundantsuffix.(setups),
            single_error
        )
        save("codes/$(codeentryname)/totalsummary.png", f)

        # Plotting code instances
        for c in codes
            # Plotting stabilizer
            f = Figure(size=(400,400))
            sf = f[1,1]
            stabilizerplot_axis(sf, parity_checks(c))
            save("codes/$(codeentryname)/$(instancenameof(c)).png", f)
            # Plotting circuits
            continue # skip circuit plots
            if nqubits(c) <= 15
                try
                    savecircuit(naive_encoding_circuit(c), "codes/$(codeentryname)/$(c)_encoding.png")
                catch
                    @error "$(c) failed to plot `naive_encoding_circuit`"
                end
                try
                    savecircuit(naive_syndrome_circuit(c)[1], "codes/$(codeentryname)/$(c)_naive_syndrome.png")
                catch
                    @error "$(c) failed to plot `naive_syndrome_circuit`"
                end
                try
                    savecircuit(vcat(shor_syndrome_circuit(c)[1:2]...), "codes/$(codeentryname)/$(c)_naive_syndrome.png")
                catch
                    @error "$(c) failed to plot `shor_syndrome_circuit`"
                end
            end
        end
    end
end

function prep_markdown(code_metada)
    for (codeentry, metadata) in code_metadata
        codeentryname = nameof(codeentry)
        make_markdown_page(codeentryname, metadata)
    end
end

#

function prep_everything(code_metada)
    prep_folders(code_metada)
    prep_figures(code_metada)
    prep_markdown(code_metada)
end
