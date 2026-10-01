
################################
# Pre-processing of occurrence and covariate data to set up GLMM analysis of large mammals 
# Author: Jeremy Dertien
# Last updated: 2026-08-01
#################################

library(terra)
library(dplyr)
library(sf)
library(stringr)
library(tidyr)

studyarea = st_read("./Data/Connectivity_Data/raw_data/your_study_area.shp")
spgrid = st_read("./raw_data/occurrences_data/sp_occurrence.shp") #species data as grid squares
mammals_covariants <- rast("./raw_data/RastStack_10k_2.grd")

# -----------------
# Utility Functions
# -----------------
# Function to generate points only at the center of each square
st_centroid_within_poly <- function(poly) {
  # Check if centroid is in polygon
  ctrd <- st_centroid(poly, of_largest_polygon = TRUE)
  in_poly <- diag(st_within(ctrd, poly, sparse = FALSE))
  # Replace geometries that are not within polygon
  st_geometry(ctrd[!in_poly,]) <- st_geometry(st_point_on_surface(poly[!in_poly,]))
  
  return(ctrd)
}
# Function to apply buffers and dissolve with variable distances
st_buffer_presence_squares <- function(sf_object, presence_column, buffer_distances) { 
  # Assuming the presence column effectively indicates the species and that each sf object is for a single species, 
  # so taking the first values is sufficient
  species_name <- names(buffer_distances)[which(names(buffer_distances) == presence_column)] 
  dist <- buffer_distances[presence_column]
  buff <- st_buffer(sf_object, dist = dist)
  buff_union <- st_as_sf(data.frame(id = 1), geometry = st_union(buff))
  buff_union_valid <- st_make_valid(buff_union)
  
  return(buff_union_valid)
}
# Function to erase
st_erase <- function(x, y) {
  st_difference(x, st_union(st_combine(y)))
}

# ----------
# Main Script
# -----------
# Extract genus part from column names [Not necessary for other data types]
genus_names = names(spgrid)[grepl("^m_", names(spgrid))] %>%
  str_extract("(?<=_)[a-z]{3}") %>%
  unique()

# Isolate species by genus and sum into one column per genus into a list
sf_eu_mammals_by_genus <- list()
for (genus in genus_names) {
  # Identify columns belonging to this genus
  cols <- grep(paste0("_", genus), names(spgrid), value = TRUE)
  # Select and sum columns for each genus, replace 9 with 1 ---- deviation from previous, now including outside squares as presence
  sf_eu_mammals_by_genus[[genus]] <- spgrid %>%
    select(cellcode, eoforigin, noforigin, all_of(cols)) %>%
    rowwise() %>%
    mutate(genus_sum = sum(c_across(all_of(cols)), na.rm = TRUE),
           genus_sum = if_else(genus_sum == 9, 1, genus_sum)) %>%
    ungroup() %>%
    select(cellcode, eoforigin, noforigin, genus_sum)
  # Rename the summed column to reflect the genus
  names(sf_eu_mammals_by_genus[[genus]])[4] <- paste0("m_", genus, "spp")
}

names(sf_eu_mammals_lst) <- paste0("m_", genus_names, "spp")

# Select the only presence squares
sf_eu_mammals_pres_lst <- lapply(sf_eu_mammals_lst, function(sf_obj){
  #Filter rows where any numeric column has a values of 1
  sf_obj %>% 
    filter(if_any(where(is.numeric), ~ .x == 1))
})

# Create points for the presence squares
eu_mammals_pres_pts_lst <- lapply(sf_eu_mammals_pres_lst, st_centroid_within_poly) 

# Create buffer with different buffer distances to create pseudo-absence points
buffer_distances <- c("m_canspp" = 75000, "m_ursspp" = 80000, "m_lynspp" = 60000, 
                      "m_gulspp" = 40000, "m_alcspp" = 40000, "m_capspp" = 40000, 
                      "m_cerspp" = 40000, "m_rupspp" = 40000, "m_susspp" = 40000, 
                      "m_rnspp" = 60000)

