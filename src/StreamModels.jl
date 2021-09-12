@with_kw struct ModelConstants
    a1::Float64
    a2::Float64
    b1::Float64
    b2::Float64
    Qbf::Float64
    agN::Float64 = 30.0 # N in q from contributing area
    agC::Float64 = 90.0 # C in q from contributing area
    agCN::Float64 = 4.5 # other C param for C from contributing area
    g::Float64 = 9.81  # gravity m/s^2
    n::Float64 = 0.035 # Manning's roughness
    Jleach::Float64 = 85/3600
end

@with_kw struct NetworkConstants
    n_links::Int64
    outlet_link::Int64
    gage_link::Int64
    gage_flow::Float64
    feature::Vector{Int64}
    to_node::Vector{Int64}
    us_area::Vector{Float64}
    contrib_area::Vector{Float64}
    contrib_subwatershed::Vector{Int64}
    contrib_n_load_factor::Vector{Float64}
    routing_order::Vector{Int64}
    hw_links::Vector{Int64}
    slope::Vector{Float64}
    link_len::Vector{Float64}
    wetland_area::Vector{Float64}
    pEM::Vector{Float64}
    fainN::Vector{Float64}
    fainC::Vector{Float64}
    # optional values
    B_gage::Int64 = -1
    B_us_area::Float64 = -1.0
end

@with_kw struct ModelVariables
    q::Vector{Float64}
    Q_in::Vector{Float64}
    Q_out::Vector{Float64}
    B::Vector{Float64}
    U::Vector{Float64}
    H::Vector{Float64}
    N_conc_ri::Vector{Float64}
    N_conc_us::Vector{Float64}
    N_conc_ds::Vector{Float64}
    N_conc_in::Vector{Float64} # combined conc of ri and us
    C_conc_ri::Vector{Float64}
    C_conc_us::Vector{Float64}
    C_conc_ds::Vector{Float64}
    C_conc_in::Vector{Float64}
    mass_N_in::Vector{Float64}
    mass_N_out::Vector{Float64}
    mass_C_in::Vector{Float64}
    mass_C_out::Vector{Float64}
    cn_rat::Vector{Float64}
    jden::Vector{Float64}
end


"""
    StreamModel(
        mc::ModelConstants,
        nc::NetworkConstants,
        mv::ModelVariables
    )

The StreamModel structure is a wrapper around three other structures.
`ModelConstants` holds values of physical and process constants that do not
change during the run. `NetworkConstants` holds the specification of the
links, their characteristics, and nitrate concentrations from the landscape.
It will not change during the run, but is expected to be adapted for each
management scenario. Finally, `ModelVariables` holds the values that are
calculated during the model run. All `NitrateNetworkModel` functions will take the
entire `StreamModel` as an argument, so there is no need to pull out the
component structures. It is also expected that users will use the file-based
constructor [`StreamModel(::String, ::String)`](@ref).
"""
@with_kw struct StreamModel
    mc::ModelConstants
    nc::NetworkConstants
    mv::ModelVariables
end


"""
    reset_model_vars!(model::StreamModel)

Sets all values in all arrays in mv to 0.0. This way we don't have to
allocate a new ModelVariables object to rerun.
"""
function reset_model_vars!(model::StreamModel)
    @unpack mv = model
    mv.q .= 0.0
    mv.Q_in .= 0.0
    mv.Q_out .= 0.0
    mv.B .= 0.0
    mv.U .= 0.0
    mv.H .= 0.0
    mv.N_conc_ri .= 0.0
    mv.N_conc_us .= 0.0
    mv.N_conc_ds .= 0.0
    mv.N_conc_in .= 0.0
    mv.C_conc_ri .= 0.0
    mv.C_conc_us .= 0.0
    mv.C_conc_ds .= 0.0
    mv.C_conc_in .= 0.0
    mv.mass_N_in .= 0.0
    mv.mass_N_out .= 0.0
    mv.mass_C_in .= 0.0
    mv.mass_C_out .= 0.0
    mv.cn_rat .= 0.0
    mv.jden .= 0.0
end

