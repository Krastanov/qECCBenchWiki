module CodeFigures

using Makie, CairoMakie
using Quantikz
using QuantumClifford: stab_to_gf2
using QuantumClifford.ECC: TableDecoder, stabilizerplot_axis, parity_checks, iscss, parity_checks_z, parity_checks_x

include("../_0.helpers_and_metadata/helpers.jl")
include("../_0.helpers_and_metadata/db_helpers.jl")

using .Helpers: logrange, instancenameof, skipredundantfix, typenameof
using .DBHelpers: dbrow, dbnarray, dbrow!

skipzeronan(xs) = (x for x in xs if x!=0 && !isnan(x))

function make_decoder_figure(phys_errors, results;
    title="",
    colors=Makie.wong_colors(),
    linestyles=[:solid, :dash, :dot, :dashdot, :dashdotdot, Linestyle([0.5, 1.0, 1.5, 2.5])],
    markers=['●', '■', '▲', '▼', '◆', '★'],
    single_error=false,
    codelabels=[], decoderlabels=[], setuplabels=[],
)
    minlim = minimum(phys_errors)
    #minlim = min(minimum(phys_errors),minimum(skipzeronan(results)))
    maxlim = min(1, max(maximum(Iterators.flatten((phys_errors,skipzeronan(results))))))

    fresults = copy(results)
    fresults[results.==0] .= NaN

    f = Figure(size=(1000,400))
    a = Axis(f[1:7,1:3],
        xscale=log10, yscale=log10,
        limits=(minlim,maxlim,minlim,maxlim),
        aspect=DataAspect(),
        xlabel="physical error rate",
        ylabel="logical error rate",
        title=title)

    singlecode = size(results,3) == 1
    plotcolor(iᶜ,iᵈ) = singlecode ? colors[iᵈ] : colors[iᶜ]
    decoderlegendcolor(iᵈ) = singlecode ? colors[iᵈ] : :gray

    b = lines!(a, [minlim,maxlim],[minlim,maxlim], color=:black)
    for (iᶜ,iᵈ,iˢ) in Iterators.product(axes.((fresults,), (3,4,5))...)
        if single_error
            scatter!(a, phys_errors, max.(fresults[:,1,iᶜ,iᵈ,iˢ],fresults[:,2,iᶜ,iᵈ,iˢ]), marker=markers[iˢ], color=plotcolor(iᶜ,iᵈ), linestyle=linestyles[iᵈ])
            lines!(  a, phys_errors, max.(fresults[:,1,iᶜ,iᵈ,iˢ],fresults[:,2,iᶜ,iᵈ,iˢ]), marker=markers[iˢ], color=plotcolor(iᶜ,iᵈ), linestyle=linestyles[iᵈ])
        else
            scatter!(a, phys_errors, fresults[:,1,iᶜ,iᵈ,iˢ], marker=:+, color=plotcolor(iᶜ,iᵈ), linestyle=linestyles[iᵈ])
            scatter!(a, phys_errors, fresults[:,2,iᶜ,iᵈ,iˢ], marker=:x, color=plotcolor(iᶜ,iᵈ), linestyle=linestyles[iᵈ])
            lines!(  a, phys_errors, fresults[:,1,iᶜ,iᵈ,iˢ], marker=:+, color=plotcolor(iᶜ,iᵈ), linestyle=linestyles[iᵈ])
            lines!(  a, phys_errors, fresults[:,2,iᶜ,iᵈ,iˢ], marker=:x, color=plotcolor(iᶜ,iᵈ), linestyle=linestyles[iᵈ])
        end
    end
    ca = []
    for (iᶜ,label) in enumerate(codelabels)
        push!(ca, lines!(a, [NaN], [NaN], color=plotcolor(iᶜ,1), label=label))
    end
    Legend(f[1:2,4],ca,codelabels, "Code", framevisible = false, halign=:left, titlehalign=:left, valign=:top, nbanks=2)
    la = []
    for (iᵈ,label) in enumerate(decoderlabels)
        push!(la, lines!(a, [NaN], [NaN], linestyle=linestyles[iᵈ], color=decoderlegendcolor(iᵈ), label=label))
    end
    Legend(f[3:6,4],la,decoderlabels, "Decoder", framevisible = false, halign=:left, titlehalign=:left, valign=:top, nbanks=1)
    ma = []
    if single_error
        for (iˢ,label) in enumerate(setuplabels)
            push!(ma, scatter!(a, [NaN], [NaN], marker=markers[iˢ], color=:gray, label=label))
        end
        Legend(f[7,4],ma,setuplabels, "Circuit Type", framevisible = false, halign=:left, titlehalign=:left, valign=:top, nbanks=2)
    else
        push!(ma, scatter!(a, [NaN], [NaN], marker=:+, color=:gray, label="X"))
        push!(ma, scatter!(a, [NaN], [NaN], marker=:x, color=:gray, label="Z"))
        Legend(f[7,4],ma,["X", "Z"], "Logical Error", framevisible = false, halign=:left, titlehalign=:left, valign=:top, nbanks=2)
    end
    f
