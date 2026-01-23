#####################################################
###         Libraries                             ###
#####################################################

library(cowplot)
library(kableExtra)
library(scales)
library(akima)

#####################################################
###         Exploratory Data Analysis :           ###
###         Structure                             ###
#####################################################

# Stats for both edx (train) and final_holdout_test (test dataset) :
# Number of movies, users and ratings (rows)
data.frame(Dataset = c("edx", "final_holdout_test"),
           Type = c("Train", "Test"),
           Movies = c(comma(n_distinct(edx$movieId)), comma(n_distinct(final_holdout_test$movieId))),
           Users = c(comma(n_distinct(edx$userId)), comma(n_distinct(final_holdout_test$userId))),
           Ratings = c(comma(nrow(edx)), comma(nrow(final_holdout_test))))

#####################################################
###            Data Transformation                ###
#####################################################

# Top rows of the train dataset
# we may change the format to markdown
data_summary <- head(edx %>% select(userId, movieId,
                                    rating, timestamp,
                                    title, genres))

# Replace '|' with ';' in the genres column
data_summary$genres <- gsub("\\|", ";", data_summary$genres)
data_summary

# We add columns for the timestamp values (day of week, day, month, year and hour),
# and for the title and year of release :
edx_movies <- edx %>%
  mutate(
    # Convert timestamp to POSIXct (assuming it's in seconds)
    datetime = as.POSIXct(timestamp, origin = "1970-01-01", tz = "UTC"),
    t_day_of_week = ((wday(datetime) + 5) %% 7) + 1,                    # Numeric representation, Monday = 1...
    t_day = day(datetime),                                              # Day of the month
    t_month = month(datetime),                                          # Month (number)
    t_year = year(datetime),                                            # Year
    t_hour = hour(datetime),                                            # Hour
    year = as.integer(str_extract(title, "(?<=\\()\\d{4}(?=\\))")),     # Removes parentheses from the year
    title_without_year = str_remove(title, "\\s*\\(\\d{4}\\)")          # Removes year with parentheses from the title
  ) %>%
  select(-title, -timestamp, -datetime, -genres, genres) %>%
  rename(title = title_without_year)

# Top rows of the transformed train dataset
head(edx_movies %>% select(userId, movieId,
                           rating, t_day_of_week,
                           t_day, t_month,
                           t_year, t_hour,
                           title, year))

# Structure of the edx table : variables and stats
summary(edx)

# Structure of the final_holdout_test table : variables and stats
summary(final_holdout_test)

#####################################################
###             Data Analysis                     ###
#####################################################

# List of variables and number of distinct values
edx_movies %>%
  select(userId, movieId, t_day_of_week, t_day,
         t_month, t_year, t_hour, title, year, genres) %>%
  summarise(across(everything(), ~ n_distinct(.))) %>%
  pivot_longer(cols = everything(), names_to = "Variable", values_to = "Distinct_Count") %>%
  arrange(desc(Distinct_Count))

# Correlation between variables :
edx_movies_indexed <- edx_movies %>%
  mutate(
    userIndex = dense_rank(userId),
    movieIndex = dense_rank(movieId),
    genresIndex = as.numeric(factor(genres, levels = unique(genres)))
  ) %>%
  select(userIndex, movieIndex, rating, genresIndex, t_day_of_week, t_day, t_month, t_year, t_hour, year, movieId, title)
df_title <- edx_movies %>% select(movieId, title) %>% arrange(movieId) %>% distinct(movieId, title) %>%
  mutate(
    titleIndex = as.numeric(factor(title, levels = unique(title)))
  ) %>%
  select(-title)
edx_movies_indexed <- edx_movies_indexed %>%
  left_join(df_title, by="movieId")

# Calculate the correlation matrix for selected columns
correlation_matrix <- cor(edx_movies_indexed %>%
                            select(userId = userIndex,
                                   movieId = movieIndex,
                                   titleId = titleIndex,
                                   rating,
                                   genresId = genresIndex,
                                   t_daywk = t_day_of_week,
                                   t_day, t_month, t_year, t_hour, year))


# Plot the values of title_numeric against movieId :
#head(edx_movies_indexed)
#edx_movies_indexed %>% ggplot(mapping = aes(x = movieIndex, y = titleIndex)) +
#  geom_point(color = "darkblue") +
#  labs(x = "movieId", y = "title_numeric") +
#  theme_minimal() + theme(legend.position = "top")

# Remove unused variables
rm(edx_movies_indexed, df_title)

# Format the correlation coefficients
correlation_matrix <- round(correlation_matrix, 2)  # Round to 4 digits

# Move rating to the last row and last column
correlation_matrix <- cbind(correlation_matrix, 
                                      rating = correlation_matrix[, "rating"])
correlation_matrix <- rbind(correlation_matrix, 
                                      rating = correlation_matrix["rating", ])

# Remove the original rating column and row
correlation_matrix <- correlation_matrix[-4, -4]

# Remove values between -0.1 and 0.1
correlation_matrix[correlation_matrix < 0.1 & correlation_matrix > -0.1] <- ""

# View the correlation matrix
print(correlation_matrix)

# Keys

# We need to see which combination can be used for this exercise :
# obviously the couple movieId, userId will give the best outcome (RMSE = 0)
# but it won't help when used on the final_holdout_test dataset.

# Example of a multi-dimensional rating :
#df <- edx_movies %>% sample_n(50)
#scatterplot3d::scatterplot3d(df$userId, df$t_year, df$rating, color = df$movieId, pch = 16,
#                             grid = TRUE, box = FALSE, xlab = "User ID", 
#                             ylab = "Year", zlab = "Rating", zlim = c(0, 5))

# Step 1: Extract 1,000 distinct userIds
distinct_userIds <- edx_movies %>%
  distinct(userId) %>%
  sample_n(1000)

# Step 2: Extract 1,000 distinct movieIds
distinct_movieIds <- edx_movies %>%
  distinct(movieId) %>%
  sample_n(1000)

# Step 3: Filter edx_movies for the extracted userIds and movieIds
df <- edx_movies %>%
  filter(userId %in% distinct_userIds$userId, 
         movieId %in% distinct_movieIds$movieId) %>%
  select(userId, movieId, rating)

# View the filtered data (optional)
head(df)

# Define the values
x <- df$movieId
y <- df$userId
z <- df$rating

# Interpolate to get a grid of values
interp_data <- with(edx_movies, interp(x, y, z, linear = TRUE))

# Plot the interpolated surface
persp(interp_data$x, interp_data$y, interp_data$z, main = "Ratings", 
      xlab = "Movie ID", ylab = "User ID", zlab = "Rating",
      theta = 30, phi = 30, expand = 0.5, col = "lightblue",shade = 0.5,
      cex.main = 0.8, cex.lab = 0.8, cex.axis = 0.8)

rm(distinct_userIds, distinct_movieIds, df, x, y, z)

