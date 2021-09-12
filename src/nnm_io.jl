"""
    StreamModel(baseparams_file::String, network_file::String)

Constructs a [`StreamModel`](@ref) based on inputs in two csv files. The files
should be structured as follows:

* baseparams_file: columns "variable" and "value".
* network_file: many more columns.
"""
function StreamModel(baseparams_file::String, network_file::String)
    baseparams = read_baseparams(baseparams_file)
    mc = ModelConstants(
        a1 = baseparams["a1"],
        a2 = baseparams["a2"],
        b1 = baseparams["b1"],
        b2 = baseparams["b2"],
        Qbf = baseparams["Qbf"],
        agN = baseparams["agN"],
        agC = baseparams["agC"],
        agCN = baseparams["agCN"],
        g = baseparams["g"],
        n = baseparams["n"],
        Jleach = baseparams["Jleach"]
    )

    netdf = DataFrame(CSV.File(network_file))
    n_links = Int64(baseparams["n_links"])

    routing_depth = netdf.routing_depth
    routing_order = sort!(collect(1:n_links), by=x->(routing_depth[x],n_links-x), rev=true)
    is_hw = netdf.is_hw
    hw_links = [l for l in 1:n_links if is_hw[l] == 1]

    nc = NetworkConstants(
        n_links = n_links,
        outlet_link = baseparams["outlet_link"],
        gage_link = baseparams["gage_link"],
        gage_flow = baseparams["gage_flow"],
        feature = netdf.feature,
        to_node = netdf.to_node,
        us_area = netdf.us_area,
        contrib_area = netdf.contrib_area,
        contrib_subwatershed = netdf.swat_sub,
        contrib_n_load_factor = ones(n_links),
        routing_order = routing_order,
        hw_links = hw_links,
        slope = netdf.slope,
        link_len = netdf.link_len,
        wetland_area = netdf.wetland_area,
        pEM = netdf.pEM,
        fainN = netdf.fainN,
        fainC = netdf.fainC,
        # optional values
        B_gage = "B_gage" in keys(baseparams) ? baseparams["B_gage"] : -1,
        B_us_area = "B_us_area" in keys(baseparams) ? baseparams["B_us_area"] : -1.0
    )

    mv = init_model_vars(nc.n_links)

    StreamModel(mc, nc, mv)

end


"Load either a YAML or CSV (legacy) baseparams file to a Dict"
function read_baseparams(baseparams_file::String)
    fileext = Base.Filesystem.splitext(baseparams_file)[2]
    if fileext == ".yml" || fileext == ".yaml"
        return YAML.load_file(baseparams_file)
    elseif fileext == ".csv"
        baseparams = Dict{Any, Any}()
        lines = readlines(open(baseparams_file))
        for l in lines[2:end]  #TODO: this is skipping the header but should be smarter
            key, val = split(l, ',')
            baseparams[key] = parse(Float64, val)
        end
        return baseparams
    else
        return nothing
    end
end


function save_constants(mc::ModelConstants, nc::NetworkConstants, filename::String)
    save(filename, "mc", mc, "nc", nc)
end

function load_constants(filename::String)
    d = load(filename)
    return d["mc"], d["nc"]
end


"""
    save_model_results(model::StreamModel, filename::String)

Writes model results to csv file
"""
function save_model_results(model::StreamModel, filename::String)
    @unpack mv, mc, nc = model

    df = DataFrame()
    df[!, :link] = 1:nc.n_links
    df[!, :feature] = nc.feature
    df[!, :q] = mv.q
    df[!, :Q_in] = mv.Q_in
    df[!, :Q_out] = mv.Q_out
    df[!, :B] = mv.B
    df[!, :H] = mv.H
    df[!, :U] = mv.U
    df[!, :Jden] = mv.jden
    df[!, :cnrat] = mv.cn_rat
    df[!, :N_conc_ri] = mv.N_conc_ri
    df[!, :N_conc_us] = mv.N_conc_us
    df[!, :N_conc_ds] = mv.N_conc_ds
    df[!, :N_conc_in] = mv.N_conc_in
    df[!, :C_conc_ri] = mv.C_conc_ri
    df[!, :C_conc_us] = mv.C_conc_us
    df[!, :C_conc_ds] = mv.C_conc_ds
    df[!, :C_conc_in] = mv.C_conc_in
    df[!, :mass_N_out] = mv.mass_N_out
    df[!, :mass_C_out] = mv.mass_C_out
    ldr, lef = get_delivery_ratios(model)
    df[!, :link_DR] = ldr
    df[!, :link_EF] = lef

    CSV.write(filename, df)
end


"""
    save_model_variables(mv::ModelVariables, filename::String)

Write a ModelVariables struct to a table
"""
function save_model_variables(mv::ModelVariables, filename::String)
    df = DataFrame()
    df[!, :link] = 1:length(mv.q)
    df[!, :q] = mv.q
    df[!, :Q_in] = mv.Q_in
    df[!, :Q_out] = mv.Q_out
    df[!, :B] = mv.B
    df[!, :H] = mv.H
    df[!, :U] = mv.U
    df[!, :Jden] = mv.jden
    df[!, :cnrat] = mv.cn_rat
    df[!, :N_conc_ri] = mv.N_conc_ri
    df[!, :N_conc_us] = mv.N_conc_us
    df[!, :N_conc_ds] = mv.N_conc_ds
    df[!, :N_conc_in] = mv.N_conc_in
    df[!, :C_conc_ri] = mv.C_conc_ri
    df[!, :C_conc_us] = mv.C_conc_us
    df[!, :C_conc_ds] = mv.C_conc_ds
    df[!, :C_conc_in] = mv.C_conc_in
    df[!, :mass_N_out] = mv.mass_N_out
    df[!, :mass_C_out] = mv.mass_C_out

    CSV.write(filename, df)
end