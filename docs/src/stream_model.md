# Stream Model
This is an implementation of NNM. It is contained in stream\_model.jl and
stream\_model\_io.jl.

### Function documentation
```@docs
StreamModel
StreamModel(::String, ::String)
evaluate!(::StreamModel)
load_from_tables
save_model_results
```

### Results access
These functions give ways of extracting key results from the model structure.
```@docs
get_outlet_nconc
get_avg_nconc
get_delivery_ratios
```
