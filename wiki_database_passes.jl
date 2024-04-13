using Logging
using TerminalLoggers
using ProgressLogging

global_logger(TerminalLogger(right_justify=120))

include("_0.helpers_and_metadata/helpers.jl")
include("_0.helpers_and_metadata/db_helpers.jl")

using .Helpers: logrange, instancenameof, skipredundantfix
using .DBHelpers: dbrow, dbnarray, dbrow!

include("_0.helpers_and_metadata/code_metadata.jl")

using .CodeMetadata: code_metadata
using .Helpers: typenameof

include("_1.code_benchmark_pass/benchmark.jl")
include("_2.markdown_generation_pass/markdown.jl")
include("_2.markdown_generation_pass/figures.jl")

using .CodeBenchmark: evaluate_codes_decoders_setups
using .CodeFigures: prep_figures
using .CodeMarkdown: prep_markdown

#

function run_evaluations(code_metadata; include=nothing)
    for (codetype, metadata) in code_metadata
        codetypename = typenameof(codetype)
        !isnothing(include) && codetype ∉ include && continue
        codes = [codetype(instance_args...) for instance_args in metadata[:family]]
        decoders = metadata[:decoders]
        setups = metadata[:setups]
        errrange = metadata[:errrange]
        @info "Evaluating $(codetypename) ..."
        e, n, r = evaluate_codes_decoders_setups(codes, decoders, setups; errrange)
    end
end

function prep_folders(code_metadata)
    for (codetype, metadata) in code_metadata
        codetypename = typenameof(codetype)
        isdir("codes/$codetypename") || mkdir("codes/$codetypename")
    end
end

function prep_everything(code_metada)
    prep_folders(code_metada)
    prep_figures(code_metada)
    prep_markdown(code_metada)
end
