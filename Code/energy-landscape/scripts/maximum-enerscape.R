library(terra)

if (interactive()) {
  datadir <- "data"
  mass <- 1e2
} else {
  args <- commandArgs(trailingOnly = TRUE)
  stopifnot(length(args) == 2)
  datadir <- args[1]
  mass <- as.numeric(args[2])
  message(" - Mass = ", mass)
}

message("     === START ===     ")
ff <- list.files(
  file.path(datadir, "enerscape"),
  pattern = as.character(mass),
  full.names = TRUE
)
stopifnot(length(ff) == 4)
r <- rast(ff)
r <- max(r)
filename <- paste0(mass, "-maximum.tif")
output <- file.path(datadir, "enerscape", filename)
message(" - Writing to: ", output)
writeRaster(r, output, overwrite = TRUE, datatype = "INT2U")  # max (2^18 - 1) = 65,535 kcal
message("     === END ===     ")
