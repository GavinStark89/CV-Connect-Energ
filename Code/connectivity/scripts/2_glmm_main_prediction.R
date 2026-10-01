################################
# Species distribution modelling and diagnostics for large herbivores and carnivores of Europe
# Author: Jeremy Dertien
# Last updated: 2026-08-01
#################################

library(parallel)
library(lme4)
library(MuMIn)
library(caret)
library(pROC)
library(ecospat)

pred_vars = c("forest", "ag", "dvlp", "shrub", "wland",
              "RdDensity", "Elev", "TempMax",
              "Precip", "Snow")

# Fit GLMM + model average all models with Delta AICc < 8
fit_model = function(df, sp) {
  f = as.formula(paste(sp, "~", paste(pred_vars, collapse = " + "), "+ (1|BioGeo10k)"))
  m = glmer(f, df, binomial, control = glmerControl(optimizer = "bobyqa"))
  ms = dredge(m, rank = "AICc")
  mods = get.models(ms, subset = delta < 8)
  avg = if (length(mods) == 1) mods[[1]] else model.avg(mods)
  list(model = avg, n_models = length(mods), model_table = ms)
}

# Calculate AUC + Boyce from validation data
get_metrics = function(model, test, sp) {
  p = predict(model, newdata = test, type = "response",
              re.form = NULL, allow.new.levels = TRUE)
  y = test[[sp]]
  ok = complete.cases(y, p); y = y[ok]; p = p[ok]
  
  c(AUC = as.numeric(auc(roc(y, p, levels = c(0, 1), direction = "<", quiet = TRUE))),
    Boyce = tryCatch(ecospat.boyce(fit = p, obs = p[y == 1], nclass = 0, PEplot = FALSE)$cor,
    error = function(e) NA_real_)
  )
}

# Species and stratified 5-fold splits
species_names = names(eu_mammals_covs_values)
set.seed(45)
folds = setNames(lapply(species_names, \(sp)
                        createFolds(eu_mammals_covs_values[[sp]][[sp]], k = 5)), species_names)

# 55 independent species x fold jobs
jobs = expand.grid(species = species_names, fold = 1:5,
                   stringsAsFactors = FALSE)

#Parallel cluster
no_cores = 20
cl = makeCluster(no_cores)

clusterExport(cl, c("eu_mammals_covs_values", "pred_vars", "folds",
                    "fit_model", "get_metrics", "jobs"))

clusterEvalQ(cl, {
  library(lme4)
  library(MuMIn)
  library(pROC)
  library(ecospat)
  options(na.action = "na.fail")
})

# 5-fold CV for every species
cv_list = parLapply(cl, seq_len(nrow(jobs)), function(j) {
  sp = jobs$species[j]; i = jobs$fold[j]
  df = eu_mammals_covs_values[[sp]]
  test_id = folds[[sp]][[i]]
  fit = fit_model(df[-test_id, ], sp)
  met = get_metrics(fit$model, df[test_id, ], sp)
  data.frame(species = sp, fold = i, n_models = fit$n_models,
             AUC = met["AUC"], Boyce = met["Boyce"])
})

cv_folds = do.call(rbind, cv_list)

# Fit final delta-AICc < 8 averaged models using all data
species_models = parLapply(cl, species_names, \(sp)
                           fit_model(eu_mammals_covs_values[[sp]], sp))

names(species_models) = species_names
stopCluster(cl)

##Species-level CV summary
cv_summary = aggregate(cbind(AUC, Boyce) ~ species, cv_folds,
                       \(x) c(mean = mean(x, na.rm = TRUE),
                              sd = sd(x, na.rm = TRUE)))

# Clean summary columns
cv_summary = data.frame(
  species = cv_summary$species,
  mean_AUC = cv_summary$AUC[, "mean"],
  sd_AUC = cv_summary$AUC[, "sd"],
  mean_Boyce = cv_summary$Boyce[, "mean"],
  sd_Boyce = cv_summary$Boyce[, "sd"]
)

saveRDS(species_models, "species_GLMM_models.rds")
saveRDS(cv_folds, "GLMM_CV_folds.rds")
write.csv(cv_summary, "GLMM_CV_summary.csv", row.names = FALSE)

cv_summary