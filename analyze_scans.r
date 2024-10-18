# This program takes in a folder of raw pre- and post-burn .las files, along with a csv file with paired file 
# names and pre and post-burn masses. It outputs a folder of cropped, denoised, normalized scans and a csv file 
# with height distributions, volumes, bulk densities, consumption by volume, and consumption by mass.

require("lidR")

# USER: set the location of the input folder
# the input folder should be a folder of lidar scans
# all of the files in the input folder should end with "_pre.las" or "_post.las"
input.folder <- "C:/Users/js81535/Desktop/lidar_exploration/unclipped_scans/LAS files/"

# USER: set the location of the input csv. 
# the table should have columns for pre_file_name, post_file_name, pre_mass, and post_mass
# the table should have one row for each pre-burn/post-burn pair of scans in the input file
input.csv <- "C:/Users/js81535/Desktop/lidar_exploration/names_and_masses.csv"

# USER: set the location where the output should go
output.folder <- "C:/Users/js81535/Desktop/lidar_exploration/autoclipped_scans_for_analysis"

# the computer gets the information it needs from the folder and csv file
input.file.names <- list.files(path = input.folder, full.names = FALSE)
input.data <- read.csv(input.csv)


# loop through all of the files in the input folder to crop them
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



# find 

