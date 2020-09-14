using Pkg
Pkg.activate("..")

using NitrateNetworkModel


workspace = "../data/LeSueur"
inputs_dir = joinpath(workspace, "inputs")
results_dir = joinpath(workspace, "results")


function main()
    streammodel = StreamModel(
        inputpath("base_params.csv"), 
        inputpath("network_table.csv")
    )
    evaluate!(streammodel)
    save_model_results(streammodel, resultpath("base_results.csv"))
end


inputpath(basename) = joinpath(inputs_dir, "LeSueurNetworkData", basename)
resultpath(basename) = joinpath(results_dir, basename)

main()