end

function prep_figures(code_metadata)
    for (codetype, metadata) in code_metadata
        codetypename = typenameof(codetype)
        @info "Plotting figures for $(codetypename) ..."
        codes = [codetype(instance_args...) for instance_args in metadata[:family]]
        decoders = metadata[:decoders]
        setups = metadata[:setups]
        errrange = metadata[:errrange]
        e = logrange(errrange...)
        r = dbnarray(codes, decoders, setups, e)

        single_error = length(decoders)>1 || decoders==[TableDecoder]

        # Plotting summary fig
        f = make_decoder_figure(e, r;
            title="$(codetypename)",
            codelabels=instancenameof.(codes),
            decoderlabels=skipredundantfix.(decoders),
            setuplabels=skipredundantfix.(setups),
            single_error
        )
        save("codes/$(codetypename)/totalsummary.png", f)

        # Plotting code instances
        for c in codes
            # Plotting stabilizer
            f = Figure(size=(600,300))
            sf = f[1:2,1]
            _,ax,p = stabilizerplot_axis(sf, parity_checks(c))
            ax.title = "Parity Check Tableau\n(a.k.a. Stabilizer Generators)"
            cm = Makie.cgrad([:lightgray,:black], 2, categorical = true)
            hz, hx, tz, tx = if iscss(c)
                parity_checks_z(c)[end:-1:1,:]', parity_checks_x(c)[end:-1:1,:]', "Z parity checks", "X parity checks"
            else
                h = stab_to_gf2(parity_checks(c))
                h[:,end÷2+1:end][end:-1:1,:]', h[:,1:end÷2][end:-1:1,:]', "Z components", "X components"
            end
            axz = Axis(f[1,2], title=tz)
            hmz = Makie.heatmap!(
                axz,
                collect(hz);
                colorrange = (0, 1),
                colormap=cm
            )
            axx = Axis(f[2,2], title=tx)
            hmx = Makie.heatmap!(
                axx,
                collect(hx);
                colorrange = (0, 1),
                colormap=cm
            )
            linkxaxes!(axx, axz)
            for ax in (axx, axz)
                Makie.hidedecorations!(ax)
                Makie.hidespines!(ax)
                ax.aspect = Makie.DataAspect()
            end
            colsize!(f.layout, 1, Relative(0.6))
            colsize!(f.layout, 2, Aspect(1, 1))
            colgap!(f.layout, 1, Relative(0.15))
            save("codes/$(codetypename)/$(instancenameof(c)).png", f)
            # Plotting circuits
            continue # skip circuit plots
            if nqubits(c) <= 15
                try
                    savecircuit(naive_encoding_circuit(c), "codes/$(codetypename)/$(c)_encoding.png")
                catch
                    @error "$(c) failed to plot `naive_encoding_circuit`"
                end
                try
                    savecircuit(naive_syndrome_circuit(c)[1], "codes/$(codetypename)/$(c)_naive_syndrome.png")
                catch
                    @error "$(c) failed to plot `naive_syndrome_circuit`"
                end
                try
                    savecircuit(vcat(shor_syndrome_circuit(c)[1:2]...), "codes/$(codetypename)/$(c)_naive_syndrome.png")
                catch
                    @error "$(c) failed to plot `shor_syndrome_circuit`"
                end
            end
        end
    end
end

end
