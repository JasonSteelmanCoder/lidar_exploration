# This program takes in the path to a cropped .las file. 
# It plots the height distribution of the fuel bed and 
# prints the total volume of the bed to the console.

require("lidR")

# USER: type the path to your input file here:
input.path <- "C:/Users/js81535/Desktop/lidar_exploration/auto_clipped_scans/ambient_cones_rep1_autoclipped_pre.las"

# load the scan
las <- readLAS(input.path)

# classify noise points and trim them
las <- classify_noise(las, sor(k=10, m=8))
las <- filter_poi(las, Classification != 18)

# classify ground and non-ground points
mycsf <- csf(FALSE, class_threshold = 0.01, rigidness = 3, cloth_resolution = 0.9)
las <- classify_ground(las, mycsf)
#plot(las, color = 'Classification')

# normalize heights from the ground and plot the scan
norm.las <- normalize_height(las, tin())

# plot(norm.las, legend = TRUE, color = 'Z')

print(attributes(norm.las))


# find height distribution and plot it
fuel.points <- Filter(function(x) x > 0,  attributes(norm.las)$data$Z)

boxplot(x = fuel.points, main = 'Height Distribution of Fuel Bed',  ylab = "heights (m)")


# rasterize the top of the fuel bed
fuel.raster <- rasterize_canopy(norm.las, res = 0.004, algorithm = dsmtin())
#plot(fuel.raster)

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
print(total.volume)




