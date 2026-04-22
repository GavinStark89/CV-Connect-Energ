library(terra)
library(enerscape)

if (interactive()) {
  datadir <- "data"
  mass <- 1e2
  direction <- "up"
} else {
  args <- commandArgs(trailingOnly = TRUE)
  stopifnot(length(args) == 3)
  datadir <- args[1]
  mass <- as.numeric(args[2])
  direction <- args[3]
  message(" - Mass = ", mass)
  message(" - Direction = ", direction)
}

message("     === START ===     ")
dem <- rast(file.path(datadir, "dem-projected.tif"))
en <- enerscape(dem, mass, "kcal", 4, direction = direction)
en <- en / res(en)[1] * 1e3  # to kcal/km
filename <- paste0(mass, "-", direction, ".tif")
output <- file.path(datadir, "enerscape", filename)
message(" - Writing to: ", output)
writeRaster(en, output, overwrite = TRUE, datatype = "INT2U")  # max (2^18 - 1) = 65,535 kcal
message("     === END ===     ")
