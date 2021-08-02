# Flow Regime

Functions to allow the basic StreamModel to be run across a range of flow values,
and estimate frequency curves for nitrate concentrations based on the frequency
curves for flow.

## Function documentation

```@docs
FlowRegime
FlowRegime(flowfile::String; q_gage_col, p_exceed_col, p_mass_col)
evaluate!(::StreamModel, ::FlowRegime)
FlowRegimeSimResults
weighted_outlet_nconc(::FlowRegimeSimResults)
weighted_avg_nconc(::FlowRegimeSimResults)
```

## Example

```julia
using NitrateNetworkModel
using Plots
using Printf

# required input files
baseparams_file = "../data/baseparams.csv"
network_file = "../data/network_table.csv"
flowfile = "../data/flow_values.csv"

# create the model structs
sm = StreamModel(baseparams_file, network_file)
fr = FlowRegime(flowfile)

# run the model
results = evaluate!(sm, fr)

# create a summary figure
plot(fr.p_exceed, results.n_conc_outlet,
    label=@sprintf "Outlet (overall: %.2f)" weighted_outlet_nconc(results))
plot!(fr.p_exceed, results.n_conc_avg,
    label=@sprintf "Average (overall: %.2f)" weighted_avg_nconc(results))
xaxis!("Probability Exceedance")
yaxis!("Nitrate Concentration")
```
