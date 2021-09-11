
"""
    evaluate!(model::StreamModel; qgage::Float64, contrib_n_load_reduction::Union{nothing,Array{Float64,1}})

Main model function. Assumes that `model.nc` has already been updated to
reflect the desired management scenario, e.g. updates to
`model.nc.contrib_n_load_factor` or `model.nc.feature` and
`model.nc.wetland_area`.

If a value for qgage is provided, the model will be run using that value as
the flow measured at the link `model.nc.gage_link`, which is used to assign
flow values to all other links. Otherwise, the model will be run using
`model.nc.gage_flow`.

#TODO: the reason I'm doing it this way is because the nc struct is currently
immutable. I could switch it to mutable, but I've been avoiding that due to
potential performance regressions. I should test that, since this is introduces
a funny asymmetry in how different model parameters are handled. 
"""
function evaluate!(model::StreamModel; qgage::Float64=NaN, contrib_n_load_reduction=nothing)
    reset_model_vars!(model)
    if isnan(qgage)
        assign_qQ!(model, model.nc.gage_flow)
    else
        assign_qQ!(model, qgage)
    end
    assign_B!(model)
    determine_U_H_wetland_hydraulics!(model)
    compute_N_C_conc!(model; contrib_n_load_reduction=contrib_n_load_reduction)
end


"""
    init_model_vars(n_links::Int64)

Returns a new `ModelVariables` instance with zero-initialized vectors.
"""
function init_model_vars(n_links::Int64)
    mv = ModelVariables(
        q = zeros(Float64, n_links),            # flow from contrib area
        Q_in = zeros(Float64, n_links),         # channel flow from upstream
        Q_out = zeros(Float64, n_links),        # channel flow to downstream
        B = zeros(Float64, n_links),            # channel width
        U = zeros(Float64, n_links),
        H = zeros(Float64, n_links),
        N_conc_ri = zeros(Float64, n_links),    # [N] in q from land inputs
        N_conc_us = zeros(Float64, n_links),    # [N] in Q_in from upstream
        N_conc_ds = zeros(Float64, n_links),    # [N] in Q_out
        N_conc_in = zeros(Float64, n_links),
        C_conc_ri = zeros(Float64, n_links),    # same as N
        C_conc_us = zeros(Float64, n_links),
        C_conc_ds = zeros(Float64, n_links),
        C_conc_in = zeros(Float64, n_links),
        mass_N_in = zeros(Float64, n_links),
        mass_N_out = zeros(Float64, n_links),
        mass_C_in = zeros(Float64, n_links),
        mass_C_out = zeros(Float64, n_links),
        cn_rat = zeros(Float64, n_links),
        jden = zeros(Float64, n_links)          # denitrification rate
    )
    return mv
end


"""
    assign_qQ!(model::StreamModel, q_gage::Float64)

Routes water
"""
function assign_qQ!(model::StreamModel, q_gage::Float64)
    @unpack q, Q_in, Q_out = model.mv
    @unpack us_area, contrib_area, routing_order, to_node,
            gage_link, outlet_link = model.nc

    contrib_q_per_area = q_gage / us_area[gage_link]

    for l in routing_order[1:end-1]
        q[l] = contrib_q_per_area * contrib_area[l]
        Q_out[l] = q[l] + Q_in[l]
        Q_in[to_node[l]] += Q_out[l]
    end
    q[outlet_link] = contrib_q_per_area * contrib_area[outlet_link]
    Q_out[outlet_link] = q[outlet_link] + Q_in[outlet_link]
end

"""
    assign_B!(model::StreamModel)

Calculates average channel width (B)
"""
function assign_B!(model::StreamModel)
    @unpack Qbf, a1, a2, b1, b2 = model.mc
    @unpack gage_link, us_area = model.nc
    @unpack B, Q_out = model.mv

    if Q_out[gage_link] < Qbf
        B_ref = a1 * Q_out[gage_link] ^ b1
    else
        B_ref = a2 * Q_out[gage_link] ^ b2
    end

    tmp = (B_ref/sqrt(us_area[gage_link])) * sqrt.(us_area)

    for i in 1:length(B)
        @inbounds B[i] = tmp[i]
    end
end

