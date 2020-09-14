# NitrateNetworkModel.jl

Implementation of network-based model of in-stream nitrate and carbon dynamics described in [Czuba, et al. (2018)](https://doi.org/10.1002/2017WR021859)

## Usage
The basic simulation of the LeSueur basin can be run with these commands:

```bash
% git clone https://github.com/phawthorne/NitrateNetworkModel.jl
% cd NitrateNetworkModel.jl/scripts
% julia init.jl
% julia run_le_sueur.jl
```

This will produce `.../NitrateNetworkModel.jl/data/LeSueur/results/base_results.csv`.