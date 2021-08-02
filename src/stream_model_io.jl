using DelimitedFiles
using Parameters
using FileIO
using DataFrames
using CSV

"""
    load_from_tables(baseparams_file::String, network_file::String)

Constructs a [`StreamModel`](@ref) based on inputs in two csv files. The files
should be structured as follows:

* baseparams_file: columns "variable" and "value".
* network_file: many more columns.
"""
function load_from_tables(baseparams_file::String, network_file::String)
    basedf = DataFrame!(CSV.File(baseparams_file))
    varcol = columnindex(basedf, :variable)
    valcol = columnindex(basedf, :value)
    value(var) = basedf[findfirst(x->x==var, basedf[!, varcol]), valcol]
    mc = ModelConstants(
        a1 = value("a1"),
        a2 = value("a2"),
        b1 = value("b1"),
        b2 = value("b2"),
        Qbf = value("Qbf"),
        agN = value("agN"),
        agC = value("agC"),
        agCN = value("agCN"),
        g = value("g"),
        n = value("n"),
        Jleach = value("Jleach")
    )

    netdf = DataFrame!(CSV.File(network_file))
    n_links = Int64(value("n_links"))

    routing_depth = netdf.routing_depth
    routing_order = sort!(collect(1:n_links), by=x->(routing_depth[x],n_links-x), rev=true)
    is_hw = netdf.is_hw
    hw_links = [l for l in 1:n_links if is_hw[l] == 1]

    nc = NetworkConstants(
        n_links = n_links,
        outlet_link = value("outlet_link"),
        gage_link = value("gage_link"),
        gage_flow = value("gage_flow"),
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
        fainC = netdf.fainC
    )

    mv = init_model_vars(nc.n_links)

    StreamModel(mc, nc, mv)

end


"""
    init_model(data_dir::String)

Constructs `ModelConstants` and `NetworkConstants` instances.
"""
function load_model_from_matlab_dump(data_dir::String)
    d = load_data_from_dir(data_dir)

    mc = ModelConstants(
        a1 = d["a1"],
        b1 = d["b1"],
        a2 = d["a2"],
        b2 = d["b2"],
        Qbf = d["Qbf"]
    )

    nc = build_network(d)

    return mc, nc

end

"""
    load_data_from_dir(data_dir::String)

Reads all .txt and .csv files from "model_params" folder. Returns a dictionary
with filename (no extension) as key and the data as value.
"""
function load_data_from_dir(data_dir::String)
    # data_dir = "model_params"
    vars = Dict{String, Any}()
    for df in Base.Filesystem.readdir(data_dir)
        base = Base.Filesystem.basename(df)
        vn, ext = Base.Filesystem.splitext(base)
        if ext == ".txt" || ext == ".csv"
            full_path = Base.Filesystem.joinpath(data_dir, df)
            vars[vn] = readdlm(full_path, ',')
            if length(vars[vn]) == 1
                vars[vn] = vars[vn][1]
            end
        end
    end
    return vars
end

"""
    build_network(d::Dict{String, Any}))

Builds a `NetworkConstants` instance from dictionary of model_params
files.
"""
function build_network(d::Dict{String, Any})
    outlet_link = Int64(d["OutletLinkID"])
    n_links = Int64(d["LinkNum"])

    to_node = vec(d["ToNode"])
    to_node[outlet_link] = -1
    to_node = convert(Vector{Int64}, to_node)

    # routing order
    ln = LinkNetwork(to_node)
    routing_order = get_routing_order(ln, outlet_link)
    hw_links = get_headwater_links(ln)

    nc = NetworkConstants(
        n_links = n_links,
        outlet_link = Int64(d["OutletLinkID"]),
        gage_link = Int64(d["GageLinkID"]),
        gage_flow = Float64(d["GageFlow"]),
        feature = convert(Vector{Int64}, vec(d["Feature"])),
        to_node = to_node,
        us_area = vec(d["usarea"]),
        contrib_area = vec(d["Area"]),
        contrib_subwatershed = ones(Int64, n_links),
        contrib_n_load_factor = zeros(n_links),
        routing_order = routing_order,
        hw_links = hw_links,
        slope = vec(d["Slope"]),
        link_len = vec(d["Length"]),
        wetland_area = vec(d["WA"]),
        pEM = vec(d["pEM"]),
        fainN = vec(d["fainN"]),
        fainC = vec(d["fainC"])
    )

    return nc
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
    df[:link] = 1:nc.n_links
    df[:feature] = nc.feature
    df[:q] = mv.q
    df[:Q_in] = mv.Q_in
    df[:Q_out] = mv.Q_out
    df[:B] = mv.B
    df[:H] = mv.H
    df[:U] = mv.U
    df[:Jden] = mv.jden
    df[:cnrat] = mv.cn_rat
    df[:N_conc_ri] = mv.N_conc_ri
    df[:N_conc_us] = mv.N_conc_us
    df[:N_conc_ds] = mv.N_conc_ds
    df[:N_conc_in] = mv.N_conc_in
    df[:C_conc_ri] = mv.C_conc_ri
    df[:C_conc_us] = mv.C_conc_us
    df[:C_conc_ds] = mv.C_conc_ds
    df[:C_conc_in] = mv.C_conc_in
    df[:mass_N_out] = mv.mass_N_out
    df[:mass_C_out] = mv.mass_C_out
    ldr, lef = get_delivery_ratios(model)
    df[:link_DR] = ldr
    df[:link_EF] = lef

    CSV.write(filename, df)
end
