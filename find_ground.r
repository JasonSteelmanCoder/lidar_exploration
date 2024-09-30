require("lidR")


# load the scan
las <- readLAS("C:/Users/js81535/Desktop/lidar_exploration/compacted_dry_nocones_rep2_pre_clipped (1).las")
#las <- readLAS("C:/Users/js81535/Desktop/lidar_exploration/dry_nocones_rep2_post_clipped.las")


# classify ground and non-ground points
mycsf <- csf(FALSE, class_threshold = 0.009, rigidness = 3)
las <- classify_ground(las, mycsf)


# normalize heights from the ground and plot the scan
norm.las <- normalize_height(las, tin())

print(attributes(norm.las))

plot(norm.las, legend = TRUE, color = 'Z')


# find height distribution and plot it
fuel.points <- Filter(function(x) x > 0,  attributes(norm.las)$data$Z)

boxplot(x = fuel.points, main = 'Height Distribution of Fuel Bed',  ylab = "heights (m)")


# find the center of the fuel pile 
df = data.frame(attributes(norm.las)$data$Classification, attributes(norm.las)$data$X, attributes(norm.las)$data$Y, attributes(norm.las)$data$Z, attributes(norm.las)$data$Zref)
names(df) <- c("Classification", "X", "Y", "Z", "Zref")
fuel.df <- df[df$"Classification" == 0, ]

x.center <- median(fuel.df$X)
y.center <- median(fuel.df$Y)
print(x.center)
print(y.center)


# find points that are within 0.5m of the center of the fuel pile
fuel.df[["dist_from_ctr"]] <- sqrt((fuel.df$X - x.center)^2 + (fuel.df$Y - y.center)^2)
circle.df <- fuel.df[fuel.df$dist_from_ctr <= 0.5, ]


# estimate volume within 0.5m of the center of the fuel pile
median.height <- median(circle.df$Z)
print(median.height)

volume <- median.height * pi * 0.25
print(volume)


# make a tin of 

