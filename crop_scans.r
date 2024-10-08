require("lidR")

# load the scan
las <- readLAS("C:/Users/js81535/Desktop/lidar_exploration/dry_nocones_rep1_pre.las")
#las <- readLAS("C:/Users/js81535/Desktop/lidar_exploration/ambient_cones_rep2_post.las")

# find the median location of all the points in the scan
med.x <- median(las$X)
med.y <- median(las$Y)
med.z <- median(las$Z)

print(c(med.x, med.y, med.z))

# cut out a 2m square around the median location
top <- med.y + 1
right <- med.x + 1
bottom <- med.y - 1
left <- med.x - 1

trimmed.las <- clip_rectangle(las, xleft = left, ybottom = bottom, xright = right, ytop = top)

#plot(trimmed.las)

# crop out the cieling
ground.las <- filter_poi(trimmed.las, Z < 1)

plot(ground.las)

# crop out the floor
platform.las <- filter_poi(ground.las, Z > -1.4)

plot(platform.las)

# write the output to a new file
writeLAS(platform.las, "C:/Users/js81535/Desktop/lidar_exploration/my_new_las.las")