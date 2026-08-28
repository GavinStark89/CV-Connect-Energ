Climate Change Velocity and Climate Resiliency
This repository contains two R scripts for calculating Climate Change Velocity (CCV) and estimating Climate Resiliency within protected areas.

1. Climate Change Velocity

`CCV_calculations.R` calculates CCV from historical and future climate raster data.
Climate data can be obtained from:
[WorldClim](https://www.worldclim.org/)
[CHELSA](https://www.chelsa-climate.org/)

The workflow:

1. Loads historical and future climate rasters.
2. Reprojects them to EPSG:3035 at 1 km resolution. (Can be changes dependent on requirements) 
3. Calculates the temporal climate gradient.
4. Calculates the spatial climate gradient.
5. Calculates CCV
6. Saves `CCV.tif` and a log-transformed version `Log_CCV.tif`.

The number of years between the historical and future datasets must be specified in:
`Years <- XX`

2. Climate Resiliency

`Climate_Resiliency_Calculations.R` calculates a climate-resiliency metric for protected areas using the CCV raster.

Required inputs:
* WDPA or other protected-area polygons
* Area of Interest (AOI)
* CCV raster

For each protected area, the script:
1. Clips the protected areas to the AOI.
2. Extracts the mean CCV.
3. Calculates an equivalent radius of each protected area forcing a circular shape.
4. Calculates climate resiliency


The scripts require compatible climate rasters, protected-area polygons, and an AOI. Paths to all input and output files must be updated before running the scripts.
