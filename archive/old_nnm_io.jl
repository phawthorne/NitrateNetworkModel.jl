
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
