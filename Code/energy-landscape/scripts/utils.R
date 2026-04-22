#' @title Load Cost of Travel Rasters
#' @param mass body mass (kg) of the animal.
#' @param datadir directory where the rasters are saved.
#' @return A raster stack of the layers.
load_enerscape <- function(mass, datadir = "data/enerscape") {
	stopifnot(dir.exists(datadir))
	stopifnot(is(mass, "numeric"))
	ff <- list.files(datadir, pattern = as.character(mass), full.names = TRUE)	
	directions <- sapply(strsplit(ff, "/"), \(x) x[length(x)])
	directions <- sapply(strsplit(directions, "[.]"), \(x) x[1])
	directions <- sapply(strsplit(directions, "-"), \(x) x[length(x)])
	r <- rast(ff)
	names(r) <- directions
	r <- r[[c("left", "down", "right", "up")]]
	return(r)
}
