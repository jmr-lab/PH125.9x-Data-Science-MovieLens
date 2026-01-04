#####################################################
###                  Introduction               ###
#####################################################

# Presentation of the problem, what we will be doing, what we want to achieve

#####################################################
###                  Presentation                 ###
#####################################################

# What the initial script provided in the course is doing: the data before and after transformation

#####################################################
###                  Data Analysis                ###
#####################################################

# Shw the edx data structure, present possible variables (user, movie, title, year, timestamp = day of week, day, month, year, hour and minute)
# temporary transform the data for further analysis (add columns and rows) if required
# Display number of unique users, movies, genres, years...

# Calculate average of ratings
# Show distribution of ratings less average
# show distribution is normal with mean 0 (should be) and calculate sd
library(ggplot2)
p <- ggplot(edx, aes(x = rating)) +
  geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30)
p + scale_color_brewer(palette="Accent") + 
  theme_minimal() + theme(legend.position = "top") +
  labs(title = "Variability", x = "rating")
mean(edx$rating)

# Calculate bias for users, movies and all variables
# Show distribution
# Explain why they need to be as close as possible from (y-mu)
# Select these ones for further analysis

# show correlations between variables and y-mu
# show correlation between variables

#####################################################
###                  Preditions.                  ###
#####################################################

# calculate predictions (lm, glm, gamLoess, knn and rf) based on variables selected before
# see if possible with computer

# prediction with mu + bi + ei

# calculate rmse for each method

# see how we can use multiple bias

#####################################################
###                  Conclusion                   ###
#####################################################
