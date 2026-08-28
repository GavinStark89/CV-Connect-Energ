#Loading R-packages
#library(terra)

# Polygon layer for WDPA can be downloaded from https://www.protectedplanet.net/en/thematic-areas/wdpa?tab=WDPA

# Load data
WDPA <- vect("File path")   #Vector layer containing WDPA polygons or other protected areas
AOI <- vect("File path")    #Vector layer of study area (AOI)
CCV <- rast("Filepath")     #Raster layer of climate change velocity


# Fix geometry (just in case)
WDPA <- makeValid(WDPA)
AOI   <- makeValid(AOI)


# Match CRS (vector → Europe)
WDPA<- project(WDPA, crs(AOI))


# Clip polygons to Europe
WDPA_clipped <- intersect(WDPA, AOI)


# Match CRS to raster
WDPA_clipped <- project(CCV, crs(WDPA_clipped))


# Zonal statistics (mean CCV (km/year)
Zonal_mean <- extract(CCV, WDPA_clipped, fun = mean, na.rm = TRUE)

# Attach mean values
WDPA_clipped$mean_val <- Zonal_mean[,2]


# Compute equivalent radius (km) assuiming a circle using the GIS_ARE in km²,
# data column. If using other polygons than WDPA changes this to match column name containing area size or equivalent
WDPA_clipped$radius_km <- ifelse(
  is.na(WDPA_clipped$GIS_ARE) | WDPA_clipped$GIS_ARE <= 0,
  NA,
  sqrt(WDPA_clipped$GIS_ARE / pi)
)


# Compute Climate Resiliency (years)
# Climate Resiliency = distance (km) / CCV (km/year)
WDPA_clipped$time_years <- ifelse(
  is.na(WDPA_clipped$mean_val) | WDPA_clipped$mean_val <= 0,
  NA,
  WDPA_clipped$radius_km / WDPA_clipped$mean_val
)


# Save output

writeVector(
  WDPA_clipped,
  "File Directory/WDPA_Climate_Resiliency.shp",
  overwrite = TRUE
)
