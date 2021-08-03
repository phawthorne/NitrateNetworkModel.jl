# Documentation for NitrateNetworkModel

This module implements the Nitrate Network Model described in [Czuba, et al. (2018)](https://doi.org/10.1002/2017WR021859).

## Basic usage

Basic usage requires two files, one that defines model parameters and another that defines the stream network to be simulated. In the example below, these are `base_params.csv` and `network_table.csv`. Construct a `StreamModel`, and then `evaluate!()` it to run the model.

```julia
using NitrateNetworkModel

sm = StreamModel(
    "../data/base_params.csv", 
    "../data/network_table.csv"
)
evaluate!(sm)
save_model_results(sm, "../results/base_results.csv")
```
