library(terra)
library(dplyr)

# Load cumulative-current rasters
herb = rast("./Data/Connectivity_Data/herbivore_cumprj.tif")
pred = rast("./Data/Connectivity_Data/predmax_cumpprj.tif")

# ------------------------------------------------------------
# 1. Align rasters
# ------------------------------------------------------------

# Project carnivore raster if CRS differs
if (!same.crs(herb, pred)) {
  pred = project(pred, herb)
}

# Align extent/resolution/grid if needed
if (!compareGeom(
  herb,
  pred,
  stopOnError = FALSE,
  crs = TRUE,
  ext = TRUE,
  rowcol = TRUE,
  res = TRUE
)) {
  pred = resample(pred, herb, method = "bilinear")
}

# Keep only cells that contain data in BOTH rasters
common_mask = !is.na(herb) & !is.na(pred)

herb_common = mask(herb, common_mask, maskvalues = 0)
pred_common = mask(pred, common_mask, maskvalues = 0)

#----------------------------
# Spearman rank correlation testing
# ---------------------------

# Extract values from common valid cells
herb_vals = values(herb_common, mat = FALSE)
pred_vals = values(pred_common, mat = FALSE)

valid = is.finite(herb_vals) & is.finite(pred_vals)

herb_vals = herb_vals[valid]
pred_vals = pred_vals[valid]

# Spearman rank correlation
spearman_result = cor.test(
  herb_vals,
  pred_vals,
  method = "spearman",
  exact = FALSE
)

spearman_result
rho = unname(spearman_result$estimate)

rho

spearman_summary = data.frame(
  comparison = "Herbivore vs large predators",
  n_cells = length(herb_vals),
  spearman_rho = rho,
  p_value = spearman_result$p.value
)

spearman_summary


# Percentages of the highest-current landscape to compare
hotspot_levels = c(0.05, 0.10, 0.25)

calculate_hotspot_overlap = function(herb_rast, pred_rast, proportion) {
  
  herb_vals = values(herb_rast, mat = FALSE)
  pred_vals = values(pred_rast, mat = FALSE)
  
  valid = is.finite(herb_vals) & is.finite(pred_vals)
  
  h = herb_vals[valid]
  c = pred_vals[valid]
  
  # Threshold defining the upper X% of each raster
  herb_threshold = quantile(h, probs = 1 - proportion,na.rm = TRUE)
  
  pred_threshold = quantile(c, probs = 1 - proportion, na.rm = TRUE)
  
  # Binary hotspot membership
  herb_hot = h >= herb_threshold
  pred_hot = c >= pred_threshold
  
  # Cell counts
  herb_n = sum(herb_hot)
  pred_n = sum(pred_hot)
  
  shared_n = sum(herb_hot & pred_hot)
  union_n = sum(herb_hot | pred_hot)
  
  # Similarity measures
  jaccard = shared_n / union_n
  
  herb_shared_pct = 100 * shared_n / herb_n
  pred_shared_pct = 100 * shared_n / pred_n
  
  data.frame(
    hotspot = paste0("Top ", proportion * 100, "%"),
    herb_threshold = herb_threshold,
    pred_threshold = pred_threshold,
    herb_cells = herb_n,
    pred_cells = pred_n,
    shared_cells = shared_n,
    union_cells = union_n,
    herb_shared_pct = herb_shared_pct,
    pred_shared_pct = pred_shared_pct,
    jaccard = jaccard
  )
}

overlap_results = bind_rows(lapply(hotspot_levels, function(x) {
      calculate_hotspot_overlap(
        herb_common,
        pred_common,
        x
      )
    }
  )
)

overlap_results

cell_area = cellSize(herb_common, unit = "km")
mean_cell_area = global(cell_area, "mean", na.rm = TRUE)[1, 1]

overlap_results = overlap_results %>%
  mutate(herb_area_km2 = herb_cells * mean_cell_area,
    pred_area_km2 = pred_cells * mean_cell_area,
    shared_area_km2 = shared_cells * mean_cell_area,
    union_area_km2 = union_cells * mean_cell_area
  )

overlap_results


overlap_results %>%
  mutate(herb_actual_pct = 100 * herb_cells / sum(valid),
    pred_actual_pct = 100 * pred_cells / sum(valid)
  )

#----------------------
# Patch Metrics
#----------------------

calculate_patch_metrics = function(r, proportion) {
  
  vals = values(r, mat = FALSE)
  vals = vals[is.finite(vals)]
  
  threshold = quantile(vals, probs = 1 - proportion, na.rm = TRUE)
  
  # Binary hotspot raster: hotspot = 1, everything else = NA
  hot = ifel(r >= threshold, 1, NA)
  
  # Identify contiguous hotspot patches
  # directions = 8 allows diagonal connectivity
  patch_rast = patches(
    hot,
    directions = 8
  )
  
  # Frequency of cells in each patch
  patch_freq = freq(patch_rast)
  
  # If 1 km raster, each cell is approximately 1 km2
  cell_area = cellSize(r, unit = "km")
  
  mean_area = global(cell_area, "mean", na.rm = TRUE)[1, 1]
  
  patch_freq$area_km2 = patch_freq$count * mean_area
  
  total_hotspot_area = sum(patch_freq$area_km2)
  
  data.frame(hotspot = paste0("Top ", proportion * 100, "%"),
    threshold = threshold,
    n_patches = nrow(patch_freq),
    
    mean_patch_km2 = mean(patch_freq$area_km2),
    
    median_patch_km2 = median(patch_freq$area_km2),
    
    largest_patch_km2 = max(patch_freq$area_km2),
    
    largest_patch_pct = 100 * max(patch_freq$area_km2) / total_hotspot_area
  )
}

levels = c(0.05, 0.10, 0.25)

herb_patch = bind_rows(
  lapply(levels, function(x)
      calculate_patch_metrics(herb_common, x)
  )
) %>%
  mutate(archetype = "Herbivore")

pred_patch = bind_rows(
  lapply(levels, function(x)
      calculate_patch_metrics(pred_common, x)
  )
) %>%
  mutate(archetype = "Large predator")

patch_results = bind_rows(herb_patch, pred_patch)

patch_results

herb_rank = rank(herb_vals, ties.method = "average") / length(herb_vals)

pred_rank = rank(pred_vals, ties.method = "average") / length(pred_vals)

# Cells in upper 25% for herbivore
herb_favourable = herb_rank >= 0.75

# Where those cells fall in carnivore distribution
pred_classes = cut(
  pred_rank[herb_favourable],
  breaks = c(
    0,
    0.50,
    0.75,
    0.90,
    1
  ),
  labels = c(
    "Bottom 50%",
    "50-75%",
    "75-90%",
    "Top 10%"
  ),
  include.lowest = TRUE
)

prop.table(table(pred_classes)) * 100
