using Pkg
Pkg.activate("..")

using Documenter, NitrateNetworkModel

push!(LOAD_PATH, "../src/")

makedocs(
    format = Documenter.HTML(prettyurls = false),
    modules = [NitrateNetworkModel],
    sitename = "NitrateNetworkModel.jl",
    pages = [
        "Home" => "index.md",
        "Basic Model" => "nnm.md",
        "Flow Regime" => "flow_regime.md",
        "Subnetworks" => "subnetwork.md",
        "LinkNetwork" => "link_network.md",
    ],
    warnonly = true
)

deploydocs(
    repo = "github.com/phawthorne/NitrateNetworkModel.jl.git",
    devbranch = "main"
)
