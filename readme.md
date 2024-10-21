# Lidar Scan Manipulation and Measurement
This repository contains scripts for manipulating and measuring lidar scans of fire lab experiments. 

## Which program should I use?
| Script | Inputs | Outputs |
|--------|---------|--------|
|deluxe_lidar_analysis_package.r|a folder of raw scans (of the whole fire lab) and a csv file with columns for pre_file_name, post_file_name, pre_mass, and post_mass|a folder of cropped, denoised scans and a csv file with all of the input columns, plus min height, q1 height, median height, q3 height, max height, volume, and bulk density for both pre- and post- burn scans, as well as consumption by volume and consumption by mass|
|crop_scans.r|a raw scan of the whole fire lab|a cropped, denoised scan of only the platform and fuel bed|
|crop_all.r|a folder with raw scans of the whole fire lab|a folder with cropped, denoised scans of only the platform and the fuel bed|
|find_fuel_volume_and_height_distribution.r|a cropped scan of the platform and fuel bed|the height distribution of the fuel bed in a boxplot and the fuelbed volume printed to the console|
|find_consumption.r|a cropped preburn scan and a cropped postburn scan|the percent consumed by volume, printed to the console|
|find_consumption_all.r|a folder of matching, cropped pre and post burn scans|a csv file with the percent consumed, by volume, for each pair|
|find_bulk_density.r|a fuel mass and a corresponding cropped scan|the bulk density of the fuelbed, printed to the console|