# Create the buffer taking into account the buffer distances
eu_mammals_pres_pts_buff_lst <- lapply(names(eu_mammals_pres_pts_lst), function(x){ 
  sf_object <- eu_mammals_pres_pts_lst[[x]]
  presence_column <- x  
  st_buffer_presence_squares(sf_object, presence_column, buffer_distances)
})

# Assigning objects names
names(eu_mammals_pres_pts_buff_lst) <- paste0("m_", genus_names, "spp")

# Erase the presence squares to obtain a fully dissolved single polygon on the outside 
eu_mammals_buff_diff_lst <- list()

for (name in names(eu_mammals_pres_pts_buff_lst)){
  if (name %in% names(sf_eu_mammals_pres_lst)) {
    eu_mammals_buff_diff_lst[[name]] <- st_erase(eu_mammals_pres_pts_buff_lst[[name]], sf_eu_mammals_pres_lst[[name]])  
  } else {
    eu_mammals_buff_diff_lst[[name]] <- NULL
    print(paste("No matchinf sf object for:", name))
  }
}

# Clip the available buffer area by the countries of the study area
eu_mammals_buff_diff_ctry_lst <- list()
# Loop through each sf object and intersect with the nations "study area"
for(name in names(eu_mammals_buff_diff_lst)){
  eu_mammals_buff_diff_ctry_lst[[name]] <- st_intersection(eu_mammals_buff_diff_lst[[name]], studyarea) 
}

# Clip the buffer area with the initial grid that contains 0 and 1
eu_mammals_buff_diff_ctry_clip_lst <- list() 
for(name in names(eu_mammals_buff_diff_ctry_lst)){
  if(name %in% names(sf_eu_mammals_lst)) {
    eu_mammals_buff_diff_ctry_clip_lst[[name]] <- st_intersection(sf_eu_mammals_lst[[name]], eu_mammals_buff_diff_ctry_lst[[name]])
  } else {
    warning(paste(name, 'not found in sf_eu_mammals_lst'))
  }
}

# Create point from available squares
eu_mammals_avail_pts <- lapply(eu_mammals_buff_diff_ctry_clip_lst, function(sf_object){
  selected_sf_object <- sf_object  %>%
    select(1:4, geometry)
  st_centroid_within_poly(selected_sf_object)
})

eu_mammals_avail_selected_pts <- lapply(eu_mammals_avail_pts, function(sf_object){
  # Filter rows, where any numeric columns has a 0 values
  sf_object %>%
    filter(if_any(where(is.numeric), ~ .x == 0))
})

# Final result combine the presence and available points
eu_mammals_pres_avail_pts <- list()
for (name in names(eu_mammals_pres_pts_lst)){
  # Retrieve the matching sf objects from both list and combine objects
  sf_objec1 <- eu_mammals_pres_pts_lst[[name]]
  sf_objec2 <- eu_mammals_avail_selected_pts[[name]]
  combined_sf <- rbind(sf_objec1, sf_objec2)
  eu_mammals_pres_avail_pts[[name]] <- combined_sf 
}


# Extract covariate values for presence and available points
eu_mammals_covs_values <- lapply(eu_mammals_pres_avail_pts, function(sf_object){
  # Convert sf object to SpatVector for compatibility with terra::extract()
  spat_vector <- vect(sf_object)
  df <- terra::extract(mammals_covariants, spat_vector, bind = TRUE) |>
    as.data.frame()
  # Replace any NA with 0
  df <- df %>% 
    mutate(across(where(is.numeric), ~replace_na(., 0)))
  return(df)
})
saveRDS(eu_mammals_covs_values,"./data/eu_mammal_covvalues.Rds")

##Save data needed for species prediction script and write .csv
length(eu_mammals_covs_values)

for (i in seq_along(eu_mammals_covs_values)) {
  write.csv(
    eu_mammals_covs_values[[i]],
    paste0("./data/", names(eu_mammals_covs_values)[i], ".csv"),
    row.names = FALSE
  )
}