"""
    determine_U_H_wetland_hydraulics!(model::StreamModel)

Calculates U and H, and updates B for wetlands.
#TODO: move the B updating to the function for B?
    the wrong version of B is used to calculate U and H, but then these
    are updated - could skip the update?
"""
function determine_U_H_wetland_hydraulics!(model::StreamModel)
    @unpack n, g = model.mc
    @unpack n_links, feature, link_len, slope, wetland_area = model.nc
    @unpack Q_in, Q_out, B, H, U = model.mv

    tmp_U = zeros(n_links)
    tmp_H = zeros(n_links)
    # TODO: is there a way to use @. and not have to preallocate?
    @. tmp_U = (1/n * (Q_out/B)^(2/3) * sqrt(slope)) ^ (3/5)
    @. tmp_H = Q_out / tmp_U / B
    wetl_vol = zeros(n_links)

    for i in 1:n_links
        @inbounds U[i] = tmp_U[i]
        @inbounds H[i] = tmp_H[i]

        if feature[i] == 1
            continue
        end

        if feature[i] == 2
            wetl_vol[i] = 0.0032 * wetland_area[i] ^ 1.47
        elseif feature[i] == 3
            wetl_vol[i] = 2.1 * wetland_area[i]
        else
            wetl_vol[i] = 0
        end

        link_len[i] = sqrt(wetland_area[i])
        B[i] = sqrt(wetland_area[i])
        H[i] = wetl_vol[i] / wetland_area[i]
        U[i] = Q_out[i] / B[i] / H[i]
    end
end

"""
    compute_N_C_conc!(model::StreamModel)

Routes N and C, computes denitrification.
"""
function compute_N_C_conc!(model::StreamModel; contrib_n_load_reduction=nothing)
    @unpack agN, agC, agCN, Jleach = model.mc
    @unpack q, Q_in, Q_out, B, N_conc_ri, N_conc_us, N_conc_ds, N_conc_in,
        C_conc_ri, C_conc_ds, C_conc_us, C_conc_in, cn_rat, jden,
        mass_N_in, mass_N_out, mass_C_in, mass_C_out = model.mv
    @unpack link_len, routing_order, to_node, outlet_link,
        fainN, fainC, wetland_area, pEM, contrib_n_load_factor = model.nc


    if contrib_n_load_reduction === nothing
        contrib_n_load = contrib_n_load_factor
    else
        contrib_n_load = contrib_n_load_reduction .* contrib_n_load_factor
    end
    
    for l in routing_order
        # bookkeeping
        N_conc_us[l] = mass_N_in[l] / Q_in[l]
        C_conc_us[l] = mass_C_in[l] / Q_in[l]

        # add input from contributing areas
        N_conc_ri[l] = agN * fainN[l] * contrib_n_load[l]
        C_conc_ri[l] = agC * fainC[l] + agCN * fainN[l]

        # After adding local, we have the final incoming mass. Everything
        # from upstream has already been accounted for because of routing_order
        # guarantee.
        mass_N_in[l] += N_conc_ri[l] * q[l]
        mass_C_in[l] += (C_conc_ri[l] * q[l]) + (Jleach * wetland_area[l] * pEM[l] * 1.0e-5)

        N_conc_in[l] = mass_N_in[l] / (Q_in[l] + q[l])
        C_conc_in[l] = mass_C_in[l] / (Q_in[l] + q[l])

        # calculate denitrification rate
        if mass_N_in[l] == 0.0
            jden[l] = 0
        else
            cn_rat[l] = mass_C_in[l] / mass_N_in[l]
            if cn_rat[l] >= 1
                jden[l] = (11.5*sqrt(N_conc_in[l]))/3600
            else
                jden[l] = (3.5*C_conc_in[l])/3600
            end
        end

        mass_C_out[l] = max(0, mass_C_in[l] - jden[l] * B[l] * link_len[l] * 1.0e-3)
        mass_N_out[l] = max(0, mass_N_in[l] - jden[l] * B[l] * link_len[l] * 1.0e-3)

        # bookkeeping: downstream concentration
        N_conc_ds[l] = mass_N_out[l] / Q_out[l]
        C_conc_ds[l] = mass_C_out[l] / Q_out[l]

        # route N and C mass downstream
        if l != outlet_link
            mass_N_in[to_node[l]] += mass_N_out[l]
            mass_C_in[to_node[l]] += mass_C_out[l]
        end
    end
