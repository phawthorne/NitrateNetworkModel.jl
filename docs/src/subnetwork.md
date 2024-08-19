# Subnetworks

Functions to pull out sub-models from full models. Intended for use in testing or when there's an interest in a subregion.

## Usage
Define a `SubNetworkDef` struct, then call `generate_subnetwork`. Once this is done, `StreamModel` and `FlowRegime` structs can be created directly from the `SubNetworkDef` struct

## Documentation
```@docs
SubNetworkDef
generate_subnetwork
StreamModel(::SubNetworkDef)
FlowRegime(::SubNetworkDef)
```
