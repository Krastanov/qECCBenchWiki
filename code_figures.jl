skipzeronan(xs) = (x for x in xs if x!=0 && !isnan(x))

function make_decoder_figure(phys_errors, results;
    title="",
    colors=Makie.wong_colors(),
    linestyles=[:solid, :dash, :dot, :dashdot, :dashdotdot, :dashdotdotdot],
    markers=['●', '■', '▲', '▼', '◆', '★'],
    single_error=false,
    colorlabels=[], linestylelabels=[], markerlabels=[],
)
    minlim = minimum(phys_errors)
    #minlim = min(minimum(phys_errors),minimum(skipzeronan(results)))
    maxlim = min(1, max(maximum(phys_errors),maximum(skipzeronan(results))))

    fresults = copy(results)
    fresults[results.==0] .= NaN

    f = Figure(size=(700,400))
    a = Axis(f[1:3,1:3],
        xscale=log10, yscale=log10,
        limits=(minlim,maxlim,minlim,maxlim),
        aspect=DataAspect(),
        xlabel="physical error rate",
        ylabel="logical error rate",
        title=title)
    b = lines!(a, [minlim,maxlim],[minlim,maxlim], color=:black)
    for (iᶜ,iᵈ,iˢ) in Iterators.product(axes.((fresults,), (3,4,5))...)
        if single_error
            scatter!(a, phys_errors, max.(fresults[:,1,iᶜ,iᵈ,iˢ],fresults[:,2,iᶜ,iᵈ,iˢ]), marker=markers[iˢ], color=colors[iᶜ], linestyle=linestyles[iᵈ])
            lines!(  a, phys_errors, max.(fresults[:,1,iᶜ,iᵈ,iˢ],fresults[:,2,iᶜ,iᵈ,iˢ]), marker=markers[iˢ], color=colors[iᶜ], linestyle=linestyles[iᵈ])
        else
            scatter!(a, phys_errors, fresults[:,1,iᶜ,iᵈ,iˢ], marker=:+, color=colors[iᶜ], linestyle=linestyles[iᵈ])
            scatter!(a, phys_errors, fresults[:,2,iᶜ,iᵈ,iˢ], marker=:x, color=colors[iᶜ], linestyle=linestyles[iᵈ])
            lines!(  a, phys_errors, fresults[:,1,iᶜ,iᵈ,iˢ], marker=:+, color=colors[iᶜ], linestyle=linestyles[iᵈ])
            lines!(  a, phys_errors, fresults[:,2,iᶜ,iᵈ,iˢ], marker=:x, color=colors[iᶜ], linestyle=linestyles[iᵈ])
        end
    end
    ca = []
    for (iᶜ,label) in enumerate(colorlabels)
        push!(ca, lines!(a, [NaN], [NaN], color=colors[iᶜ], label=label))
    end
    Legend(f[1,4],ca,colorlabels, "Code", framevisible = false, halign=:left, titlehalign=:left, valign=:top, nbanks=2)
    la = []
    for (iᵈ,label) in enumerate(linestylelabels)
        push!(la, lines!(a, [NaN], [NaN], linestyle=linestyles[iᵈ], color=:gray, label=label))
    end
    Legend(f[2,4],la,linestylelabels, "Decoder", framevisible = false, halign=:left, titlehalign=:left, valign=:top, nbanks=2)
    ma = []
    if single_error
        for (iˢ,label) in enumerate(markerlabels)
            push!(ma, scatter!(a, [NaN], [NaN], marker=markers[iˢ], color=:gray, label=label))
        end
        Legend(f[3,4],ma,markerlabels, "Circuit Type", framevisible = false, halign=:left, titlehalign=:left, valign=:top, nbanks=2)
    else
        push!(ma, scatter!(a, [NaN], [NaN], marker=:+, color=:gray, label="X"))
        push!(ma, scatter!(a, [NaN], [NaN], marker=:x, color=:gray, label="Z"))
        Legend(f[3,4],ma,["X", "Z"], "Logical Error", framevisible = false, halign=:left, titlehalign=:left, valign=:top, nbanks=2)
    end
    f
end
