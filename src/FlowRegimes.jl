"""
    FlowRegime(
        q_gage::Vector{Float64},
        p_exceed::Vector{Float64},
        p_mass::Vector{Float64}
    )

Input structure for evaluating StreamModel against multiple flow values.
Single-link flow regime - values measured at gaged link.
"""
@with_kw struct FlowRegime
    q_gage::Vector{Float64}
    p_exceed::Vector{Float64}
    p_mass::Vector{Float64}
end


"""
    FlowRegimeSimResults(
        n_conc_outlet::Vector{Float64},
        n_conc_avg::Vector{Float64},
        p_mass::Vector{Float64}
    )

Results structure returned by `evaluate!`. Contains outlet
and average nitrate concentration values for each of the flow values in
`flowregime.q_gage`. `flowregime.p_mass` is copied over for convenience.
"""
@with_kw struct FlowRegimeSimResults
    n_conc_outlet::Vector{Float64}
    n_conc_avg::Vector{Float64}
    p_mass::Vector{Float64}
end


"""
    FlowRegime(flowfile::String; q_gage_col=:Q, p_exceed_col=:cp, p_mass_col=:cf)

Constructor function to build FlowRegime from csv file.
"""
function FlowRegime(flowfile::String; q_gage_col=:Q, p_exceed_col=:cp, p_mass_col=:cf)
    flowdf = DataFrame(CSV.File(flowfile))
    return FlowRegime(
        deepcopy(flowdf[!, columnindex(flowdf, q_gage_col)]),
        deepcopy(flowdf[!, columnindex(flowdf, p_exceed_col)]),
        deepcopy(flowdf[!, columnindex(flowdf, p_mass_col)])
    )
end


"""
    evaluate!(model::StreamModel, flowregime::FlowRegime)

Runs `stream_model.evaluate!(model, q)` for each q in `flowregime.q_gage.` Outlet
and average concentrations are saved to a `FlowRegimeSimResults` struct and
returned.
"""
function evaluate!(model::StreamModel, flowregime::FlowRegime)
    nqvals = length(flowregime.q_gage)
    results = FlowRegimeSimResults(
        fill(0.0, nqvals),
        fill(0.0, nqvals),
        deepcopy(flowregime.p_mass)
    )

    for i in 1:nqvals
        evaluate!(model, qgage=flowregime.q_gage[i])
        results.n_conc_outlet[i] = get_outlet_nconc(model)
        results.n_conc_avg[i] = get_avg_nconc(model)
    end

    return results
end


"""
    weighted_outlet_nconc(results::FlowRegimeSimResults)

Convenience function for getting probability exceedance weighted outlet concentration.
"""
function weighted_outlet_nconc(results::FlowRegimeSimResults)
    return sum(results.n_conc_outlet .* results.p_mass)
end


"""
    weighted_avg_nconc(results::FlowRegimeSimResults)

Convenience function for getting probability exceedance weighted average concentration.
"""
function weighted_avg_nconc(results::FlowRegimeSimResults)
    return sum(results.n_conc_avg .* results.p_mass)
end


"""
    full_eval_flow_regime(model::StreamModel, flowregime::FlowRegime)

Run `stream_model.evaluate!(model, q)` for each q in `flowregime.q_gage`.
Save averaged link values for values in `ModelVariables`.
"""
function full_eval_flow_regime(model::StreamModel, flowregime::FlowRegime)
    results = init_model_vars(model.nc.n_links)

    for (q, p) in zip(flowregime.q_gage, flowregime.p_mass)
        evaluate!(model, qgage=q)
        results = results + (p * model.mv)
    end
    
    return results
end

"Write `flowregime` to CSV file `output_file`"
function write_flow_regime(output_file, flowregime::FlowRegime;
               q_gage_col="Q", p_exceed_col="cp", p_mass_col="cf")
    nflows = length(flowregime.q_gage)

    open(output_file, "w") do io
        write(io, "$(q_gage_col),$(p_exceed_col),$(p_mass_col)\n")
        for i=1:nflows
            q = flowregime.q_gage[i]
            cp = flowregime.p_exceed[i]
            cf = flowregime.p_mass[i]
            write(io, "$(q),$(cp),$(cf)\n")
        end
    end
end