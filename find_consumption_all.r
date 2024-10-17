require("lidR")

# the input to this program is a folder with pairs of pre- and post-burn scans.
# PAIRED SCANS NEED TO HAVE IDENTICAL NAMES WITH THE SUFFIXes "_pre.las" AND "_post.las"
# e.g. "my_las_scan_pre.las" and "my_las_scan_post.las"
# put the path to your input folder here:
input.folder <- "C:/Users/js81535/Desktop/lidar_exploration/auto_clipped_scans/"

# set the path and file name for the csv output to be saved to:
output.path <- 'C:/Users/js81535/Desktop/lidar_exploration/consumed_volume.csv'

# go through folder and find all the .las files ending in "_pre" and "_post"
input.file.names <- list.files(path=input.folder, pattern = "_((pre)|(post))\\.las$")     # only files with the correct suffix will be considered.
# print(input.file.names)

# check that all of the _pre files have matching _post files. 
# a warning message will appear if there are _pre files with missing _post files
for (name in input.file.names) {
  if (grepl("_pre\\.las$", name)) {
    matching.name <- sub("_pre\\.las$", "_post.las", name)
    if (!(matching.name %in% input.file.names)) {
      cat("the pre-burn scan \'", name, "\' does not have a matching post-burn scan!\n")
    }
  }
}

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

# initialize a dataframe to store the outputs
df <- data.frame(pre_file=character(), post_file=character(), percent_consumed=numeric(), stringsAsFactors = FALSE)

# loop through all of the pairs of scans in the folder
for (file in input.file.names) {
  
  if (grepl('_pre\\.las$', file)) {
  
    cat("processing", file, "...\n")
  
    # name pre and post burn scans
    matching.name <- sub("_pre\\.las$", "_post.las", file)
    preburn.file <- file.path(input.folder, file)
    postburn.file <- file.path(input.folder, matching.name)
    
    # read the scans (this will skip files that don't have a match)
    if (file.exists(postburn.file)) {
      preburn.scan <- readLAS(preburn.file)
      postburn.scan <- readLAS(postburn.file)
    }
    
    # find the volumes of pre- and post-burn scans
    pre.volume <- find_volume(preburn.scan)
    post.volume <- find_volume(postburn.scan)
    
    # find and print the percent-consumed by volume
    consumption.pct <- ((pre.volume - post.volume) / pre.volume) * 100
    
    cat("Percent Consumed by Volume in", file, ':', consumption.pct, '\n')
    
    # add the data as a row in the data frame
    new_row <- data.frame(pre_file = file, post_file = matching.name, percent_consumed = consumption.pct)
    df <- rbind(df, new_row)
    
  }
}

# write the output to a csv file
write.csv(df, file=output.path, row.names=FALSE)