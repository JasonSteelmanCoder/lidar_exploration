require("lidR")

# find the files in the input folder
input.folder <- "C:/Users/js81535/Desktop/lidar_exploration/unclipped_scans/LAS files/"
input.file.names <- list.files(path = input.folder, full.names = FALSE)

output.folder <- "C:/Users/js81535/Desktop/lidar_exploration/auto_clipped_scans"

for (file.name in input.file.names) {
  # load the scan
  las <- readLAS(file.path(input.folder, file.name))
  
  med.x <- median(las$X)
  med.y <- median(las$Y)
  med.z <- median(las$Z)
  
  print(c(med.x, med.y, med.z))
  
  top <- med.y + 1
  right <- med.x + 1
  bottom <- med.y - 1
  left <- med.x - 1
  
  trimmed.las <- clip_rectangle(las, xleft = left, ybottom = bottom, xright = right, ytop = top)
  
  #plot(trimmed.las)
  
  ground.las <- filter_poi(trimmed.las, Z < 1)
  
  #plot(ground.las)
  
  platform.las <- filter_poi(ground.las, Z > -1.4)
  
  #plot(platform.las)
  
  new.file.name <- sub("\\.las$", "_autoclipped.las", file.name)
  writeLAS(platform.las, file.path(output.folder, new.file.name))
}