using Parameters
# TODO: make the landscape and stream interfaces more similar


@with_kw struct WatershedSimModel
    landscape::ScaledPowerFunctionLandscape
    stream::StreamModel
end

@with_kw struct WatershedSimActions
    landscape::Vector{Float64}  # management intensity
    stream::Vector{Float64}     # wetland actions
end

function evaluate!(m::WatershedSimModel, a::WatershedSimActions)
    @unpack landscape, stream = WatershedSimModel
    evaluate!(m.landscape, a.landscape)
    loading_fraction = landscape.nitrate_load / (landscape.scale + landscape.intercept)
    for l in 1:stream.nc.n_links
        stream.nc.contrib_n_load_factor[l] = loading_fraction[stream.nc.contrib_subwatershed]
    end
    evaluate!(stream)
end
