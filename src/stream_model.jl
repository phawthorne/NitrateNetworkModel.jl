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


"""
Arithmentic operators for `ModelVariables`. Introduced to calculate average
results for all model variables when running with a `FlowRegime`. 
"""

"Define + for ModelVariables structs"
function Base.:+(mv1::ModelVariables, mv2::ModelVariables)
    return ModelVariables(
        mv1.q + mv2.q,
        mv1.Q_in + mv2.Q_in,
        mv1.Q_out + mv2.Q_out,
        mv1.B + mv2.B,
        mv1.U + mv2.U,
        mv1.H + mv2.H,
        mv1.N_conc_ri + mv2.N_conc_ri,
        mv1.N_conc_us + mv2.N_conc_us,
        mv1.N_conc_ds + mv2.N_conc_ds,
        mv1.N_conc_in + mv2.N_conc_in,
        mv1.C_conc_ri + mv2.C_conc_ri,
        mv1.C_conc_us + mv2.C_conc_us,
        mv1.C_conc_ds + mv2.C_conc_ds,
        mv1.C_conc_in + mv2.C_conc_in,
        mv1.mass_N_in + mv2.mass_N_in,
        mv1.mass_N_out + mv2.mass_N_out,
        mv1.mass_C_in + mv2.mass_C_in,
        mv1.mass_C_out + mv2.mass_C_out,
        mv1.cn_rat + mv2.cn_rat,
        mv1.jden + mv2.jden,
    )
end

"Define * for constant * ModelVariables"
function Base.:*(g::Number, mv::ModelVariables)
    return ModelVariables(
        g * mv.q,
        g * mv.Q_in,
        g * mv.Q_out,
        g * mv.B,
        g * mv.U,
        g * mv.H,
        g * mv.N_conc_ri,
        g * mv.N_conc_us,
        g * mv.N_conc_ds,
        g * mv.N_conc_in,
        g * mv.C_conc_ri,
        g * mv.C_conc_us,
        g * mv.C_conc_ds,
        g * mv.C_conc_in,
        g * mv.mass_N_in,
        g * mv.mass_N_out,
        g * mv.mass_C_in,
        g * mv.mass_C_out,
        g * mv.cn_rat,
        g * mv.jden
    )
end

function Base.:*(mv::ModelVariables, g::Number)
    return g * mv
end


"Define / for ModelVariables / constant"
function Base.:/(mv::ModelVariables, g::Number)
    return ModelVariables(
        mv.q / g,
        mv.Q_in / g,
        mv.Q_out / g,
        mv.B / g,
        mv.U / g,
        mv.H / g,
        mv.N_conc_ri / g,
        mv.N_conc_us / g,
        mv.N_conc_ds / g,
        mv.N_conc_in / g,
        mv.C_conc_ri / g,
        mv.C_conc_us / g,
        mv.C_conc_ds / g,
        mv.C_conc_in / g,
        mv.mass_N_in / g,
        mv.mass_N_out / g,
        mv.mass_C_in / g,
        mv.mass_C_out / g,
        mv.cn_rat / g,
        mv.jden / g
    )
end

