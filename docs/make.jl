using Documenter, NitrateNetworkModel

push!(LOAD_PATH, "../src/")

makedocs(
    format = Documenter.HTML(prettyurls = false),
    modules = [NitrateNetworkModel],
    sitename = "NitrateNetworkModel.jl",
    pages = [
        "Home" => "index.md",
        "Models" => ["nnm.md",
                     "flow_regime.md"]
    ]
)
