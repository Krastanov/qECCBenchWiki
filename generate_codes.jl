using QuantumClifford
using QuantumClifford.ECC

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

include("code_metadata.jl")

include("code_markdown.jl")
include("code_figures.jl")
include("code_result_db.jl")
include("code_evaluation.jl")

#

function run_evaluations(code_metadata)
    for (codeentry, metadata) in code_metadata
        codes = [codeentry(instance_args...) for instance_args in metadata[:family]]
        decoders = metadata[:decoders]
        setups = metadata[:setups]
        errrange = metadata[:errrange]
        println("Evaluating $(codeentry) ...")
        e, n, r = evaluate_codes_decoders_setups(codes, decoders, setups; errrange)
    end
end

function prep_folders(code_metada)
    for (codeentry, metadata) in code_metadata
        isdir("codes/$codeentry") || mkdir("codes/$codeentry")
    end
end

function prep_figures(code_metada)
    for (codeentry, metadata) in code_metadata
        println("Plotting $(codeentry) ...")
        codes = [codeentry(instance_args...) for instance_args in metadata[:family]]
        decoders = metadata[:decoders]
        setups = metadata[:setups]
        errrange = metadata[:errrange]
        e = logrange(errrange...)
        r = dbnarray(codes, decoders, setups, e)

        single_error = length(decoders)>1 || decoders==[TableDecoder]

        # Plotting summary fig
        f = make_decoder_figure(e, r;
            title="$(codeentry)",
            colorlabels=string.(codes),
            linestylelabels=string.(decoders),
            markerlabels=string.(setups),
            single_error
        )
        save("codes/$(codeentry)/totalsummary.png", f)

        # Plotting code instances
        for c in codes
            # Plotting stabilizer
            f = Figure(size=(400,400))
            sf = f[1,1]
            stabilizerplot_axis(sf, parity_checks(c))
            save("codes/$(codeentry)/$(c).png", f)
            # Plotting circuits
            if nqubits(c) <= 15
                try
                    savecircuit(naive_encoding_circuit(c), "codes/$(codeentry)/$(c)_encoding.png")
                catch
                    @error "$(c) failed to plot `naive_encoding_circuit`"
                end
                try
                    savecircuit(naive_syndrome_circuit(c)[1], "codes/$(codeentry)/$(c)_naive_syndrome.png")
                catch
                    @error "$(c) failed to plot `naive_syndrome_circuit`"
                end
                try
                    savecircuit(vcat(shor_syndrome_circuit(c)[1:2]...), "codes/$(codeentry)/$(c)_naive_syndrome.png")
                catch
                    @error "$(c) failed to plot `shor_syndrome_circuit`"
                end
            end
        end
    end
end

function prep_markdown(code_metada)
    for (codeentry, metadata) in code_metadata
        make_markdown_page(codeentry, metadata)
    end
end

#

function prep_everything(code_metada)
    prep_folders(code_metada)
    prep_figures(code_metada)
    prep_markdown(code_metada)
end