# Let's split the train dataset in 2 and count the number of unique rows for each couple :
# Calculate the number of rows in the dataset
num_rows <- nrow(edx_movies)
# Create a random sample of indices for the 90% dataset
train_indices <- sample(1:num_rows, size = 0.9 * num_rows)
# Create 90% training dataset
train_set <- edx_movies[train_indices, ]
# Create 10% testing dataset
test_set <- edx_movies[-train_indices, ]
# Remove num_rows and the indices
rm(num_rows, train_indices)

# Function to get number of rows in the final dataset for each combination :
get_nb_unique_rows <- function(combination) {
  unique_combinations <- anti_join(test_set, train_set, by = combination)
  # Return a data frame or tibble for the output
  return(tibble(
    Combination = paste(combination, collapse = ", "),
    `Nb Rows` = nrow(unique_combinations)
  ))
}

# All variables to be used :
variables <- c("userId", "movieId", "t_year", "year", "genres")

# Generate combinations of size 2
combinations_2d <- combn(variables, 2, simplify = FALSE)

# Apply the function to each combination and combine results into a tibble
unique_rows_2d <- bind_rows(lapply(combinations_2d, get_nb_unique_rows)) %>%
  arrange(desc(`Nb Rows`))

# Nb rows for the train_set :
nrow(test_set)

# We reformat the numbers to add a comma :
unique_rows_2d$`Nb Rows` <- prettyNum(unique_rows_2d$`Nb Rows`, big.mark = ",", scientific = FALSE)

# Nb rows in the test_set not in the train_set :
unique_rows_2d

# 3D combinations :

# Generate combinations of size 3
combinations_3d <- combn(variables, 3, simplify = FALSE)

# Apply the function to each combination and combine results into a tibble
unique_rows_3d <- bind_rows(lapply(combinations_3d, get_nb_unique_rows)) %>%
  arrange(desc(`Nb Rows`))

# Nb rows for the train_set :
nrow(test_set)

# We reformat the numbers to add a comma :
unique_rows_3d$`Nb Rows` <- prettyNum(unique_rows_3d$`Nb Rows`, big.mark = ",", scientific = FALSE)

# Nb rows in the test_set not in the train_set :
unique_rows_3d

# List of movies with number of ratings,
# the list is sorted by number of ratings (descending)
list_movies <- edx_movies %>% group_by(movieId, title, year, genres) %>%
  summarize(count = n()) %>%
  arrange(desc(count)) %>%
  ungroup()

# We don't need the movieId, but an index so we can create a plot :
list_movies$index <- 1:nrow(list_movies)
list_movies <- list_movies %>% select(index, title, year, genres, count)

# Top 5 movies with the highest number of ratings.
# We need to reformat the year as character so it is not displayed with a comma (1,994)
top_n(
  list_movies %>% mutate(year = as.character(year)) %>% select(index, title, year, count),
  5, count)

# Plot the movies :
# the figure on the left shows the number of ratings per movie (descending),
# the figure on the right is the same but a log10 transformation is applied to the y axis (number of ratings) :
plot_grid(
  list_movies %>% sample_n(1000) %>% ggplot(aes(x = index, y = count)) +
    geom_area(color = "darkblue", fill="darkblue", alpha = 0.1) +
    theme_minimal() +
    labs(x = "MovieId", y = "Count"),
  list_movies %>% sample_n(1000) %>% ggplot(aes(x = index, y = count)) +
    geom_area(color = "darkblue", fill="darkblue", alpha = 0.1) +
    theme_minimal() +
    labs(x = "MovieId", y = "Count (log10)") +
    scale_y_log10(),
  ncol = 2)

# Number of movies released per year, and number of ratings given to movies, per year :
plot_grid(
  list_movies %>%
    group_by(year) %>%
    summarise(total_movies = n()) %>%
    ggplot(aes(x = year, y = total_movies)) +
    geom_bar(stat = "identity", fill="darkblue", alpha = 0.8) +
    labs(x = "Year", y = "Total Movies") +
    theme_minimal(),
  list_movies %>%
    ggplot(aes(x = year, y = count)) +
    geom_bar(stat = "identity", fill="darkblue", alpha = 0.8) +
    scale_y_continuous(labels = label_number(scale = 1e-3, suffix = "k")) +
    labs(x = "Year Movie Released", y = "Ratings") +
    theme_minimal(),
  ncol = 2)

# Number of Ratings per Movie per year of release,
# and number of ratings per age of movie (difference between the timestamp year and the year of release) :
plot_grid(
  edx_movies %>%
    group_by(year) %>%
    summarize(ratio = n() / n_distinct(movieId)) %>%
    arrange(year) %>%
    ungroup() %>%
    ggplot(aes(x = year, y = ratio)) +
    geom_bar(stat = "identity", fill="darkblue", alpha = 0.8) +
    labs(x = "Year", y = "Nb Ratings per Movie") +
    theme_minimal(),
  edx_movies %>%
    mutate(age = t_year - year) %>%
    group_by(age) %>%
    summarize(count = n()) %>%
    arrange(desc(count)) %>%
    ungroup() %>%
    ggplot(aes(x = age, y = count)) +
    geom_bar(stat = "identity", fill="darkblue", alpha = 0.8) +
    scale_y_continuous(labels = label_number(scale = 1e-3, suffix = "k")) +
    labs(x = "Movie Age", y = "Ratings") +
    theme_minimal(),
  ncol = 2)

# List of users with number of ratings given,
# the list is sorted by number of ratings (descending)
list_users <- edx_movies %>% group_by(userId) %>%
  summarize(count = n()) %>%
  arrange(desc(count)) %>%
  ungroup()

# As for the movies, we don't need the userId, but an index so we can create a plot :
list_users$index <- 1:nrow(list_users)
list_users <- list_users %>% select(index, count)

# Top 5 users with the highest number of ratings :
top_n(list_users, 5, count)

# Number of ratings given per user :
# the figure on the left shows the number of ratings per user (descending),
# the figure on the right is the same but a log10 transformation is applied to the y axis (number of ratings) :
plot_grid(
  list_users %>% sample_n(1000) %>% ggplot(aes(x = index, y = count)) +
    geom_area(color = "darkgreen", fill="darkgreen", alpha = 0.1) +
    theme_minimal() +
    labs(x = "User", y = "Count"),
  list_users %>% sample_n(1000) %>% ggplot(aes(x = index, y = count)) +
    geom_area(color = "darkgreen", fill="darkgreen", alpha = 0.1) +
    theme_minimal() +
    labs(x = "User", y = "Count (log10)") +
    scale_y_log10(),
  ncol = 2)

# Genres :
head(edx_movies %>% select(userId, rating, title, year, genres))

# Get a list of all genres with their number of ratings, average, min and max rating :
list_genres <- edx_movies %>%
  group_by(genres) %>%
  summarize(
    count_ratings = n(),
    average_rating = mean(rating),
    min_rating = min(rating),
    max_rating = max(rating),
    .groups = 'drop') %>%
  separate_rows(genres, sep = "\\|") %>%
  group_by(genres) %>%
  summarize(
    count = sum(count_ratings),
    overall_average_rating = sum(average_rating * count_ratings) / sum(count_ratings),
    min_rating = min(min_rating),
    max_rating = max(max_rating),
    .groups = 'drop')

