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

# USER: set the location where the output should go (the cropped scans and the csv file will go to this folder.)
output.folder <- "C:/Users/js81535/Desktop/lidar_exploration/autoclipped_scans_for_analysis"

# grab data from the folder and csv file
input.file.names <- list.files(path = input.folder, full.names = FALSE)
input.data <- read.csv(input.csv)

# initialize output data frame
output.data <- data.frame(input.data)

output.data$min_height_pre <- NA
output.data$q1_height_pre <- NA
output.data$median_height_pre <- NA
output.data$q3_height_pre <- NA
output.data$max_height_pre <- NA
output.data$volume_pre <- NA
output.data$bulk_density_pre <- NA

output.data$min_height_post <- NA
output.data$q1_height_post <- NA
output.data$median_height_post <- NA
output.data$q3_height_post <- NA
output.data$max_height_post <- NA
output.data$volume_post <- NA
output.data$bulk_density_post <- NA

output.data$consumption_by_volume <- NA
output.data$consumption_by_mass <- NA






# loop through the raw pre and post files to crop them
all.files <- c(input.data$pre_file_name, input.data$post_file_name)

for (file.name in all.files) {
  # check that the file exists in the folder
  if (!file.exists(file.path(input.folder, file.name))) {
    cat("the file \'", file.name, "\' is not in the input folder.\nEnsure that the folder has pre and post burn .las files with names that match the ones in the pre_file_name and post_file_name columns of the input csv.\n")
    next
  }

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
  
  # crop out the ceiling
  ground.las <- filter_poi(trimmed.las, Z < 1)
  
  #plot(ground.las)
  
  # crop out the floor
  platform.las <- filter_poi(ground.las, Z > -1.4)
  
  #plot(platform.las)
  
  # write the cropped scan to a file in the output folder.
  cat("processing ", file.name, '...\n')  
  if (grepl('_pre\\.las$', file.name)) {
    new.file.name <- sub("_pre\\.las$", "_autoclipped_pre.las", file.name)
  } else if (grepl('_post\\.las$', file.name)) {
    new.file.name <- sub("_post\\.las$", "_autoclipped_post.las", file.name)
  } else {
    new.file.name <- file.name
  }
  cat("stored as ", new.file.name, '\n')
  writeLAS(platform.las, file.path(output.folder, new.file.name))
}






# define a function to find height distributions and volumes
find.hdv <- function(file.name, pre.post, output.row) {
  # load the scan
  las <- readLAS(file.path(output.folder, file.name))
  
  # classify noise points and trim them
  las <- classify_noise(las, sor(k=10, m=8))
  las <- filter_poi(las, Classification != 18)
  
  # classify ground and non-ground points
  mycsf <- csf(FALSE, class_threshold = 0.01, rigidness = 3, cloth_resolution = 0.9)
  las <- classify_ground(las, mycsf)
  
  # normalize heights from the ground
  norm.las <- normalize_height(las, tin())
  
  # find height distribution and add it to the output data frame
  fuel.points <- Filter(function(x) x > 0,  attributes(norm.las)$data$Z)
  min.height <- min(fuel.points)
  q1.height <- quantile(fuel.points, probs = 0.25, names=FALSE)[1]
  median.height <- median(fuel.points)
  q3.height <- quantile(fuel.points, probs = 0.75, names=FALSE)[1]
  max.height <- max(fuel.points)

  
  # rasterize the top of the fuel bed
  fuel.raster <- rasterize_canopy(norm.las, res = 0.004, algorithm = dsmtin())
  
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
  
  if (pre.post == 'pre') {
    output.data[output.row, "min_height_pre"] <<- min.height
    output.data[output.row, "q1_height_pre"] <<- q1.height
    output.data[output.row, "median_height_pre"] <<- median.height
    output.data[output.row, "q3_height_pre"] <<- q3.height
    output.data[output.row, "max_height_pre"] <<- max.height
    output.data[output.row, "volume_pre"] <<- total.volume
  } else if (pre.post == 'post') {
    output.data[output.row, "min_height_post"] <<- min.height
    output.data[output.row, "q1_height_post"] <<- q1.height
    output.data[output.row, "median_height_post"] <<- median.height
    output.data[output.row, "q3_height_post"] <<- q3.height
    output.data[output.row, "max_height_post"] <<- max.height
    output.data[output.row, "volume_post"] <<- total.volume
  }
  cat('...')
}

# find height distribution and volume for each file and add it to the output data frame
for (i in 1:nrow(input.data)) {
  # grab names from the input csv
  pre.name <- input.data[i, "pre_file_name"]
  post.name <- input.data[i, "post_file_name"]
  
  # update the names to match the new, processed scans
  pre.name <- sub("_pre\\.las$", "_autoclipped_pre.las", pre.name)
  post.name <- sub("_post\\.las$", "_autoclipped_post.las", post.name)
  
  # find height distributions and volumes and add them to the output data frame
  find.hdv(pre.name, 'pre', i)
  find.hdv(post.name, 'post', i)
}

# add bulk densities and consumption to the data frame
output.data$bulk_density_pre <- output.data$pre_mass / output.data$volume_pre
output.data$bulk_density_post <- output.data$post_mass / output.data$volume_post

output.data$consumption_by_volume <- ((output.data$volume_pre - output.data$volume_post) / output.data$volume_pre) * 100
output.data$consumption_by_mass <- ((output.data$pre_mass - output.data$post_mass) / output.data$pre_mass) * 100

# write the data to a csv file
write.csv(output.data, file.path(output.folder, "scans_data.csv"), row.names = FALSE)
cat("Your data can be found at \'", file.path(output.folder, "scans_data.csv"), "\'\n")


