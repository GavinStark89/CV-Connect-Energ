# Climate-velocity connectivity analysis

This directory contains the main analysis scripts used to evaluate functional connectivity and climate-related connectivity patterns across European protected areas. The workflow combines species occurrence data, environmental covariates, GLMM-based species distribution models (SDMs), Omniscape circuit-theory connectivity, and protected-area summaries.

## Workflow

The numbered scripts are intended to be run broadly in sequence:

1. **`1_presence_covariate_processing.R`**  
   Pre-processes species occurrence data, creates presence/available locations, and extracts environmental covariates for model fitting.

2. **`2_glmm_main_prediction.R`**  
   Fits the main GLMMs and generates spatial predictions used in the connectivity workflow. Performs model diagnostics.

3. **`3_omniscape_config.R`**  
   Transforms SDMs to resistance rasters and prepares Omniscape inputs and configuration files from the modeled spatial layers.

4. **`4_run_omniscape_multiconfigs.jl`**  
   Runs Omniscape configurations in Julia to generate cumulative and normalized current-density surfaces.

5. **`5_protected_area_merge.R`**  
   Prepares PA-level data for subsequent analyses through iterative merging of neighboring polygons. Links connectivity outputs to the protected-area network.

Additional analyses:

- **`PA_heterogeneity_analysis.R`** — evaluates variation in climate/connectivity relationships among protected areas and biogeographic regions, including class shifts and Shannon entropy.
- **`similarity_analysis.R`** — compares similarity among connectivity outputs and/or protected-area connectivity patterns used in the synthesis analyses.

## Software

Analyses are primarily written in **R**, with Omniscape runs performed in **Julia**. Common R dependencies include `terra`, `sf`, `dplyr`, `tidyr`, `stringr`, `lme4`, and related modeling packages. Omniscape requires the Julia package `Omniscape.jl`.

## Spatial data

Most spatial analyses use **ETRS89 / LAEA Europe (EPSG:3035)**. Large raster and vector inputs are not stored in this code directory and should be supplied separately using the relative paths expected by each script (e.g. `./raw_data/` and `./data/`).

## Notes

- The numbered scripts form the core processing workflow; the two unnumbered scripts are downstream synthesis analyses.
- File paths are written as project-relative paths where possible so the workflow can be reproduced outside the original computing environment.
- Some steps, particularly Omniscape and large raster operations, can require substantial memory and processing time.

## Author

Jeremy Dertien
01.08.2026
