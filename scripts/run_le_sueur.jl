using Pkg
Pkg.activate("..")
using NitrateNetworkModel


workspace = "../data/LeSueur"
inputpath(basename) = joinpath(workspace, "inputs", "LeSueurNetworkData", basename)
resultpath(basename) = joinpath(workspace, "results", basename)


function main()
    sm = StreamModel(
        inputpath("base_params.csv"), 
        inputpath("network_table.csv")
    )
    evaluate!(sm)
    save_model_results(sm, resultpath("base_results.csv"))

    flowregime = FlowRegime(inputpath("flow_values.csv"))
    results = evaluate!(sm, flowregime)
    @show weighted_avg_nconc(results)
    @show weighted_outlet_nconc(results)

end


main()