end

#= Solution querying functions =#
"""
    get_outlet_nconc(model::StreamModel)::Float64

Gets nitrate concentration leaving outlet link
"""
function get_outlet_nconc(model::StreamModel)
    @unpack mv, mc, nc = model
    return mv.N_conc_ds[nc.outlet_link]
end

"""
    get_avg_nconc(model::StreamModel)::Float64

Gets link length-weighted nitrate concentration
"""
function get_average_nconc(model::StreamModel)
    @unpack mv, mc, nc = model
    tot_len_w_nconc = sum(mv.N_conc_ds .* nc.link_len)
    # TODO: this could take the average of up and downstream
    tot_len = sum(nc.link_len)
    return tot_len_w_nconc / tot_len
end

get_avg_nconc(model::StreamModel) = get_average_nconc(model::StreamModel)

"""
    get_delivery_ratios(model::StreamModel)::Tuple{Vector{Float64}, Vector{Float64}}

Returns vectors with net delivery ratio and escape fraction for each link.
"""
function get_delivery_ratios(model::StreamModel)
    @unpack q, Q_in, N_conc_ri, N_conc_us, N_conc_ds, N_conc_in = model.mv
    @unpack to_node, outlet_link, n_links = model.nc

    # we set EF to 1.0 for links that aren't measuring any input
    link_escape_frac = [in == 0.0 ? 1.0 : out/in for
                        (in, out) in zip(N_conc_in, N_conc_ds)]

    link_delivery_ratio = zeros(n_links)
    # TODO: this could be done in a more efficient way traversing upstream instead
    for l = 1:n_links
        ll = l
        link_delivery_ratio[l] = link_escape_frac[l] # TODO: this or 1.0?
        while ll != outlet_link
            ll = to_node[ll]
            link_delivery_ratio[l] *= link_escape_frac[ll]
        end
    end
    return link_delivery_ratio, link_escape_frac
end


"Compare two streammodels' network constants - just prints differences for now"
function compare_network_constants(sm1::StreamModel, sm2::StreamModel)
    nc1 = sm1.nc
    nc2 = sm2.nc

    if nc1.n_links != nc2.n_links
        println("n_links")
    end

    if nc1.outlet_link != nc2.outlet_link
        println("outlet_link")
    end

    if nc1.gage_link != nc2.gage_link
        println("gage_link")
    end

    if nc1.gage_flow != nc2.gage_flow
        println("gage_flow")
    end

    feature_diffs = findall(nc1.feature .!= nc2.feature)
    if length(feature_diffs) > 0
        @show feature_diffs
    end
    us_area_diffs = findall(nc1.us_area .!= nc2.us_area)
    if length(us_area_diffs) > 0
        @show us_area_diffs
    end
    contrib_area_diffs = findall(nc1.contrib_area .!= nc2.contrib_area)
    if length(contrib_area_diffs) > 0
        @show contrib_area_diffs
    end
    contrib_n_load_factor_diffs = findall(nc1.contrib_n_load_factor .!= nc2.contrib_n_load_factor)
    if length(contrib_n_load_factor_diffs) > 0
        @show contrib_n_load_factor_diffs
    end
    link_len_diffs = findall(nc1.link_len .!= nc2.link_len)
    if length(link_len_diffs) > 0
        @show link_len_diffs
    end
    wetland_area_diffs = findall(nc1.wetland_area .!= nc2.wetland_area)
    if length(wetland_area_diffs) > 0
        @show wetland_area_diffs
    end
    pEM_diffs = findall(nc1.pEM .!= nc2.pEM)
    if length(pEM_diffs) > 0
        @show pEM_diffs
    end
    fainN_diffs = findall(nc1.fainN .!= nc2.fainN)
    if length(fainN_diffs) > 0
        @show fainN_diffs
    end
    fainC_diffs = findall(nc1.fainC .!= nc2.fainC)
    if length(fainC_diffs) > 0
        @show fainC_diffs
    end
    



end