# List of genres :
paste(c(list_genres$genres[!list_genres$genres %in% "(no genres listed)"],
             list_genres$genres[list_genres$genres == "(no genres listed)"]), collapse = ", ")

# Plot the number of ratings per genre (separated) :
list_genres %>%
  arrange(desc(count)) %>%
  mutate(genres = factor(genres, levels = genres)) %>%
  ggplot(aes(x = genres, y = count)) +
  geom_bar(stat = "identity", fill="darkcyan", alpha = 0.8) +
  scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "M")) +
  labs(x = "Genre", y = "Ratings") +
  theme_minimal() + theme(axis.text.x = element_text(angle = 90, hjust = 1))

# Plot the number of ratings per genre (combined), and the cumulative percentage :
plot_grid(
  edx_movies %>%
    group_by(genres) %>%
    summarize(
      count = n(),
      average_rating = mean(rating),
      min_rating = min(rating),
      max_rating = max(rating),
      .groups = 'drop') %>%
    arrange(desc(count)) %>%
    mutate(index = row_number()) %>%
    ggplot(aes(x = index, y = count)) +
    geom_bar(stat = "identity", fill="darkcyan", alpha = 0.8) +
    scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "M")) +
    labs(x = "Genre ID (combination)", y = "Ratings") +
    theme_minimal() + theme(legend.position = "top", legend.justification = c(0.5, 0), text = element_text(size = 9)),
  
  edx_movies %>%
    group_by(genres) %>%
    summarize(
      count = n(),
      average_rating = mean(rating),
      min_rating = min(rating),
      max_rating = max(rating),
      .groups = 'drop') %>%
    arrange(desc(count)) %>%
    mutate(index = row_number(),
           percentage = (count / sum(count)) * 100) %>%
    mutate(cumulative_count = cumsum(count),
           total_count = sum(count),
           cumulative_percentage = (cumulative_count / total_count) * 100) %>%
    ggplot(aes(x = index, y = cumulative_percentage)) +
    geom_area(color = "darkcyan", fill="darkcyan", alpha = 0.1) +
    scale_y_continuous(
      labels = label_number(scale = 1, suffix = "%"),  # Scale for percentage labels
      breaks = seq(0, 100, by = 10)) +
    labs(x = "Genre ID (combination)", y = "Cumulative percentage of Ratings") +
    theme_minimal() + theme(legend.position = "top", legend.justification = c(0.5, 0), text = element_text(size = 9)),
  
  ncol = 2)

# Plot the number of ratings per movie and per genre (combined) per year :
edx_movies %>%
  group_by(year, movieId, genres) %>%
  summarize(
    count_ratings = n(),
    .groups = 'drop') %>%
  separate_rows(genres, sep = "\\|") %>%
  group_by(year, genres) %>%
  summarize(
    count = sum(count_ratings),
    ratings = sum(count_ratings) / n(),
    .groups = 'drop') %>%
  #  filter(genres %in% c("Animation", "Children", "Fantasy", "Mystery")) %>%
  ggplot(aes(x = year, y = ratings, color = genres)) +
  geom_smooth(se = FALSE, method = "loess", size = 1, formula = y ~ x) +
  labs(x = "Year", y = "Number of Ratings per movie") +
  scale_y_continuous(labels = label_number(scale = 1e-3, suffix = "k")) +
  theme_minimal() + theme(text = element_text(size = 8), legend.position = "bottom", legend.key.size = unit(0.1, "cm"))

# Plot the number of ratings per genre (combined) per year :
edx_movies %>%
  group_by(year, genres) %>%
  summarize(
    count_ratings = n(),
    .groups = 'drop') %>%
  separate_rows(genres, sep = "\\|") %>%
  group_by(year, genres) %>%
  summarize(
    count = sum(count_ratings),
    .groups = 'drop') %>%
  ggplot(aes(x = year, y = count, color = genres)) +
  geom_smooth(se = FALSE, method = "loess", size = 1, formula = y ~ x) +
  labs(x = "Year", y = "Number of Ratings") +
  scale_y_continuous(labels = label_number(scale = 1e-3, suffix = "k")) +
  theme_minimal() + theme(text = element_text(size = 8), legend.position = "bottom", legend.key.size = unit(0.1, "cm"))

# Timestamp :

# Number of ratings per month-year : total and per movie, user, genres and year of release
plot_grid(
  edx_movies %>%
    group_by(t_year, t_month) %>%
    summarise(count = n(), .groups = 'drop') %>%
    mutate(year_month = as.Date(paste(t_year, t_month, "01", sep = "-"))) %>%
    ggplot(aes(x = year_month, y = count)) +
    geom_area(color = "black", fill="black", alpha = 0.1) +
    labs(title = "Total",x = "Timestamp", y = "Number of Ratings") +
    scale_y_continuous(labels = label_number(scale = 1e-3, suffix = "k")) +
    theme_minimal() + theme(legend.position = "top", legend.justification = c(0.5, 0), text = element_text(size = 9)),

  edx_movies %>%
    group_by(t_year, t_month) %>%
    summarise(count = n_distinct(movieId), .groups = 'drop') %>%
    mutate(year_month = as.Date(paste(t_year, t_month, "01", sep = "-"))) %>%
    ggplot(aes(x = year_month, y = count)) +
    geom_area(color = "darkblue", fill="darkblue", alpha = 0.1) +
    labs(title = "Movies",x = "Timestamp", y = "Number of Ratings") +
    theme_minimal() + theme(legend.position = "top", legend.justification = c(0.5, 0), text = element_text(size = 9)),

  edx_movies %>%
    group_by(t_year, t_month) %>%
    summarise(count = n_distinct(userId), .groups = 'drop') %>%
    mutate(year_month = as.Date(paste(t_year, t_month, "01", sep = "-"))) %>%
    ggplot(aes(x = year_month, y = count)) +
    geom_area(color = "darkgreen", fill="darkgreen", alpha = 0.1) +
    labs(title = "Users",x = "Timestamp", y = "Number of Ratings") +
    theme_minimal() + theme(legend.position = "top", legend.justification = c(0.5, 0), text = element_text(size = 9)),

  edx_movies %>%
    group_by(t_year, t_month) %>%
    summarise(count = n_distinct(genres), .groups = 'drop') %>%
    mutate(year_month = as.Date(paste(t_year, t_month, "01", sep = "-"))) %>%
    ggplot(aes(x = year_month, y = count)) +
    geom_area(color = "darkcyan", fill="darkcyan", alpha = 0.1) +
    labs(title = "Genres",x = "Timestamp", y = "Number of Ratings") +
    theme_minimal() + theme(legend.position = "top", legend.justification = c(0.5, 0), text = element_text(size = 9)),

  edx_movies %>%
    group_by(t_year, t_month) %>%
    summarise(count = n_distinct(year), .groups = 'drop') %>%
    mutate(year_month = as.Date(paste(t_year, t_month, "01", sep = "-"))) %>%
    ggplot(aes(x = year_month, y = count)) +
    geom_area(color = "orange", fill="orange", alpha = 0.1) +
    labs(title = "Year of Release",x = "Timestamp", y = "Number of Ratings") +
    theme_minimal() + theme(legend.position = "top", legend.justification = c(0.5, 0), text = element_text(size = 9)),
  
ncol = 2)


