using CSV
using DataFrames
using DelimitedFiles
using Parameters

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

Results structure returned by `evaluate_with_flow_regime`. Contains outlet
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
    flowdf = DataFrame!(CSV.File(flowfile))
    return FlowRegime(
        deepcopy(flowdf[!, columnindex(flowdf, q_gage_col)]),
        deepcopy(flowdf[!, columnindex(flowdf, p_exceed_col)]),
        deepcopy(flowdf[!, columnindex(flowdf, p_mass_col)])
    )
end


"""
    evaluate_with_flow_regime(model::StreamModel, flowregime::FlowRegime)

Runs `stream_model.evaluate!(model, q)` for each q in `flowregime.q_gage.` Outlet
and average concentrations are saved to a `FlowRegimeSimResults` struct and
returned.
"""
function evaluate_with_flow_regime(model::StreamModel, flowregime::FlowRegime)
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
