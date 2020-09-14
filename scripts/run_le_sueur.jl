import Base.Filesystem.joinpath
import Base.Filesystem.isdir
import Base.Filesystem.mkpath


workspace = "../data/LeSueur"
inputs_dir = joinpath(workspace, "inputs")
results_dir = joinpath(workspace, "results")


function main()
    set_up_workspace()
    download_data()
end


"Create data/LeSueur containing inputs and results folders"
function set_up_workspace()
    for path in [workspace, inputs_dir, results_dir]
        if !isdir(path)
            mkpath(path)
        end
    end
end

"Download model data"
function download_data()
    url = "https://de.cyverse.org/dl/d/B8A1E227-19BC-4994-8762-ABE4FCBA348A/LeSueurNetworkData.zip"
    target_file = joinpath(inputs_dir, "LeSueurNetworkData.zip")
    Base.download(url, target_file)
    Base.run(`unzip $target_file "LeSueurNetworkData*" -d $inputs_dir`)
    Base.Filesystem.rm(target_file)
end


main()
