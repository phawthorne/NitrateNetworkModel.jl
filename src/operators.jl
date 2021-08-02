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

