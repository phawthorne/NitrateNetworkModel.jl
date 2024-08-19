"""
    SubNetworkDef(
        network_file::String,
        baseparams_file::String,
        root_node::Int,
        subnetwork_file::String,
        subnetwork_params_file::String,
        flow_regime_file::Union{Nothing, String},
        subnetwork_flow_regime_file::Union{Nothing, String}
    )

Parametric struct to pass to `generate_subnetwork`. 

The final two arguments, `flow_regime_file` and `subnetwork_flow_regime_file` can be `nothing` 
or point to an existing flow regime file and the location to create the corresponding
flow regime file for the subnetwork. If either one is `nothing`, then this step will be
skipped, or if both are provided, the subnetwork flow regime file will be calculated and
created.

All other arguments are required.
"""
@with_kw struct SubNetworkDef
    network_file::String
    baseparams_file::String
    root_node::Int
    subnetwork_file::String
    subnetwork_params_file::String
    flow_regime_file::Union{Nothing, String}
    subnetwork_flow_regime_file::Union{Nothing, String}
end


"""
    generate_subnetwork(subnetworkdef::SubNetworkDef)

Generate files for running the NitrateNetworkModel on a subnetwork of a larger
network model. 
"""
function generate_subnetwork(subnetworkdef::SubNetworkDef)
    generate_subnetwork_file(subnetworkdef)
    generate_subnetwork_modelparams_file(subnetworkdef)
    if (subnetworkdef.subnetwork_flow_regime_file !== nothing &&
        subnetworkdef.flow_regime_file !== nothing)
        generate_subnetwork_flow_regime_file(subnetworkdef)
    end
end


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

function generate_subnetwork_file(subnetworkdef::SubNetworkDef)
    generate_subnetwork_file(
        subnetworkdef.network_file,
        subnetworkdef.root_node,
        subnetworkdef.subnetwork_file
    )
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

function generate_subnetwork_modelparams_file(subnetworkdef::SubNetworkDef)
    generate_subnetwork_modelparams_file(
        subnetworkdef.network_file,
        subnetworkdef.baseparams_file,
        subnetworkdef.root_node,
        subnetworkdef.subnetwork_file,
        subnetworkdef.subnetwork_params_file
    )
end


"""
    generate_subnetwork_flow_regime()

Create `subnetwork_flow_regime_file` by running the base model for each Q value in 
`flow_regime_file`, and pulling out `Q_out[root_node]`.
"""
function generate_subnetwork_flow_regime_file(
    network_file::String, 
    baseparams_file::String,
    flow_regime_file::String, 
    root_node::Int, 
    subnetwork_flow_regime_file::String)

    basemodel = StreamModel(baseparams_file, network_file)
    baseflows = FlowRegime(flow_regime_file)

    nqvals = length(baseflows.q_gage)
    submodel_qvals = zeros(nqvals)
    for i in 1:nqvals
        evaluate!(basemodel, qgage=baseflows.q_gage[i])
        submodel_qvals[i] = basemodel.mv.Q_out[root_node]
    end

    submodel_flow_regime = FlowRegime(
        submodel_qvals, baseflows.p_exceed, baseflows.p_mass
    )

    write_flow_regime(subnetwork_flow_regime_file, submodel_flow_regime)
end

function generate_subnetwork_flow_regime_file(subnetworkdef::SubNetworkDef)
    generate_subnetwork_flow_regime_file(
        subnetworkdef.network_file,
        subnetworkdef.baseparams_file,
        subnetworkdef.flow_regime_file,
        subnetworkdef.root_node,
        subnetworkdef.subnetwork_flow_regime_file
    )
end



"""
    StreamModel(subnetworkdef::SubNetworkDef; make_if_missing::Bool=true)

Construct a `StreamModel` from a `SubNetworkDef`. If the subnetwork hasn't been
created yet and `make_if_missing` is `true` (default), this will also generate the
subnetwork files. If `make_if_missing` is set to `false`, throws an error if the
subnetwork doesn't exist.
"""
function StreamModel(subnetworkdef::SubNetworkDef; make_if_missing::Bool=true)
    if (~(Base.Filesystem.isfile(subnetworkdef.subnetwork_params_file) &&
          Base.Filesystem.isfile(subnetworkdef.subnetwork_file)))
        if make_if_missing
            generate_subnetwork(subnetworkdef)
        else
            error("Subnetwork not found and make_if_missing is False")
        end
    end
    
    return StreamModel(subnetworkdef.subnetwork_params_file,
                       subnetworkdef.subnetwork_file)
end

"""
    FlowRegime(subnetworkdef::SubNetworkDef; make_if_missing::Bool=true)

Construct a `FlowRegime` from a `SubNetworkDef`. If the subnetwork and flow regime 
haven't been created yet and `make_if_missing` is `true` (default), this will also 
generate the required files. If `make_if_missing` is set to `false`, throws an error 
if the subnetwork files don't exist.
"""
function FlowRegime(subnetworkdef::SubNetworkDef; make_if_missing::Bool=true)
    if (~(Base.Filesystem.isfile(subnetworkdef.subnetwork_params_file) &&
          Base.Filesystem.isfile(subnetworkdef.subnetwork_file) &&
          Base.Filesystem.isfile(subnetworkdef.subnetwork_flow_regime_file)))
        if make_if_missing
            generate_subnetwork(subnetworkdef)
            generate_subnetwork_flow_regime_file(subnetworkdef)
        else
            error("Subnetwork and/or subnetwork flow regime not found and make_if_missing is False")
        end
    end

    return FlowRegime(subnetworkdef.subnetwork_flow_regime_file)
end