# Landscape Model

## ScaledPowerFunctionLandscape
This is a mock-up landscape type that models sub-basin specific crop production and nitrate loading trade-offs using power functions. The model equation for n loading is
``N(x_i) = s_i x_i^{p_i} + N_{i0}``, where $x_i$ is the intensity parameter for sub-basin $i$. The model assumes that crop production is linear: ``C(x_i) = y_i * x_i``.

### Using the model
There are only two steps to running this model: creating the model structure, and calling the execute function with a specified agricultural intensity value.

After executing the model with `evaluate!(l, x)`, the results are available in:
* `l.crops`
* `l.nitrate_load`

### Function documentation
```@docs
WatershedSim.ScaledPowerFunctionLandscape
WatershedSim.evaluate!(::ScaledPowerFunctionLandscape, ::Vector{Float64})
```
