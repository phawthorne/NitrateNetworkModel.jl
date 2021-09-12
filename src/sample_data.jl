"""
    generate_subnetwork_file(network_file::String, root_node::Int, subnetwork_file::String)

Output a network parameter file to `subnetwork_file` consisting of the `root_node`
and all upstream links. Links will be reindexed, with the old "link_id" renamed to
"original_link_id" for potential cross-referencing.
"""
function generate_subnetwork_file(network_file::String, root_node::Int, subnetwork_file::String)
    netdf = DataFrame(CSV.File(network_file))

    subnetwork_links = find_subnetwork(netdf[!, :to_node], root_node)
    subnetdf = netdf[subnetwork_links, :]
    subnetdf[!, :original_link_id] = subnetdf[!, :link_id]
    subnetdf[!, :link_id] = 1:size(subnetdf, 1)
    subnetdf[!, :original_to_node] = subnetdf[!, :to_node]
    subnetdf[!, :to_node] = reindex_to_node(subnetwork_links, subnetdf)

    CSV.write(subnetwork_file, subnetdf)
end


"Helper function to traverse link network upstream. Return list of upstream links."
function find_subnetwork(dslinks, root)

    function contrib_nodes(nodes)
        # `...` "splats" the resulting vector of vectors so we get a flattened vector of node ids
        upstream = vcat([findall(dslinks .== n) for n in nodes]...)
        
        if length(upstream) > 0
            return vcat(nodes, contrib_nodes(upstream))
        else
            return nodes
        end
    end

    return contrib_nodes([root])

end


"Reassign `:to_node` values to match new `link_id`s"
function reindex_to_node(subnetwork_links, subnetdf)
    to_node = zeros(Int64, size(subnetdf, 1))
    for (i, n) in enumerate(subnetdf[!,:original_to_node])
        ds = findfirst(subnetwork_links .== n)
        if ds === nothing
            to_node[i] = -1
        else
            to_node[i] = ds
        end
    end
    return to_node
end


"""
    generate_subnetwork_modelparams_file()

Create an updated model parameter file. The main things that need
to be updated are: 

- `n_links`
- `outlet_link`
- `gage_link`
- `gage_flow`
- `B_gage`
- `B_us_area`

We set `outlet_link` and `gage_link` to link 1.  In order to calculate `gage_flow`, 
we need to run the original model, and then we have `gage_flow = `model.mv.Q_out[root_node]`,
where `root_node` is the original link index of the subnetwork outlet. 

The values `B_gage` and `B_us_area` get flow and upstream area from the original
gage link. They are used to set channel width within the subnetwork, and need to be
referenced to the original model for consistency of results.

Assumes that the subnetwork network constants file has already been generated

Note that a different function is required to update a flow regime file.
"""
function generate_subnetwork_modelparams_file(
    network_file::String,
    baseparams_file::String,
    root_node::Int,
    subnetwork_file::String,
    subnetwork_params_file::String
)
    streammodel = StreamModel(baseparams_file, network_file)
    evaluate!(streammodel)
    gage_flow = streammodel.mv.Q_out[root_node]

    orig_gage_flow = streammodel.nc.gage_flow
    orig_gage_us_area = streammodel.nc.us_area[streammodel.nc.gage_link]

    baseparams = read_baseparams(baseparams_file)
    subnetdf = DataFrame(CSV.File(subnetwork_file))

    baseparams["n_links"] = size(subnetdf, 1)
    baseparams["outlet_link"] = 1
    baseparams["gage_link"] = 1
    baseparams["gage_flow"] = gage_flow
    baseparams["B_gage"] = orig_gage_flow
    baseparams["B_us_area"] = orig_gage_us_area

    YAML.write_file(subnetwork_params_file, baseparams)
end

