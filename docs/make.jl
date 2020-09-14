using Documenter, WatershedSim
push!(LOAD_PATH, "../src/")
makedocs(
    format = Documenter.HTML(prettyurls = false),
    modules = [WatershedSim],
    sitename = "WatershedSim.jl",
    pages = [
        "Home" => "index.md",
        "Models" => ["landscape.md",
                     "stream_model.md",
                     "flow_regime.md"]
    ]
)
