# This program takes in a folder of raw .las scans (of the whole lab). 
# It outputs a folder of cropped, denoised .las scans only including the fire platform and fuel bed.

require("lidR")

# USER: write the path to your input folder here.
# all input files should end with "_pre.las" or "_post.las"
input.folder <- "C:/Users/js81535/Desktop/lidar_exploration/unclipped_scans/LAS files/"
input.file.names <- list.files(path = input.folder, full.names = FALSE)

# USER: write the path to your output folder here.
output.folder <- "C:/Users/js81535/Desktop/lidar_exploration/auto_clipped_scans"

# loop through all of the files in the input folder
for (file.name in input.file.names) {
  # load the scan
  las <- readLAS(file.path(input.folder, file.name))

  # find the median position of all of the points in the scan
  med.x <- median(las$X)
  med.y <- median(las$Y)
  med.z <- median(las$Z)
  
  #print(c(med.x, med.y, med.z))
  
  # trim a 2m square around the median position of all the points in the scan
  top <- med.y + 1
  right <- med.x + 1
  bottom <- med.y - 1
  left <- med.x - 1
  
  trimmed.las <- clip_rectangle(las, xleft = left, ybottom = bottom, xright = right, ytop = top)
  
  #plot(trimmed.las)
  
  # crop out the cieling
  ground.las <- filter_poi(trimmed.las, Z < 1)
  
  #plot(ground.las)
  
  # crop out the floor
  platform.las <- filter_poi(ground.las, Z > -1.4)
  
  #plot(platform.las)
  
  # classify noise points and trim them
  platform.las <- classify_noise(platform.las, sor(k=10, m=2))
  platform.las <- filter_poi(platform.las, Classification != 18)
  
  # write the cropped scan to a file in the output folder.
  cat("processing ", file.name)  
  if (grepl('_pre\\.las$', file.name)) {
    new.file.name <- sub("_pre\\.las$", "_autoclipped_pre.las", file.name)
  } else if (grepl('_post\\.las$', file.name)) {
    new.file.name <- sub("_post\\.las$", "_autoclipped_post.las", file.name)
  } else {
    new.file.name <- file.name
  }
  cat("stored as ", new.file.name)
  writeLAS(platform.las, file.path(output.folder, new.file.name))
}