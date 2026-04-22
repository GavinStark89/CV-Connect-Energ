# Energy Landscapes

## Pipeline

The bash script `pipeline` (execute with `./pipeline`) runs the whole pipeline.
It skips steps that are already completed, unless the option `--clean` is specified (`./pipeline --clean`).
The pipeline requires two mandatory inputs (`mass` and `direction`) and one optional argument (`datadir`):

  1. The body mass of the animal, in kg (`--mass=` or `-m=`).
  2. The path to the data directory (`--datadir=` or `-dd=`).
  3. The direction of the movement (`--direction=` or `-d=`). 

If `datadir` is missing, it is assumed to be `/data/climate-velocity-energy` in the EVE HPC.
Direction should be one of: `left`, `down`, `right`, or `up`.
An example of working pipeline is: 

```bash
./pipeline -dd=data --mass=10 --direction=up
```

The pipeline calls two scripts:

  1. `enerscape.R`: energyscapes.
  2. `maximum-enerscape.R`: calculate the maximum values of energyscapes for all the neighbor cells.

Originally, it called more scripts to download and project the DEM.
This was adapted for this repository to reduce complexity and disk usage.

Energy landscapes are saved in the `$DATADIR` folder (as specified by `-dd=`) as a raster file with name `$MASS-$DIRECTION.tif` (as specified by `--mass=` and `--direction=`).
If the files requested as output already exist, the pipeline is stopped.
To force to re-run, use the `--clean` argument.

**The pipeline is design to work on the EVE HPC**.
Running on a system that does not have SLURM will not work.
To take full advantage of the resource in the HPC, you can launch many pipelines concurrently:

```bash
./pipeline -dd=data --mass=10 --direction=up
./pipeline -dd=data --mass=10 --direction=down
./pipeline -dd=data --mass=10 --direction=left
./pipeline -dd=data --mass=10 --direction=right
```

### Enerscape
The pipeline uses a new version of enerscape (v.1.1.2).
It is not yet on CRAN and see below for how to install it.
Energy landscapes are calculated from the focal cell, specifying the optional argument `direction = "out"` in `enerscape()`.
It uses the 8 adjacent neighbors, _but we should decide if to use only 4_.
For the maps produced, I use the `direction` argument of `enerscape()`, which calculates costs only from the focal cell to the cell in that direction.

### Install enerscape v.1.1.2
The new version (v.1.1.2) can be installed from GitHub (e.g., `devtools::install_github("emilio-berti/enerscape)`).
It can also be installed locally from the zip archive in the `Code/pkg` folder: `Rscript --vanilla -e "install.packages('pkg/enerscape', type = 'source', repos = NULL)"`.


### Ancillary scripts:

  - `srs.R`: list of the CRS used in the project.
  - `palettes.R`: list of palettes used for plotting.
  - `utils.R`: collection of function to post-process energy landscapes.
