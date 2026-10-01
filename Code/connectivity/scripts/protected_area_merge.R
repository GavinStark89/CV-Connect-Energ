################################
# Iterative merging of European protected areas (PA) to create local more ecologically congruent PA clusters
# Author: Jeremy Dertien
# Last updated: 2026-08-01
#################################

library(sf)
library(dplyr)
library(units)

# Read in the protected areas layer and repair geometry through st_make_valid
pa = st_read("./data/protected_areas.gpkg", driver = "GPKG")

pa1k = st_make_valid(pa %>% filter(area_km2 > set_units(1, km^2)))

##Function: Iteratively merge small to large polygons at varying size thresholds
merge_small_polygons_iterative = function(
    pa,
    thresholds_km2 = c(5, 15, 25, 50, 75, 100), #threshold sizes to separate small and large polygons
    buffer_dist_m = 2000, #buffer to determine merging distance
    snap_tol_m = 1,
    simplify_tol_m = 1,
    out_dir = "threshold_outputs"
) {
  
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  
  pa_current = pa
  
  for (th in thresholds_km2) {
    message(sprintf("[< %skm²] Starting merge step", th))
    area_thresh = th  # numeric km²
    
    # Split polygons
    small_polygons = pa_current |> dplyr::filter(area_km2 < area_thresh)
    large_polygons = pa_current |> dplyr::filter(area_km2 >= area_thresh)
    
    message(sprintf(
      "[< %skm²] Small polygons: %s | Large polygons: %s",
      th, nrow(small_polygons), nrow(large_polygons)
    ))
    
    if (nrow(small_polygons) == 0 || nrow(large_polygons) == 0) {
      message(sprintf("[< %skm²] Nothing to merge, skipping", th))
      next
    }
    
    # Buffer small polygons
    message(sprintf("[< %skm²] Buffering small polygons (%sm)", th, buffer_dist_m))
    small_buf = st_buffer(small_polygons, dist = buffer_dist_m)
    
    # Proximity detection
    message(sprintf("[< %skm²] Finding proximity to large polygons", th))
    near_large = st_intersects(
      small_buf, large_polygons, sparse = FALSE
    ) |> rowSums() > 0
    
    # Drop buffer immediately to save memory
    rm(small_buf)
    invisible(gc())
    
    small_near = small_polygons[near_large, ]
    small_far  = small_polygons[!near_large, ]
    
    message(sprintf(
      "[< %skm²] Near large: %s | Far: %s",
      th, nrow(small_near), nrow(small_far)
    ))
    
    if (nrow(small_near) == 0) {
      message(sprintf("[< %skm²] No mergeable polygons, skipping", th))
      next
    }
    
    # Assign nearest large polygon ID
    message(sprintf("[< %skm²] Assigning nearest large polygon IDs", th))
    small_grouped = small_near |>
      st_join(
        large_polygons |> dplyr::select(id_large = WDPAID),
        join = st_nearest_feature,
        left = FALSE
      )
    
    rm(small_near)
    invisible(gc())
    
    # Merge step of small_near and related near large polygons
    message(sprintf("[< %skm²] Merging polygons", th))
    
    merged_list = small_grouped |>
      dplyr::group_split(id_large) |>
      lapply(function(group) {
        
        id = unique(group$id_large)
        large_poly = large_polygons |> dplyr::filter(WDPAID == id)
        
        if (nrow(large_poly) == 0) return(NULL)
        
        # Snap geometries to prevent explosion of the number of vertices
        large_poly = st_snap(large_poly, group, tolerance = snap_tol_m)
        group      = st_snap(group, large_poly, tolerance = snap_tol_m)
        
        merged_geom = st_union(
          c(st_geometry(large_poly), st_geometry(group))
        )
        
        # Keep largest piece if multipart
        if (length(merged_geom) > 1) {
          merged_geom = merged_geom[which.max(st_area(merged_geom))]
        }
        merged_df = large_poly
        st_geometry(merged_df) = merged_geom
        
        merged_df
      })
    
    rm(small_grouped)
    invisible(gc())
    
    merged_sf = do.call(rbind, merged_list)
    
    rm(merged_list)
    invisible(gc())
    
    message(sprintf(
      "[< %skm²] Merged polygons created: %s",
      th, nrow(merged_sf)
    ))
    
    # Reassemble dataset
    message(sprintf("[< %skm²] Reassembling final dataset", th))
    
    unmerged_large = large_polygons |>
      dplyr::filter(!WDPAID %in% merged_sf$WDPAID)
    
    pa_current = dplyr::bind_rows(
      merged_sf,
      small_far,
      unmerged_large
    )
    
    # Drop all intermediates to save memory
    rm(
      merged_sf,
      small_far,
      unmerged_large,
      small_polygons,
      large_polygons
    )
    invisible(gc())
    
    # Simplify once per threshold
    pa_current = st_simplify(
      pa_current,
      dTolerance = simplify_tol_m,
      preserveTopology = TRUE
    )
    
    # Recalculate area (numeric km²)
    pa_current$area_km2 = as.numeric(st_area(pa_current)) / 1e6
    
    # Save results at each threshold
    out_file = file.path(
      out_dir,
      paste0("PA_merge_lt_", th, "km2.gpkg")
    )
    
    st_write(pa_current, out_file, delete_layer = TRUE)
    
    message(sprintf(
      "[< %skm²] Step complete | Saved: %s | Object size: %.1f MB",
      th,
      out_file,
      as.numeric(object.size(pa_current)) / 1024^2
    ))
    
    rm(out_file, area_thresh)
    invisible(gc())
  }
  
  pa_current
}

# Useful for projected CRS workflows
sf::sf_use_s2(FALSE)

# Rechecking geometry validation
pa_valid = st_make_valid(pa1k)

# Run iterative merge
pa_final = merge_small_polygons_iterative(
  pa = pa_valid,
  thresholds_km2 = c(75, 100, 200, 400, 500),
  buffer_dist_m = 2000,
  snap_tol_m = 1,
  simplify_tol_m = 1,
  out_dir = "PA_threshold_merges"
)
