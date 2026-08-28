#Loading R-packages
#library(terra)
#library(raster)

# The input data kan be from either WORLDCLIM:https://www.worldclim.org
# or CHELSEA:https://www.chelsa-climate.org/

# Loading climate raster.
ClimateH_EU <- rast("File path") #file path for historic climate/temperature raster (tif)
ClimateF_EU <- rast("File path") #file path for futureclimate/temperature raster (tif)


# Project raster to EPSG: 3035, and set the resolution to 1000 x 1000 meters (1 km)
# can be changed to to other projections and/or resolutions (depending on cthe hoosen resolution when downloading the initial data)
ClimateH_EU_proj <- project(ClimateH_EU, "EPSG:3035", res = 1000)
ClimateF_EU_proj <- project(ClimateF_EU, "EPSG:3035", res = 1000)

# First, the temporal gradient is calculated.
# The future prediction and the historical data is subtracted, and thereafter divided by the number of years the two layers span across
# In this case a total of 80 years
Years <- XX
Temporal <- (ClimateF_EU_proj - ClimateH_EU_proj) / Years

# Then the spatial gradient is estimated using the slope-function from 'terra'
Spatial <- terra::terrain(ClimateH_EU_proj, v='slope', neighbors=8, unit='degrees')
# A small constant is added to the spatial gradient to remove much smaller values
Spatial_01 <- Spatial + 0.0001 


# Calculate CCV and save raster
CVV <- Temporal / Spatial_01
plot(CVV)
writeRaster(CVV, "File Directory/CCV.tif", overwrite = TRUE) #Save CCV raster

# Log-transform the CCV raster and save the new raster
CVV_log <- log(CVV)
CVV_log[CVV_log < 0] <- 0


# Save log-transformed CCV raster
writeRaster(CVV_log, "File Directory/Log_CCV.tif", overwrite = TRUE) 