# Distribution of Ratings.
# If we round the ratings, we see that the distribution is approximately normal :
plot_grid(
  ggplot(edx_movies, aes(x = rating)) +
    geom_histogram(fill="darkred", alpha = 0.8, position="dodge", bins = 30) +
    scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "M")) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Rating", y = "Count"),
  ggplot(edx_movies, aes(x = floor(rating))) +
    geom_histogram(fill="darkred", alpha = 0.8, position="dodge", bins = 30) +
    scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "M")) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Rating (Rounded)", y = "Count"),
  ncol = 2)

# Average and standard deviation
n <- nrow(edx)
mu <- mean(edx$rating)
sd <- sd(edx$rating)
data.frame(Type = c("Average", "Standard Deviation"),
           Value = c(mu, sd))

# Distribution of average ratings per variable.
# We now consider variables with low number of distinct values :
# timestamp information and year of release.

# Average rating per day of week
avg_rating_per_day_of_week <- edx_movies %>%
  group_by(t_day_of_week) %>%
  summarise(
    min_rating = min(rating),
    max_rating = max(rating),
    avg_rating = mean(rating)) %>%
  ungroup()
head(avg_rating_per_day_of_week)

# Average rating per day
avg_rating_per_day <- edx_movies %>%
  group_by(t_day) %>%
  summarise(
    min_rating = min(rating),
    max_rating = max(rating),
    avg_rating = mean(rating)) %>%
  ungroup()
head(avg_rating_per_day)

# Average rating per month
avg_rating_per_month <- edx_movies %>%
  group_by(t_month) %>%
  summarise(
    min_rating = min(rating),
    max_rating = max(rating),
    avg_rating = mean(rating)) %>%
  ungroup()
head(avg_rating_per_month)

# Average rating per year (timestamp)
avg_rating_per_t_year <- edx_movies %>%
  group_by(t_year) %>%
  summarise(
    min_rating = min(rating),
    max_rating = max(rating),
    avg_rating = mean(rating)) %>%
  ungroup()
head(avg_rating_per_t_year)

# Average rating per hour
avg_rating_per_hour <- edx_movies %>%
  group_by(t_hour) %>%
  summarise(
    min_rating = min(rating),
    max_rating = max(rating),
    avg_rating = mean(rating)) %>%
  ungroup()
head(avg_rating_per_hour)

# Average rating per year (release)
avg_rating_per_year <- edx_movies %>%
  group_by(year) %>%
  summarise(
    min_rating = min(rating),
    max_rating = max(rating),
    avg_rating = mean(rating)) %>%
  ungroup()
head(avg_rating_per_year)

# We plot the six graphs :
plot_grid(
  ggplot(avg_rating_per_day_of_week, aes(x = t_day_of_week)) +
    geom_ribbon(aes(ymin = min_rating, ymax = max_rating), fill = "darkred", alpha = 0.2) +
    geom_line(aes(y = min_rating), color = "darkred", linetype = "solid") +
    geom_line(aes(y = max_rating), color = "darkred", linetype = "solid") +
    geom_line(aes(y = avg_rating), color = "darkred", size = 1.2, linetype = "solid") +
    labs(x = "Day of the Week", y = "Rating") +
    scale_y_continuous(limits = c(0, 5)) +
    theme_minimal(),
  
  ggplot(avg_rating_per_day, aes(x = t_day)) +
    geom_ribbon(aes(ymin = min_rating, ymax = max_rating), fill = "darkred", alpha = 0.2) +
    geom_line(aes(y = min_rating), color = "darkred", linetype = "solid") +
    geom_line(aes(y = max_rating), color = "darkred", linetype = "solid") +
    geom_line(aes(y = avg_rating), color = "darkred", size = 1.2, linetype = "solid") +
    labs(x = "Day", y = "Rating") +
    scale_y_continuous(limits = c(0, 5)) +
    theme_minimal(),
  
  ggplot(avg_rating_per_month, aes(x = t_month)) +
    geom_ribbon(aes(ymin = min_rating, ymax = max_rating), fill = "darkred", alpha = 0.2) +
    geom_line(aes(y = min_rating), color = "darkred", linetype = "solid") +
    geom_line(aes(y = max_rating), color = "darkred", linetype = "solid") +
    geom_line(aes(y = avg_rating), color = "darkred", size = 1.2, linetype = "solid") +
    labs(x = "Month", y = "Rating") +
    scale_y_continuous(limits = c(0, 5)) +
    theme_minimal(),
  
  ggplot(avg_rating_per_t_year, aes(x = t_year)) +
    geom_ribbon(aes(ymin = min_rating, ymax = max_rating), fill = "darkred", alpha = 0.2) +
    geom_line(aes(y = min_rating), color = "darkred", linetype = "solid") +
    geom_line(aes(y = max_rating), color = "darkred", linetype = "solid") +
    geom_line(aes(y = avg_rating), color = "darkred", size = 1.2, linetype = "solid") +
    labs(x = "Year (timestamp)", y = "Rating") +
    scale_y_continuous(limits = c(0, 5)) +
    theme_minimal(),
  
  ggplot(avg_rating_per_hour, aes(x = t_hour)) +
    geom_ribbon(aes(ymin = min_rating, ymax = max_rating), fill = "darkred", alpha = 0.2) +
    geom_line(aes(y = min_rating), color = "darkred", linetype = "solid") +
    geom_line(aes(y = max_rating), color = "darkred", linetype = "solid") +
    geom_line(aes(y = avg_rating), color = "darkred", size = 1.2, linetype = "solid") +
    labs(x = "Hour", y = "Rating") +
    scale_y_continuous(limits = c(0, 5)) +
    theme_minimal(),
  
  ggplot(avg_rating_per_year, aes(x = year)) +
    geom_ribbon(aes(ymin = min_rating, ymax = max_rating), fill = "darkred", alpha = 0.2) +
    geom_line(aes(y = min_rating), color = "darkred", linetype = "solid") +
    geom_line(aes(y = max_rating), color = "darkred", linetype = "solid") +
    geom_line(aes(y = avg_rating), color = "darkred", size = 1.2, linetype = "solid") +
    labs(x = "Year (release)", y = "Rating") +
    scale_y_continuous(limits = c(0, 5)) +
    theme_minimal(),
  
  ncol = 3, align = 'hv', rel_heights = c(2, 2, 2))

# Distribution of average ratings per variable.
# We only consider variables with enough distinct values :
# userId (69,878), movieId (10,677), title (10,407) and genres (797)

# Average rating per user
avg_rating_per_user <- edx_movies %>%
  group_by(userId) %>%
  summarise(avg_rating = mean(rating)) %>%
  ungroup() %>%
  mutate(source = "User")
head(avg_rating_per_user)

