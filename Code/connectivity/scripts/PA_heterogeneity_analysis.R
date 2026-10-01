library(dplyr)
library(sf)

pa_df = st_read("./Data/Connectivity_Data/data/PA400k_w25kcolors2.gpkg")
bioregions = st_read("./Data/Connectivity_Data/raw_data/BiogeoRegions2016.shp")

# Correlations -----------------------------------------------------------------

cor_herb = cor.test(pa_df$circ_s, pa_df$herb25_s, method = "spearman",
                    exact = FALSE, use = "complete.obs")
cor_pred = cor.test(pa_df$circ_s, pa_df$pred25_s, method = "spearman",
                    exact = FALSE, use = "complete.obs")

cor_herb$estimate
cor_pred$estimate

# Connectivity classes ---------------------------------------------------------

class3 = function(x) cut(x, c(-Inf, 1/3, 2/3, Inf),
                         labels = c("Low", "Intermediate", "High"),
                         right = FALSE)

pa_compare = pa_df %>%
  mutate(
    climate_class = class3(circ_s),
    herb_class = class3(herb25_s),
    pred_class = class3(pred25_s)
  )

pa_compare_df = pa_compare %>%
  st_drop_geometry() %>%
  mutate(
    herb_num = as.numeric(herb_class),
    pred_num = as.numeric(pred_class),
    shift = pred_num - herb_num,
    shift_class = case_when(
      shift < 0 ~ "Lower for predator",
      shift > 0 ~ "Higher for predator",
      TRUE ~ "No change"
    )
  )

combo_summary = function(data, group)
  data %>% count(climate_class, {{ group }}) %>% mutate(percent = 100 * n / sum(n))

herb_combos = combo_summary(pa_compare_df, herb_class)
pred_combos = combo_summary(pa_compare_df, pred_class)

shift_summary = pa_compare_df %>%
  count(shift_class) %>%
  mutate(percent = 100 * n / sum(n))

high_climate_shift = pa_compare_df %>%
  filter(climate_class == "High") %>%
  count(shift_class) %>%
  mutate(percent = 100 * n / sum(n))

herb_combos
pred_combos
shift_summary
high_climate_shift

# ------------------
# Bioregional entropy
# ------------------

bioregions = st_transform(bioregions, st_crs(pa_compare))

pa_bioregion = st_point_on_surface(pa_compare) %>%
  st_join(dplyr::select(bioregions, code), join = st_intersects) %>%
  st_drop_geometry()

region_entropy_fun = function(data, class_col, name) {
  data %>%
    count(code, climate_class, {{ class_col }}) %>%
    group_by(code) %>%
    mutate(p = n / sum(n)) %>%
    summarise("{name}" := -sum(p * log(p)), .groups = "drop")
}

region_entropy = region_entropy_fun(pa_bioregion, herb_class, "herb_entropy") %>%
  left_join(region_entropy_fun(pa_bioregion, pred_class, "pred_entropy"), by = "code") %>%
  mutate(
    entropy_change = pred_entropy - herb_entropy,
    herb_entropy_norm = herb_entropy / log(9),
    pred_entropy_norm = pred_entropy / log(9),
    entropy_change_norm = pred_entropy_norm - herb_entropy_norm
  )

region_entropy

write.csv(region_entropy, "./data/bioregional_entropy2.csv", row.names = FALSE)