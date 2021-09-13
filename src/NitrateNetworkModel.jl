module NitrateNetworkModel

using CSV
using DataFrames
using DelimitedFiles
using YAML
using FileIO
using Parameters

include("link_network.jl")
export LinkNetwork, calc_routing_depth, get_routing_order,
       get_headwater_links

include("StreamModels.jl")
export StreamModel, ModelConstants, NetworkConstants, ModelVariables

include("nnm.jl")
include("nnm_io.jl")
export ModelConstants,
       NetworkConstants,
       ModelVariables,
       StreamModel,
       evaluate!,
       get_outlet_nconc,
       get_avg_nconc,
       get_average_nconc,
       get_delivery_ratios,
       reset_model_vars!

export load_data_from_dir,
       load_model_from_matlab_dump,
       save_constants,
       load_constants,
       save_model_results,
       build_network,
       save_model_variables

include("operators.jl")

include("FlowRegimes.jl")
export FlowRegime,
       FlowRegimeSimResults,
       evaluate!,
       weighted_avg_nconc,
       weighted_outlet_nconc,
       full_eval_flow_regime,
       write_flow_regime

include("sample_data.jl")
export SubNetworkDef,
       generate_subnetwork,
       generate_subnetwork_file,
       generate_subnetwork_modelparams_file,
       generate_subnetwork_flowregime_file
end
