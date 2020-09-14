# Flow Regime
Functions to allow the basic StreamModel to be run across a range of flow values,
and estimate frequency curves for nitrate concentrations based on the frequency
curves for flow.

## Function documentation
```@docs
FlowRegime
FlowRegime(flowfile::String; q_gage_col, p_exceed_col, p_mass_col)
evaluate_with_flow_regime(::StreamModel, ::FlowRegime)
FlowRegimeSimResults
weighted_outlet_nconc(::FlowRegimeSimResults)
weighted_avg_nconc(::FlowRegimeSimResults)
```

## Example
```@example flowregime
using WatershedSim
using Plots
using Printf

# required input files
baseparams_file = "/Users/hawt0010/Projects/julia-dev/WatershedSim/data/baseparams.csv"
network_file = "/Users/hawt0010/Projects/julia-dev/WatershedSim/data/network_table.csv"
flowfile = "/Users/hawt0010/Projects/julia-dev/WatershedSim/data/flow_values.csv"

# create the model structs
model = StreamModel(baseparams_file, network_file)
flowregime = FlowRegime(flowfile)

# run the model
results = evaluate_with_flow_regime(model, flowregime)

# create a summary figure
plot(flowregime.p_exceed, results.n_conc_outlet,
    label=@sprintf "Outlet (overall: %.2f)" weighted_outlet_nconc(results))
plot!(flowregime.p_exceed, results.n_conc_avg,
    label=@sprintf "Average (overall: %.2f)" weighted_avg_nconc(results))
xaxis!("Probability Exceedance")
yaxis!("Nitrate Concentration")
```
