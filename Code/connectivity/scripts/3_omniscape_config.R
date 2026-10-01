################################
# Transformation of SDM to resistance rasters & building Omniscape configuration files
# Author: Jeremy Dertien
# Last updated: 2026-08-01
#################################

library(terra)
library(dplyr)
library(stringr)

# spp prediction transformation (resistance maps)
burnin = rast("./Data/Connectivity_Data/raw_data/mammal_burnin.tif")
burnin = resample(burnin, mammals_covariants[[6]], method = "bilinear")

# Define the c value
c <- 1
# Apply the transformation to each prediction raster and save as TIF
spp_prediction_transformed <- lapply(names(spp_rastPaths), function(species_name){
  pred_rast_path <- spp_prediction_rastPaths[[species_name]]
  pred_rast<- terra::rast(pred_rast_path) # load the raster from its path
  #Apply the function
  transformed_rast <- transform_predictions(pred_rast, c)
  # Construct file path for saving and convert all zeros to 1 since resistances = 0 are not allowed
  transformed_combine <- app(sds(transformed_rast, burnin), fun = "max", na.rm = FALSE)
  transformed_combine <- subst(transformed_combine, from = 0, to = 1)
  file_path <- paste0(species_name, "energyresist_700.tif") # define the output path
  # Save the results as asc and ensure NA values are displayed as -9999
  writeRaster(transformed_combine, filename = file_path, overwrite = T, NAflag = -9999)
  return(file_path)
})

window_radi <- c("pred" = 80,"herb" = 50)

# Define paths to the input and output directories.
resistance_maps_dir <- "./Data/Connectivity_Data/data/resist"
source_wght_dir <- "./Data/Connectivity_Data/data/source"
config_dir <- "./Data/Connectivity_Data/data/omni_config"
output_dir <- "./Data/Connectivity_Data/data/omni_output"

# List all resistance map files in the specified directory.
resistance_files <- list.files(resistance_maps_dir, pattern = "\\resist_700.tif$", full.names = TRUE)
source_wght_files <- list.files(source_wght_dir, pattern = "\\.tif$", full.names = TRUE)
# Extract species names from the file names by removing file extensions and unwanted suffixes.
species_names <- sapply(source_wght_files, function(x) tools::file_path_sans_ext(basename(x)))
testname = gsub("_predictions","", species_names[[1]])
# Store paths to configuration files to be used later.

config_files <- list()

# Generate Omniscape configuration files for each species based on their specific resistance maps.
for(i in seq_along(resistance_files)) {
  species_name <- gsub("_source", "", species_names[[i]])
  sp_resistance_name <- resistance_files[i]
  radius = window_radi[[i]]
  project_name <- sprintf("%senergy_700",species_names[[i]])
  source_species <- gsub("_source", "", species_names[[i]])
  source_file <- source_wght_files[i]
  config_file_path <- sprintf("%s/%s.ini", config_dir, species_name)
  config_files[[species_name]] <- config_file_path
  
  # Configure Circuitscape options using species-specific details.
  config_options <- sprintf("
[Input files]
solver = cg+amg
resistance_file = %s
radius = %s
block_size = 5
project_name = %s
source_file = %s

[General options]
source_from_resistance = false
source_threshold = 0.25
parallelize = true
parallel_batch_size = 40

[Output options]
write_raw_currmap = true
calc_normalized_current = true
calc_flow_potential = true
mask_nodata = true

",sp_resistance_name, radius, project_name, source_file)
  
  # Save the configuration options to a file
  if (!file.exists(config_file_path)) {
    writeLines(config_options, config_file_path)
  }
  cat("Config file created at:", config_file_path, "
")
}

