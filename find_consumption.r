require("lidR")

# put the paths to your pre- and post-burn scans here
preburn.scan <- readLAS("C:/Users/js81535/Desktop/lidar_exploration/auto_clipped_scans/ambient_cones_rep1_autoclipped_pre.las")
postburn.scan <- readLAS("C:/Users/js81535/Desktop/lidar_exploration/auto_clipped_scans/ambient_cones_rep1_autoclipped_post.las")


# define a function for finding the volume of a scan
find_volume <- function(scan) {
  
  # classify noise points and trim them
  scan <- classify_noise(scan, sor(k=10, m=8))
  scan <- filter_poi(scan, Classification != 18)
  
  # classify ground and non-ground points
  mycsf <- csf(FALSE, class_threshold = 0.009, rigidness = 3)
  scan <- classify_ground(scan, mycsf)
  
  # normalize heights from the ground
  norm.scan <- normalize_height(scan, tin())
  
  # find height distribution and plot it (uncomment to perform)
  #fuel.points <- Filter(function(x) x > 0,  attributes(norm.scan)$data$Z)
  #boxplot(x = fuel.points, main = 'Height Distribution of Fuel Bed',  ylab = "heights (m)")
  
  # rasterize the top of the fuel bed
  fuel.raster <- rasterize_canopy(norm.scan, res = 0.004, algorithm = dsmtin())
  
  # get all of the individual pixels in the raster
  fuel.matrix <- as.matrix(fuel.raster)
  
  # make an empty list. Then, populate it with the volumes for each pixel
  uprights <- c()
  for (point in fuel.matrix) {
    # we only want points that have positive height
    if (!is.na(point) && point > 0) {
      upright.volume <- point * 0.000016    # multiply by the area of each pixel (which is the resolution squared)
      uprights <- append(uprights, upright.volume)      
    }
  }
  total.volume <- sum(uprights)
  return(total.volume)
  
}

# find the volumes of pre- and post-burn scans
pre.volume <- find_volume(preburn.scan)
post.volume <- find_volume(postburn.scan)

# find and print the percent-consumed by volume
consumption.pct <- ((pre.volume - post.volume) / pre.volume) * 100

cat("Percent Consumed by Volume:", consumption.pct)


