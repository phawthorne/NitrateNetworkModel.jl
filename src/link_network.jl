"""
    LinkNetwork(up, down)

`LinkNetwork` consists of two dictionaries, `up` and `down`, which indicate, respectively,
the links flowing into given link (`up[i]`), and the link it flows into (`down[i]`).
In both cases, the value is an array of link indices. An empty `down` list indicates that `i`
flow out of the network (i.e. `i` is the outlet), and an empty `up` list indicates that `i`
is a headwater.
"""
struct LinkNetwork{T<:Integer}
    up::Dict{T, Array{T, 1}}
    down::Dict{T, Array{T, 1}}
end


"""
    LinkNetwork(connection_list::Array{T, 1} where T<:Integer)

`connection_list` defines downstream connections: `connection_list[i] == j` means that link `i`
flows into link `j`. If `connection_list[i] == -1`, that means `i` is the outlet.

Return a `LinkNetwork`
"""
function LinkNetwork(connection_list::Array{T, 1} where T<:Integer)
    T = typeof(connection_list[1])
    up = Dict{T, Array{T, 1}}()
    down = Dict{T, Array{T, 1}}()

    n_nodes = length(connection_list)
    for n in 1:n_nodes
        up[n] = []
        down[n] = []
    end

    for (up_node, down_node) in enumerate(connection_list)
        if down_node == -1
            continue
        end
        push!(up[down_node], up_node)
        push!(down[up_node], down_node)
    end

    ln = LinkNetwork(up, down)
end

"calculate distance (# links) between each link and outlet"
function calc_routing_depth(ln, root_node)
    depth = Dict{Int64, Int64}()
    for n in keys(ln.down)
        depth[n] = -1
    end

    step = 0
    cur = BitSet([root_node])

    while length(cur) > 0
        next = BitSet([])
        for i in cur
            if depth[i] == -1
                depth[i] = step
                union!(next, ln.up[i])
            end
        end
        cur = next
        step += 1
    end

    return depth
end

"list of link indices sorted by depth"
function get_routing_order(ln, root_node)
    depth = calc_routing_depth(ln, root_node)
    nodes = collect(keys(ln.down))
    sort!(nodes, by=x->depth[x], rev=true)
    return nodes
end

"list of links with no upstream source"
function get_headwater_links(ln)
    hw_links = collect(Iterators.filter(x->length(ln.up[x])==0, keys(ln.up)))
    return hw_links
end