# Average rating per movie
avg_rating_per_movie <- edx_movies %>%
  group_by(movieId) %>%
  summarise(avg_rating = mean(rating)) %>%
  ungroup() %>%
  mutate(source = "Movie")
head(avg_rating_per_movie)

# Average rating per genres
avg_rating_per_genres <- edx_movies %>%
  group_by(genres) %>%
  summarise(avg_rating = mean(rating)) %>%
  ungroup() %>%
  mutate(source = "Genres")
head(avg_rating_per_genres)

# Average rating per year
#avg_rating_per_year <- edx_movies %>%
#  group_by(year) %>%
#  summarise(avg_rating = mean(rating)) %>%
#  ungroup() %>%
#  mutate(source = "Year")
#head(avg_rating_per_year)

# Average rating per t_month_year
# We add a column t_month_year :
edx_movies <- edx_movies %>%
  mutate(t_month_year = as.Date(paste(t_year, t_month, "01", sep = "-")))
avg_rating_per_t_month_year <- edx_movies %>%
  group_by(t_month_year) %>%
  summarise(avg_rating = mean(rating), .groups = 'drop') %>%
  mutate(source = "T Month Year")

# We plot the five graphs :
plot_grid(
  ggplot(avg_rating_per_user, aes(x = avg_rating)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top", legend.justification = c(0.5, 0), text = element_text(size = 9)) +
    labs(x = "Rating", y = "Users"),
  
  ggplot(avg_rating_per_movie, aes(x = avg_rating)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top", legend.justification = c(0.5, 0), text = element_text(size = 9)) +
    labs(x = "Rating", y = "Movies"),
  
  ggplot(avg_rating_per_genres, aes(x = avg_rating)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top", legend.justification = c(0.5, 0), text = element_text(size = 9)) +
    labs(x = "Rating", y = "Genres"),
  
  ggplot(avg_rating_per_year, aes(x = avg_rating)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top", legend.justification = c(0.5, 0), text = element_text(size = 9)) +
    labs(x = "Rating", y = "Year"),

  ggplot(avg_rating_per_t_month_year, aes(x = avg_rating)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top", legend.justification = c(0.5, 0), text = element_text(size = 9)) +
    labs(x = "Rating", y = "T Month Year"),
  
  ncol = 2, align = 'hv', rel_heights = c(2, 2, 2))

# Calculate rating percentages for the edx dataset
edx_movies_summarized <- edx_movies %>%
  group_by(rating = floor(rating)) %>%
  summarize(percentage = n() / nrow(edx_movies) * 100)

# Comparison with rating distribution :
plot_grid(
  ggplot() +
    geom_histogram(data = avg_rating_per_user, aes(x = avg_rating, y = after_stat(count) / sum(after_stat(count)) * 100), 
                   color = "darkred", fill = "darkred", alpha = 0.1, position = "dodge", bins = 10) +
    geom_line(data = edx_movies_summarized, aes(x = rating, y = percentage), color = "darkred", size = 1, linetype = "dashed") +
    scale_color_brewer(palette = "Accent") + 
    theme_minimal() + 
    theme(legend.position = "top", legend.justification = c(0.5, 0), text = element_text(size = 9)) +
    labs(x = "Rating", y = "User") +
    scale_y_continuous(labels = percent_format(scale = 1)) +
    scale_x_continuous(breaks = seq(1, 5, 1)),
  
  ggplot() +
    geom_histogram(data = avg_rating_per_movie, aes(x = avg_rating, y = after_stat(count) / sum(after_stat(count)) * 100), 
                   color = "darkred", fill = "darkred", alpha = 0.1, position = "dodge", bins = 10) +
    geom_line(data = edx_movies_summarized, aes(x = rating, y = percentage), color = "darkred", size = 1, linetype = "dashed") +
    scale_color_brewer(palette = "Accent") + 
    theme_minimal() + 
    theme(legend.position = "top", legend.justification = c(0.5, 0), text = element_text(size = 9)) +
    labs(x = "Rating", y = "Movie") +
    scale_y_continuous(labels = percent_format(scale = 1)) +
    scale_x_continuous(breaks = seq(1, 5, 1)),
  
  ggplot() +
    geom_histogram(data = avg_rating_per_genres, aes(x = avg_rating, y = after_stat(count) / sum(after_stat(count)) * 100), 
                   color = "darkred", fill = "darkred", alpha = 0.1, position = "dodge", bins = 10) +
    geom_line(data = edx_movies_summarized, aes(x = rating, y = percentage), color = "darkred", size = 1, linetype = "dashed") +
    scale_color_brewer(palette = "Accent") + 
    theme_minimal() + 
    theme(legend.position = "top", legend.justification = c(0.5, 0), text = element_text(size = 9)) +
    labs(x = "Rating", y = "Genres") +
    scale_y_continuous(labels = percent_format(scale = 1)) +
    scale_x_continuous(breaks = seq(1, 5, 1)),
  
  ggplot() +
    geom_histogram(data = avg_rating_per_t_month_year, aes(x = avg_rating, y = after_stat(count) / sum(after_stat(count)) * 100), 
                   color = "darkred", fill = "darkred", alpha = 0.1, position = "dodge", bins = 10) +
    geom_line(data = edx_movies_summarized, aes(x = rating, y = percentage), color = "darkred", size = 1, linetype = "dashed") +
    scale_color_brewer(palette = "Accent") + 
    theme_minimal() + 
    theme(legend.position = "top", legend.justification = c(0.5, 0), text = element_text(size = 9)) +
    labs(x = "Rating", y = "T Month Year") +
    scale_y_continuous(labels = percent_format(scale = 1)) +
    scale_x_continuous(breaks = seq(1, 5, 1)),
  
  ncol = 2, align = 'hv', rel_heights = c(2, 2, 2))

# Distribution of Average rating per couple of variables :

# List of variable combinations
group_vars <- list(
  c("movieId", "t_year"),
  c("userId", "t_year"),
  c("t_year", "genres"),
  c("movieId", "year"),
  c("movieId", "genres"),
  c("year", "genres"),
  c("t_year", "year"),
  c("movieId", "t_year", "year"),
  c("movieId", "t_year", "genres"),
  c("t_year", "year", "genres"),
  c("movieId", "year", "genres")
)

# Initialize a list to store plots
plot_list <- list()

# Iterate over each group of variables
for (vars in group_vars) {
  # Create a dynamic variable name using `paste`
  var_str <- paste(vars, collapse = ", ")
  
  # Group by dynamic variables and create the plot
  p <- edx_movies %>%
    group_by(across(all_of(vars))) %>%
    summarise(avg_rating = mean(rating, na.rm = TRUE), .groups = 'drop') %>%
    ggplot(aes(x = avg_rating)) +
    geom_histogram(aes(x = avg_rating, y = after_stat(count) / sum(after_stat(count)) * 100),
                   color = "darkred", fill = "darkred", alpha = 0.1, position = "dodge", bins = 10) +
    geom_line(data = edx_movies_summarized, aes(x = rating, y = percentage), color = "darkred", size = 1, linetype = "dashed") +
    scale_color_brewer(palette = "Accent") + 
    theme_minimal() + 
    theme(legend.position = "top", 
          legend.justification = c(0.5, 0), 
          text = element_text(size = 9),
          plot.title = element_text(size = 10)) +
    labs(x = "Rating", y = "Percent") +
    ggtitle(var_str)

  plot_list[[length(plot_list) + 1]] <- p  # Store each plot in the list
}

# Display all plots in a grid layout (3 plots per row)
plot_grid(plotlist = plot_list, ncol = 3)

#####################################################
###             Predictions                       ###
#####################################################

# RMSE function
RMSE <- function(ratings, predictions) {
  sqrt(mean((predictions - ratings)^2))
}

# Results table, add a target of 0.86490
results <- tibble(Type = character(), RMSE = numeric())
results <- results %>% add_row(Type = "Target", RMSE = 0.86490)

# Before starting, we need to check if a linear regression is possible with this large dataset (edx_movies).
# With movieId and userId, the RMSE is 1.060306 :
linear_model <- lm(rating ~ movieId + userId, data = edx_movies)
predictions <- predict(linear_model, newdata = edx_movies)
RMSE(edx_movies$rating, predictions)

# Adding a third variable will result in a memory error :
# Error: cannot allocate vector of size 53.6 Gb
# linear_model <- lm(rating ~ userId + movieId + genres, data = edx_movies)

# Random Forest model will also result in a memory error :
# Error: cannot allocate vector of size 33.5 Gb
# library(randomForest)
# rf_model <- randomForest(rating ~ movieId + userId, data = edx_movies)
# predictions <- predict(rf_model, newdata = edx_movies)

# Remove linear_model and predictions :
rm(linear_model, predictions)

# Try 1 : we predict the average value

# RMSE for the average : 1.060331
RMSE(edx$rating, mu)
results <- results %>% add_row(Type = "Average", RMSE = RMSE(edx$rating, mu))

# Ratings (10,000 samples) with average value and
# Distribution of the error if we predict the average value (constant) :
plot_grid(
  edx_movies %>% select(rating) %>% sample_n(10000) %>% arrange(desc(rating)) %>%
    mutate(index = row_number()) %>%
    ggplot(aes(x = index, y = rating)) +
    geom_area(color = "darkred", fill="darkred", alpha = 0.1) +
    geom_hline(yintercept = mu, color = "orange", linetype = "dashed", size = 1) +
    theme_minimal() +
    labs(x = "Index", y = "Rating"),
  
  ggplot(edx_movies, aes(x = rating - mu)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "M")) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Error", y = "Number of Ratings"),
  
  ncol = 2, align = 'hv', rel_heights = c(2, 2))

# Try 2 : we predict a random value with same average as mu
# May not be the best idea
#edx_movies$pred <- rnorm(n, mean = mu, sd = sd)
#head(edx_movies)
#ggplot(edx_movies, aes(x = rating - pred)) +
#  geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
#  scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "M")) +
#  scale_color_brewer(palette="Accent") + 
#  theme_minimal() + theme(legend.position = "top") +
#  labs(x = "Error (average)", y = "Number of Ratings")

# RMSE for random values : 1.499818
# We don't save it in the results table as it is above the baseline value.
#RMSE(edx_movies$rating, edx_movies$pred)

# We could reduce further the RMSE by replacing negative predictions with 0,
# and the ones above 5 by 5, but it won't change much :
# the result will still be above the baseline RMSE : 1.449352
#edx_movies <- edx_movies %>%
#  mutate(pred = case_when(
#    pred < 0 ~ 0,
#    pred > 5 ~ 5,
#    TRUE ~ pred
#  ))
#RMSE(edx_movies$rating, edx_movies$pred)

# We remove the random pred from the data frame
#edx_movies <- edx_movies %>% select(-pred)

# Try 3 : we introduce a bias for movies, users and genres.
# Note that these biases are independent for each other

# Explanation of the bias :
# Step 1: Select 3 unique movie IDs randomly
selected_movies <- edx_movies %>%
  distinct(movieId) %>%
  sample_n(3)

# Step 2: Filter and select up to 100 ratings for each selected movie
selected_ratings <- edx_movies %>%
  filter(movieId %in% selected_movies$movieId) %>%
  group_by(movieId) %>%
  slice_sample(n = 50, replace = TRUE) %>%
  arrange(movieId) %>%
  mutate(average_rating = mean(rating)) %>%
  ungroup() %>%
  mutate(index = row_number()) %>%
  select(index, movieId, rating, average_rating)

# Create a data frame for the segments
lines_data <- selected_ratings %>%
  group_by(movieId) %>%
  summarise(avg_rating = mean(rating),
            x_start = min(index),
            x_end = max(index))

# Create the base plot and add horizontal lines for the average rating,
# constrained to the respective index range
ggplot(selected_ratings, aes(x = index, y = rating, color = as.factor(movieId))) +
  geom_point(size = 1) +
  labs(x = "Index", y = "Rating") +
  theme_minimal() +
  theme(text = element_text(size = 9), legend.position = "none") +
  geom_segment(data = lines_data, 
               aes(x = x_start, xend = x_end, y = avg_rating, yend = avg_rating, color = as.factor(movieId)),
               linetype = "solid", size = 2) +
  geom_hline(yintercept = mu, color = "orange", linetype = "dashed", size = 1)

# Remove unused variables
rm(selected_movies)

# Movie bias
b_m <- edx_movies %>%
  group_by(movieId) %>%
  summarise(b_m = mean(rating - mu))
head(b_m)
edx_movies <- edx_movies %>% left_join(b_m, by = "movieId")
head(edx_movies)

# User bias
b_u <- edx_movies %>%
  group_by(userId) %>%
  summarise(b_u = mean(rating - mu))
head(b_u)
edx_movies <- edx_movies %>% left_join(b_u, by = "userId")
head(edx_movies)

# Genres bias
b_g <- edx_movies %>%
  group_by(genres) %>%
  summarise(b_g = mean(rating - mu))
head(b_g)
edx_movies <- edx_movies %>% left_join(b_g, by = "genres")
head(edx_movies)

# Year (timestamp) bias
#b_ty <- edx_movies %>%
#  group_by(t_year) %>%
#  summarise(b_ty = mean(rating - mu))
#head(b_ty)
#edx_movies <- edx_movies %>% left_join(b_ty, by = "t_year")
#head(edx_movies)

# Year (release) bias
#b_y <- edx_movies %>%
#  group_by(year) %>%
#  summarise(b_y = mean(rating - mu))
#head(b_y)
#edx_movies <- edx_movies %>% left_join(b_y, by = "year")
#head(edx_movies)

# Add the movie and user RMSE values to the results table :
results <- results %>% add_row(Type = "Movie", RMSE = RMSE(edx$rating, mu + edx_movies$b_m))
results <- results %>% add_row(Type = "User", RMSE = RMSE(edx$rating, mu + edx_movies$b_u))
results <- results %>% add_row(Type = "Genres", RMSE = RMSE(edx$rating, mu + edx_movies$b_g))
#results <- results %>% add_row(Type = "Year (timestamp)", RMSE = RMSE(edx$rating, mu + edx_movies$b_ty))
#results <- results %>% add_row(Type = "Year (release)", RMSE = RMSE(edx$rating, mu + edx_movies$b_y))

# Display the RMSEs :
results %>%
  filter(Type %in% c("Target", "Average", "Movie", "User", "Genres"))

# Distribution of the error for the bias :
plot_grid(
  ggplot(edx_movies, aes(x = rating - mu - b_m)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "M")) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Error", y = "Movie"),
  
  ggplot(edx_movies, aes(x = rating - mu - b_u)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "M")) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Error", y = "User"),
  
  ggplot(edx_movies, aes(x = rating - mu - b_g)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "M")) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Error", y = "Genres"),

  ncol = 2, align = 'hv', rel_heights = c(2, 2, 2))

# Random predictions for the movie bias :
edx_movies %>%
  mutate(pred_1 = mu + b_m) %>%
  select(userId, movieId, title, year, rating, pred_1) %>%
  filter(nchar(title) <= 30) %>%
  sample_n(5)

# Try 4 : we introduce a bias for movies and users

# Combination of 2 biases using the same formula,
# RMSE is now lower : 0.8767534
RMSE(edx$rating, mu + edx_movies$b_m + edx_movies$b_u)

# User bias applied after movie bias
# RMSE is now lower : 0.8567039
b_mu <- edx_movies %>%
  group_by(userId) %>%
  summarise(b_mu = mean(rating - mu - b_m))
head(b_mu)
edx_movies <- edx_movies %>% left_join(b_mu, by = "userId")
head(edx_movies)

results <- results %>% add_row(Type = "Movie + User", RMSE = RMSE(edx_movies$rating, mu + edx_movies$b_m + edx_movies$b_mu))

# Genres bias applied after Movie + User bias
# RMSE is now a litle bit lower : 0.8563595
b_mug <- edx_movies %>%
  group_by(genres) %>%
  summarise(b_mug = mean(rating - mu - b_m - b_mu))
head(b_mug)
edx_movies <- edx_movies %>% left_join(b_mug, by = "genres")
head(edx_movies)

results <- results %>% add_row(Type = "Movie + User + Genres",
                               RMSE = RMSE(edx_movies$rating, mu + edx_movies$b_m + edx_movies$b_mu + edx_movies$b_mug))

# Display the updated RMSEs :
results %>%
  filter(Type %in% c("Target", "Average", "Movie", "Movie + User", "Movie + User + Genres"))

# Comparison of the Distribution of errors :
bind_rows(
  edx_movies %>% mutate(err = rating - mu - b_m, Type = "Movie") %>% select(rating, err, Type),
  edx_movies %>% mutate(err = rating - mu - b_m - b_mu, Type = "Movie+User") %>% select(rating, err, Type)
) %>%
  group_by(Type) %>%
  do(data.frame(density = density(.$err)$y, err = density(.$err)$x)) %>%
  ggplot(aes(x = err, y = density, color = Type)) +
  geom_line(size = 1) +  # Use geom_line for lines instead of areas
  scale_color_manual(values = c("Movie" = "darkred", "Movie+User" = "grey")) +
  labs(x = "Error", y = "Density") +
  theme_minimal() + 
  theme(legend.position = "top")

# Random predictions for the movie bias, compared with the Movie+User bias :
edx_movies %>%
  mutate(pred_1 = mu + b_m, pred_2 = mu + b_m + b_mu) %>%
  select(userId, movieId, title, year, rating, pred_1, pred_2) %>%
  filter(nchar(title) <= 30) %>%
  sample_n(5)

# Try 5 : we add regularization

lambdas <- seq(0, 5, 0.1)

rmse_arr <- sapply(lambdas, function(lambda) {
  b_m_reg <- edx_movies %>%
    group_by(movieId) %>%
    summarise(b_m_reg = sum(rating - mu)/(n() + lambda))
  edx_movies <- edx_movies %>% left_join(b_m_reg, by = "movieId")
  
  b_mu_reg <- edx_movies %>%
    group_by(userId) %>%
    summarise(b_mu_reg = sum(rating - mu - b_m_reg)/(n() + lambda))
  edx_movies <- edx_movies %>% left_join(b_mu_reg, by = "userId")
  
  RMSE(edx_movies$rating, mu + edx_movies$b_m_reg + edx_movies$b_mu_reg)
})

# Plot the RMSEs against the values of alpha :
ggplot(mapping = aes(x = lambdas, y = rmse_arr)) +
  geom_point(color = "darkred") +
  labs(x = "Lambda", y = "RMSE") +
  theme_minimal() + theme(legend.position = "top")

# Lambda :
lambdas[which.min(rmse_arr)]

# The result is even higher than with the previous method
# and not really below the Movie + User method :
results <- results %>% add_row(Type = "Regularisation (Movie + User)", RMSE = rmse_arr[which.min(rmse_arr)])

# Display the updated RMSEs :
results %>%
  filter(Type %in% c("Target", "Average", "Movie", "Movie + User", "Regularisation (Movie + User)"))

# Try 6 : we introduce an interaction between 2 variables
# after adding a bias for the movies (b_m).

# We will apply a regularization with the value of lambda found earlier :
lambda <- 0.5

# Variable v : movieId, t_year
b_v <- edx_movies %>%
  group_by(movieId, t_year) %>%
  summarise(b_v = mean(rating - mu))
edx_movies <- edx_movies %>%
  left_join(b_v, by = c("movieId", "t_year")) %>%
  mutate(b_v = replace_na(b_v, 0))

# Variable w : userId, t_year
b_w <- edx_movies %>%
  group_by(userId, t_year) %>%
  summarise(b_w = mean(rating - mu))
edx_movies <- edx_movies %>%
  left_join(b_w, by = c("userId", "t_year")) %>%
  mutate(b_w = replace_na(b_w, 0))

# Variable x : movieId, t_year, genres
b_x <- edx_movies %>%
  group_by(movieId, t_year, genres) %>%
  summarise(b_x = mean(rating - mu))
edx_movies <- edx_movies %>%
  left_join(b_x, by = c("movieId", "t_year", "genres")) %>%
  mutate(b_x = replace_na(b_x, 0))

# Display the updated RMSEs :
results <- results %>% add_row(Type = "movieId, t_year", RMSE = RMSE(edx_movies$rating, mu + edx_movies$b_v))
results <- results %>% add_row(Type = "userId, t_year", RMSE = RMSE(edx_movies$rating, mu + edx_movies$b_w))
results <- results %>% add_row(Type = "movieId, t_year, genres", RMSE = RMSE(edx_movies$rating, mu + edx_movies$b_x))

# Define the desired order for the filter
desired_order <- c("Target", "Average", "Movie", "movieId, t_year", 
                   "User", "userId, t_year", "Genres", "movieId, t_year, genres")
# Filter and order the results
results %>%
  filter(Type %in% desired_order) %>%
  mutate(Type = factor(Type, levels = desired_order)) %>%
  arrange(Type)

# We remove the b_v, b_w and b_x columns for next calculation :
edx_movies <- edx_movies %>% select(-b_v, -b_w, -b_x)

# And we calculate the biases on the 3 groups of variables :

# Variable v : movieId, t_year
b_v <- edx_movies %>%
  group_by(movieId, t_year) %>%
  summarise(b_v = sum(rating - mu)/(n() + lambda))
edx_movies <- edx_movies %>%
  left_join(b_v, by = c("movieId", "t_year")) %>%
  mutate(b_v = replace_na(b_v, 0))

# Variable w : userId, t_year
b_w <- edx_movies %>%
  group_by(userId, t_year) %>%
  summarise(b_w = sum(rating - mu - b_v)/(n() + lambda))
edx_movies <- edx_movies %>%
  left_join(b_w, by = c("userId", "t_year")) %>%
  mutate(b_w = replace_na(b_w, 0))

# Variable x : movieId, t_year, genres
b_x <- edx_movies %>%
  group_by(movieId, t_year, genres) %>%
  summarise(b_x = sum(rating - mu - b_v - b_w)/(n() + lambda))
edx_movies <- edx_movies %>%
  left_join(b_x, by = c("movieId", "t_year", "genres")) %>%
  mutate(b_x = replace_na(b_x, 0))

# Display the updated RMSEs : 0.8417134
RMSE(edx_movies$rating, mu + edx_movies$b_v + edx_movies$b_w + edx_movies$b_x)
results <- results %>% add_row(Type = "Interaction",
                               RMSE = RMSE(edx_movies$rating, mu + edx_movies$b_v + edx_movies$b_w + edx_movies$b_x))

# Define the desired order for the filter
desired_order <- c("Target", "Average", "Movie",
                   "Regularisation (Movie + User)", 
                   "Interaction")
# Filter and order the results
results %>%
  filter(Type %in% desired_order) %>%
  mutate(Type = factor(Type, levels = desired_order)) %>%
  arrange(Type)

# Random predictions for the movie bias, compared with the Movie+User bias and the 2D/3D Interaction bias :
edx_movies %>%
  mutate(pred_1 = mu + b_m, pred_2 = mu + b_m + b_mu, pred_3 = mu + b_v + b_w + b_x) %>%
  select(userId, movieId, title, year, rating, pred_1, pred_2, pred_3) %>%
  filter(nchar(title) <= 30) %>%
  sample_n(5)

# Try 7 : we can update the predictions so there is no value over 5 (max rating)
# and no value under 0.5 (min rating), and we can even go further by calculating the
# best min and max values for which we get the minimal RMSE :

# Calculate min and max values of the predictions :
edx_movies <- edx_movies %>% mutate(pred = mu + edx_movies$b_v + edx_movies$b_w + edx_movies$b_x)
min(edx_movies$pred)
max(edx_movies$pred)

# Display min and max values of the predictions in a table :
data.frame(Variable = c("Rating", "Prediction"),
                           Min = c(min(edx_movies$rating), min(edx_movies$pred)),
                           Max = c(max(edx_movies$rating), max(edx_movies$pred)))

# Set the vmax values between 4.25 and 5 :
vmaxs <- seq(4.25, 5, 0.01)

# Function to calculate the RMSE based on vmax :
rmse_clamp_max_arr <- sapply(vmaxs, function(vmax) {
  edx_movies$pred_clamp <- pmin(edx_movies$pred, vmax)
  RMSE(edx_movies$rating, edx_movies$pred_clamp)
})

# Display the RMSE vs vmax :
ggplot(mapping = aes(x = vmaxs, y = rmse_clamp_max_arr)) +
  geom_point(color = "darkred") +
  labs(x = "VMax", y = "RMSE") +
  theme_minimal() + theme(legend.position = "top")

# vmax = 4.64
vmaxs[which.min(rmse_clamp_max_arr)]

# RMSE : 0.8412606
rmse_clamp_max_arr[which.min(rmse_clamp_max_arr)]

# Set the vmin values between 0.5 and 1.5 :
vmins <- seq(0.5, 1.5, 0.01)

# Function to calculate the RMSE based on vmin and with a vmax value of 4.64 :
rmse_clamp_min_arr <- sapply(vmins, function(vmin) {
  edx_movies$pred_clamp <- pmin(pmax(edx_movies$pred, vmin), 4.64)
  RMSE(edx_movies$rating, edx_movies$pred_clamp)
})

# Display the RMSE vs vmin :
ggplot(mapping = aes(x = vmins, y = rmse_clamp_min_arr)) +
  geom_point(color = "darkred") +
  labs(x = "VMin", y = "RMSE") +
  theme_minimal() + theme(legend.position = "top")

# vmax = 0.93
vmins[which.min(rmse_clamp_min_arr)]

# RMSE : 0.8412219
rmse_clamp_min_arr[which.min(rmse_clamp_min_arr)]

# We now replace all values over vmax with vmax,
# and all values under vmin with vmin :
edx_movies$pred_clamp <- pmin(pmax(edx_movies$pred, 0.93), 4.64)

# and obviously we get the same RMSE as before : 0.8412219
RMSE(edx_movies$rating, edx_movies$pred_clamp)

# Save the RMSE in the results table :
results <- results %>% add_row(Type = "Interaction + Clamping", RMSE = RMSE(edx_movies$rating, edx_movies$pred_clamp))

# Display the updated RMSEs :
results %>%
  filter(Type %in% c("Target", "Average", "Movie", "Movie + User", "All",
                     "Regularisation (Movie + User)", "Interaction",
                     "Interaction + Clamping"))

#####################################################
###             Final RMSE (test set)             ###
#####################################################

# Let's count the number of rows only in final_holdout_test for each couple :
final_holdout_test_movies <- final_holdout_test %>%
  mutate(
    # Convert timestamp to POSIXct (assuming it's in seconds)
    datetime = as.POSIXct(timestamp, origin = "1970-01-01", tz = "UTC"),
    t_year = year(datetime),
    year = as.integer(str_extract(title, "(?<=\\()\\d{4}(?=\\))"))
  ) %>%
  select(userId, movieId, rating, t_year, title, year, genres)

final_holdout_test_movies <- final_holdout_test_movies %>%
  left_join(b_v, by = c("movieId", "t_year")) %>%
  mutate(b_v = replace_na(b_v, 0))

final_holdout_test_movies <- final_holdout_test_movies %>%
  left_join(b_w, by = c("userId", "t_year")) %>%
  mutate(b_w = replace_na(b_w, 0))

final_holdout_test_movies <- final_holdout_test_movies %>%
  left_join(b_x, by = c("movieId", "t_year", "genres")) %>%
  mutate(b_x = replace_na(b_x, 0))

final_holdout_test_movies$pred <- pmin(pmax(mu +
                                              final_holdout_test_movies$b_v +
                                              final_holdout_test_movies$b_w +
                                              final_holdout_test_movies$b_x, 0.93), 4.64)

RMSE(final_holdout_test_movies$rating, final_holdout_test_movies$pred)

#####################################################
###             End                               ###
#####################################################

