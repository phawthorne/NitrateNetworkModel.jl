using CSV
using DataFrames
using DelimitedFiles
using Parameters

module NitrateNetworkModel

include("link_network.jl")
export LinkNetwork, calc_routing_depth, get_routing_order,
       get_headwater_links

include("stream_model.jl")
export ModelConstants, NetworkConstants, ModelVariables,
       StreamModel, evaluate!,
       get_outlet_nconc, get_avg_nconc, get_delivery_ratios,
       reset_model_vars!, assign_qQ!, assign_B!,
       determine_U_H_wetland_hydraulics!, compute_N_C_conc!,
       compare_network_constants

include("stream_model_io.jl")
export load_data_from_dir, load_model_from_matlab_dump,
       save_constants, load_constants, save_model_results,
       build_network, load_from_tables

include("flow_regime.jl")
export FlowRegime, FlowRegimeSimResults, evaluate!,
       weighted_avg_nconc, weighted_outlet_nconc

end # module
