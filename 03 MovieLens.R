library(cowplot)
library(kableExtra)
library(scales)

#####################################################
###                   Overview                    ###
#####################################################

# Structure of the edx table : variables and stats
data_summary <- summary(edx)
kable(data_summary) %>% kable_styling(font_size = 9) %>% row_spec(0, background = "lightgrey")

# Structure of the final_holdout_test table : variables and stats
data_summary <- summary(final_holdout_test)
kable(data_summary) %>% kable_styling(font_size = 9) %>% row_spec(0, background = "lightgrey")

# Stats for both edx (train) and final_holdout_test (test dataset) :
# Number of movies, users and ratings (rows)
data_summary <- data.frame(Dataset = c("edx", "final_holdout_test"),
                           Type = c("Train", "Test"),
                           Movies = c(comma(n_distinct(edx$movieId)), comma(n_distinct(final_holdout_test$movieId))),
                           Users = c(comma(n_distinct(edx$userId)), comma(n_distinct(final_holdout_test$userId))),
                           Ratings = c(comma(nrow(edx)), comma(nrow(final_holdout_test))))
kable(data_summary) %>% kable_styling(full_width = F) %>% row_spec(0, background = "lightgrey")

# Show that (movieId, userId) can be used as a primary key :
edx_unique <- edx %>% distinct(movieId, userId)
test_unique <- final_holdout_test %>% distinct(movieId, userId)
overlap <- inner_join(edx_unique, test_unique, by = c("movieId", "userId"))
data_summary <- data.frame(Dataset = c("edx", "final_holdout_test", "Overlap"),
                           MovieUserId = c(comma(nrow(edx_unique)),
                                           comma(nrow(test_unique)),
                                           comma(nrow(overlap))),
                           Ratings = c(comma(nrow(edx)), comma(nrow(final_holdout_test)), ""))
names(data_summary)[2] <- "(movieId, userId)"
kable(data_summary) %>% kable_styling(full_width = F) %>% row_spec(0, background = "lightgrey")

# Top rows of the train dataset
# we may change the format to markdown
data_summary <- head(edx)
kable(data_summary, format = "html", escape = FALSE) %>% kable_styling() %>% row_spec(0, background = "lightgrey")

#####################################################
###            Data Transformation                ###
#####################################################

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
# we may change the format to markdown
data_summary <- head(edx_movies %>% select(userId, movieId,
                                           rating, t_day_of_week,
                                           t_day, t_month,
                                           t_year, t_hour,
                                           title, year))
kable(data_summary, format = "html", escape = FALSE) %>% kable_styling() %>% row_spec(0, background = "lightgrey")

# List of variables and number of distinct values
data_summary <- edx_movies %>%
  select(userId, movieId, t_day_of_week, t_day,
         t_month, t_year, t_hour, title, year, genres) %>%
  summarise(across(everything(), ~ n_distinct(.))) %>%
  pivot_longer(cols = everything(), names_to = "Variable", values_to = "Distinct_Count") %>%
  arrange(desc(Distinct_Count))
kable(data_summary, format = "html", escape = FALSE) %>% kable_styling() %>% row_spec(0, background = "lightgrey")

#####################################################
###             Data Analysis                     ###
#####################################################

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
kable(
  top_n(
    list_movies %>% mutate(year = as.character(year)) %>% select(index, title, year, count),
    5, count),
  format.args = list(big.mark = ",")) %>%
  kable_styling(full_width = F) %>% row_spec(0, background = "lightgrey")

# Plot the movies :
# the figure on the left shows the number of ratings per movie (descending),
# the figure on the right is the same but a log10 transformation is applied to the y axis (number of ratings) :
plot_grid(
  list_movies %>% sample_n(1000) %>% ggplot(aes(x = index, y = count)) +
    geom_area(color = "darkblue", fill="darkblue", alpha = 0.1) +
    theme_minimal() +
    labs(x = "Movie", y = "Count"),
  list_movies %>% sample_n(1000) %>% ggplot(aes(x = index, y = count)) +
    geom_area(color = "darkblue", fill="darkblue", alpha = 0.1) +
    theme_minimal() +
    labs(x = "Movie", y = "Count (log10)") +
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
kable(
  top_n(list_users, 5, count),
  format.args = list(big.mark = ",")) %>%
  kable_styling(full_width = F) %>% row_spec(0, background = "lightgrey")

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
data_summary <- data.frame(Type = c("Average", "Standard Deviation"),
                           Value = c(mu, sd))
kable(data_summary) %>% kable_styling(full_width = F) %>% row_spec(0, background = "lightgrey")

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

# Average rating per title
avg_rating_per_title <- edx_movies %>%
  group_by(title) %>%
  summarise(avg_rating = mean(rating)) %>%
  ungroup() %>%
  mutate(source = "Title")
head(avg_rating_per_title)

# Average rating per genres
avg_rating_per_genres <- edx_movies %>%
  group_by(genres) %>%
  summarise(avg_rating = mean(rating)) %>%
  ungroup() %>%
  mutate(source = "Genres")
head(avg_rating_per_genres)

# We plot the four graphs :
plot_grid(
  ggplot(avg_rating_per_user, aes(x = avg_rating)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Rating", y = "Users"),
  
  ggplot(avg_rating_per_movie, aes(x = avg_rating)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Rating", y = "Movies"),
  
  ggplot(avg_rating_per_title, aes(x = avg_rating)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Rating", y = "Titles"),
  
  ggplot(avg_rating_per_genres, aes(x = avg_rating)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Rating", y = "Genres"),
  
  ncol = 2, align = 'hv', rel_heights = c(2, 2, 2))

# We will now compare Title against Movie as the graphs look very similar :
ggplot(bind_rows(avg_rating_per_movie, avg_rating_per_title), aes(x = avg_rating, fill = source)) +
  geom_histogram(position = "identity", alpha = 0.8, bins = 30) +
  scale_color_brewer(palette="Accent") + 
  labs(x = "Rating", y = "Title") +
  theme_minimal() + theme(legend.position = "top") +
  scale_fill_manual(values = c("Movie" = "darkred", "Title" = "grey"))

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

# Try 1 : we predict the average value

# Ratings (10,000 samples) with average value :
edx_movies %>% select(rating) %>% sample_n(10000) %>% arrange(desc(rating)) %>%
  mutate(index = row_number()) %>%
  ggplot(aes(x = index, y = rating)) +
  geom_area(color = "darkred", fill="darkred", alpha = 0.1) +
  geom_hline(yintercept = mu, color = "orange", linetype = "dashed", size = 1) +
  theme_minimal() +
  labs(x = "Index", y = "Rating")

# Distribution of the error if we predict the average value (constant) :
ggplot(edx_movies, aes(x = rating - mu)) +
  geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
  scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "M")) +
  scale_color_brewer(palette="Accent") + 
  theme_minimal() + theme(legend.position = "top") +
  labs(x = "Error (average)", y = "Number of Ratings")

# RMSE for the average : 1.060331
RMSE(edx$rating, mu)
results <- results %>% add_row(Type = "Average", RMSE = RMSE(edx$rating, mu))

# Display the baseline RMSE :
kable(results) %>% kable_styling(full_width = F) %>% row_spec(0, background = "lightgrey")

# Try 2 : we predict a random value with same average as mu
edx_movies$pred <- rnorm(n, mean = mu, sd = sd)
head(edx_movies)
ggplot(edx_movies, aes(x = rating - pred)) +
  geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
  scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "M")) +
  scale_color_brewer(palette="Accent") + 
  theme_minimal() + theme(legend.position = "top") +
  labs(x = "Error (average)", y = "Number of Ratings")

# RMSE for random values : 1.499818
# We don't save it in the results table as it is above the baseline value.
RMSE(edx_movies$rating, edx_movies$pred)

# We could reduce further the RMSE by replacing negative predictions with 0,
# and the ones above 5 by 5, but it won't change much :
# the result will still be above the baseline RMSE : 1.449352
edx_movies <- edx_movies %>%
  mutate(pred = case_when(
    pred < 0 ~ 0,
    pred > 5 ~ 5,
    TRUE ~ pred
  ))
RMSE(edx_movies$rating, edx_movies$pred)

# We remove the random pred from the data frame
edx_movies <- edx_movies %>% select(-pred)
edx_movies <- edx_movies %>% select(userId, movieId, rating, t_day_of_week, t_day, t_month, t_year, t_hour, year, title, genres)

# Try 3 : we introduce a bias for movies, users, genres, t_year and year
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

# View the final result
print(selected_ratings)

# Create the base plot
plot_bias <- ggplot(selected_ratings, aes(x = index, y = rating, color = as.factor(movieId))) +
  geom_point(size = 1) +
  labs(x = "Index", y = "Rating") +
  theme_minimal() +
  theme(legend.position = "none")

# Create a data frame for the segments
lines_data <- selected_ratings %>%
  group_by(movieId) %>%
  summarise(avg_rating = mean(rating),
            x_start = min(index),
            x_end = max(index))

# Add horizontal lines for the average rating, constrained to the respective index range
plot_bias + 
  geom_segment(data = lines_data, 
               aes(x = x_start, xend = x_end, y = avg_rating, yend = avg_rating, color = as.factor(movieId)),
               linetype = "solid", size = 2) +
  geom_hline(yintercept = mu, color = "orange", linetype = "dashed", size = 1)

# Remove unused variables
# rm(selected_movies, selected_ratings)

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
b_ty <- edx_movies %>%
  group_by(t_year) %>%
  summarise(b_ty = mean(rating - mu))
head(b_ty)
edx_movies <- edx_movies %>% left_join(b_ty, by = "t_year")
head(edx_movies)

# Year (release) bias
b_y <- edx_movies %>%
  group_by(year) %>%
  summarise(b_y = mean(rating - mu))
head(b_y)
edx_movies <- edx_movies %>% left_join(b_y, by = "year")
head(edx_movies)

# Add the movie and user RMSE values to the results table :
results <- results %>% add_row(Type = "Movie", RMSE = RMSE(edx$rating, mu + edx_movies$b_m))
results <- results %>% add_row(Type = "User", RMSE = RMSE(edx$rating, mu + edx_movies$b_u))
results <- results %>% add_row(Type = "Genres", RMSE = RMSE(edx$rating, mu + edx_movies$b_g))
results <- results %>% add_row(Type = "Year (timestamp)", RMSE = RMSE(edx$rating, mu + edx_movies$b_ty))
results <- results %>% add_row(Type = "Year (release)", RMSE = RMSE(edx$rating, mu + edx_movies$b_y))

#t <- edx_movies %>% mutate(pred = mu + b_m + b_mu)
#100 * sum(t$pred < 0.5 | t$pred > 5) / nrow(t)

# Display the updated RMSEs :
kable(results %>%
        filter(Type %in% c("Target", "Average", "Movie", "User", "Genres", "Year (timestamp)", "Year (release)"))) %>%
  kable_styling(full_width = F)

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
  
  ggplot(edx_movies, aes(x = rating - mu - b_ty)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "M")) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Error", y = "Year (timestamp)"),
  
  ncol = 2, align = 'hv', rel_heights = c(2, 2, 2))

# Try 4 : we introduce a bias for movies and users

# Combination of 2 biases using the same formula,
# RMSE is now lower : 0.8767534
RMSE(edx$rating, mu + edx_movies$b_m + edx_movies$b_u)

# User bias applied after movie bias
b_mu <- edx_movies %>%
  group_by(userId) %>%
  summarise(b_mu = mean(rating - mu - b_m))
head(b_mu)
edx_movies <- edx_movies %>% left_join(b_mu, by = "userId")
head(edx_movies)

results <- results %>% add_row(Type = "Movie + User", RMSE = RMSE(edx_movies$rating, mu + edx_movies$b_m + edx_movies$b_mu))

# Display the updated RMSEs :
kable(results) %>% kable_styling(full_width = F) %>% row_spec(0, background = "lightgrey")

# We have now a prediction method that gives an RMSE below the target value.
# We can try to go further..

# Bias : Movie + User + Genres
b_mug <- edx_movies %>%
  group_by(genres) %>%
  summarise(b_mug = mean(rating - mu - b_m - b_mu))
edx_movies <- edx_movies %>% left_join(b_mug, by = "genres")
RMSE(edx_movies$rating, mu + edx_movies$b_m + edx_movies$b_mu + edx_movies$b_mug)

# Bias : Movie + User + Genres + Year (timestamp)
b_mugty <- edx_movies %>%
  group_by(t_year) %>%
  summarise(b_mugty = mean(rating - mu - b_m - b_mu - b_mug))
edx_movies <- edx_movies %>% left_join(b_mugty, by = "t_year")
RMSE(edx_movies$rating, mu + edx_movies$b_m + edx_movies$b_mu + edx_movies$b_mug + edx_movies$b_mugty)

# Bias : Movie + User + Genres + Year (timestamp) + Year (release)
b_mugtyy <- edx_movies %>%
  group_by(year) %>%
  summarise(b_mugtyy = mean(rating - mu - b_m - b_mu - b_mug - b_mugty))
edx_movies <- edx_movies %>% left_join(b_mugtyy, by = "year")
RMSE(edx_movies$rating, mu + edx_movies$b_m + edx_movies$b_mu + edx_movies$b_mug + edx_movies$b_mugty + edx_movies$b_mugtyy)

# There is not much difference with Movie + User.
results <- results %>% add_row(Type = "All", RMSE = RMSE(edx_movies$rating, mu + edx_movies$b_m + edx_movies$b_mu + edx_movies$b_mug + edx_movies$b_mugty + edx_movies$b_mugtyy))

# Display the updated RMSEs :
kable(results) %>% kable_styling(full_width = F) %>% row_spec(0, background = "lightgrey")

# Distribution of the error for the bias :
plot_grid(
  ggplot(edx_movies, aes(x = rating - mu - b_m)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "M"), limits = c(0, 1750000)) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Error", y = "Movie"),
  
  ggplot(edx_movies, aes(x = rating - mu - b_m - b_mu)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    scale_y_continuous(labels = label_number(scale = 1e-6, suffix = "M"), limits = c(0, 1750000)) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Error", y = "Movie+User"),
  
  ncol = 2, align = 'hv', rel_heights = c(2, 2, 2))
head(edx_movies %>% mutate(pred = rating - mu - b_m, type = "Movie") %>% select(rating, pred, type))
bind_rows(edx_movies %>% mutate(err = rating - mu - b_m, type = "Movie") %>% select(rating, err, type),
          edx_movies %>% mutate(err = rating - mu - b_m - b_mu, type = "Movie+User") %>% select(rating, err, type))
ggplot(
  bind_rows(edx_movies %>% mutate(err = rating - mu - b_m, type = "Movie") %>% select(rating, err, type),
            edx_movies %>% mutate(err = rating - mu - b_m - b_mu, type = "Movie+User") %>% select(rating, err, type)),
  aes(x = err, fill = type)) +
  geom_histogram(position = "identity", alpha = 0.8, bins = 30) +
  scale_color_brewer(palette="Accent") + 
  labs(x = "Rating", y = "Count") +
  theme_minimal() + theme(legend.position = "top") +
  scale_fill_manual(values = c("Movie" = "darkred", "Movie+User" = "grey"))

# Try 5 : we add regularisation

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

# The result is even higher than with the previous method
# and not really below the Movie + User method :
results <- results %>% add_row(Type = "Regularisation (Movie + User)", RMSE = rmse_arr[which.min(rmse_arr)])

# Lambda :
lambdas[which.min(rmse_arr)]

# Display the updated RMSEs :
kable(results) %>% kable_styling(full_width = F) %>% row_spec(0, background = "lightgrey")

# Plot the RMSEs against the values of alpha :
ggplot(mapping = aes(x = lambdas, y = rmse_arr)) +
  geom_point(color = "darkred") +
  labs(x = "Lambda", y = "RMSE") +
  theme_minimal() + theme(legend.position = "top")

# The All and Regularisation (Movie + User) aren't really relevant,
# as we want to reduce the RMSE below 0.856
# we don't need them :
#results <- results %>%
#  filter(!Type %in% c("All", "Regularisation (Movie + User)"))

# Try 6 : we introduce an interaction between 2 variables
# after adding a bias for the movies (b_m).

# Before continuing, we need to see which combination can be
# used for this exercise :
# obviously the couple movieId, userId will give the best outcome (RMSE = 0)
# but it won't help when used on the final_holdout_test dataset.
# Let's count the number of rows only in final_holdout_test for each couple :
final_holdout_test_movies <- final_holdout_test %>%
  mutate(
    # Convert timestamp to POSIXct (assuming it's in seconds)
    datetime = as.POSIXct(timestamp, origin = "1970-01-01", tz = "UTC"),
    t_year = year(datetime),                         # Year
    year = as.integer(str_extract(title, "(?<=\\()\\d{4}(?=\\))")),  # Removes parentheses from the year
    title_without_year = str_remove(title, "\\s*\\(\\d{4}\\)")  # Removes year with parentheses
  ) %>%
  select(userId, movieId, rating, t_year, title = title_without_year, year, genres)

# Function to get number of rows in the final dataset for each combination :
get_nb_unique_rows <- function(combination) {
  unique_combinations <- anti_join(final_holdout_test_movies, edx_movies, by = combination)
  # Return a data frame or tibble for the output
  return(tibble(
    Combination = paste(combination, collapse = ", "),
    `Nb Rows` = nrow(unique_combinations)
  ))
}

# All variables to be used :
#variables <- c("userId", "t_year", "title", "year", "genres")
variables <- c("userId", "movieId", "t_year", "title", "year", "genres")

# Generate combinations of size 2
combinations <- combn(variables, 2, simplify = FALSE)

# Filter combinations to keep only those containing "userId"
#combinations <- Filter(function(combination) "userId" %in% combination, combinations)

# Apply the function to each combination and combine results into a tibble
unique_rows <- bind_rows(lapply(combinations, get_nb_unique_rows)) %>%
  arrange(desc(`Nb Rows`))
unique_rows

#combinations <- Filter(function(combination) "movieId" %in% combination, combinations)
#unique_rows <- bind_rows(lapply(combinations, get_nb_unique_rows)) %>%
#  arrange(desc(`Nb Rows`))
#unique_rows

#combinations <- Filter(function(combination) "genres" %in% combination, combinations)
#unique_rows <- bind_rows(lapply(combinations, get_nb_unique_rows)) %>%
#  arrange(desc(`Nb Rows`))
#unique_rows

# Display for each couple the number of rows in final_holdout_test
# and not in the edx dataset :
kable(unique_rows, format.args = list(big.mark = ",")) %>%
  kable_styling(full_width = F) %>% row_spec(0, background = "lightgrey")

# Release some variables :
#rm(variables, combinations)

# Example of a multi-dimensional rating
x <- c(1, 1, 1)
y <- c(2, 2, 2)
z <- c(3, 4, 5)
scatterplot3d::scatterplot3d(x, y, z, pch = 16,
                             grid = TRUE, box = FALSE, xlab = "User ID", 
                             ylab = "Year", zlab = "Rating", zlim = c(0, 5))

df <- edx_movies %>% sample_n(50)
scatterplot3d::scatterplot3d(df$userId, df$t_year, df$rating, color = df$movieId, pch = 16,
                             grid = TRUE, box = FALSE, xlab = "User ID", 
                             ylab = "Year", zlab = "Rating", zlim = c(0, 5))

# The more rows only in final_holdout_test, the better RMSE we will get in the training set,
# but we will then get a high RMSE in the test set, so we will continue with the couple
# userId, t_year
b_i_uty <- edx_movies %>%
  group_by(userId, t_year) %>%
  summarise(b_i_uty = mean(rating - mu - b_m))
edx_movies <- edx_movies %>%
  left_join(b_i_uty, by = c("userId", "t_year"))

# The RMSE is now 0.8519394
RMSE(edx_movies$rating, mu + edx_movies$b_m + edx_movies$b_i_uty)
#results <- results %>% add_row(Type = "Interaction (User + Timestamp Year)", RMSE = RMSE(edx_movies$rating, mu + edx_movies$b_m + edx_movies$b_i_uty))

# Bias : Movie + User + Year (timestamp)
b_muyt <- edx_movies %>%
  group_by(t_year) %>%
  summarise(b_muyt = mean(rating - mu - b_m - b_mu))
edx_movies <- edx_movies %>% left_join(b_muyt, by = "t_year")
RMSE(edx_movies$rating, mu + edx_movies$b_m + edx_movies$b_mu + edx_movies$b_muyt)
# Separately the bias on movie, user and t_year is higher : 0.8566979

# Display the updated RMSEs :
kable(results) %>% kable_styling(full_width = F) %>% row_spec(0, background = "lightgrey")

lambda <- 0.5
unique_rows
head(edx_movies)
#edx_movies <- edx_movies %>% select(-b_v, -b_w, -b_x)
#edx_movies <- edx_movies %>% select(-b_v, -b_w, -b_x, -b_y, -b_z)
b_v <- edx_movies %>%
  group_by(movieId, t_year) %>%
  summarise(b_v = sum(rating - mu)/(n() + lambda))
edx_movies <- edx_movies %>%
  left_join(b_v, by = c("movieId", "t_year")) %>%
  mutate(b_v = replace_na(b_v, 0))

b_w <- edx_movies %>%
  group_by(userId, t_year) %>%
  summarise(b_w = sum(rating - mu - b_v)/(n() + lambda))
edx_movies <- edx_movies %>%
  left_join(b_w, by = c("userId", "t_year")) %>%
  mutate(b_w = replace_na(b_w, 0))

b_x <- edx_movies %>%
  group_by(t_year, year, title) %>%
  summarise(b_x = sum(rating - mu - b_v - b_w)/(n() + lambda))
edx_movies <- edx_movies %>%
  left_join(b_x, by = c("t_year", "year", "title")) %>%
  mutate(b_x = replace_na(b_x, 0))

#b_y <- edx_movies %>%
#  group_by(t_year, genres) %>%
#  summarise(b_y = sum(rating - mu - b_v - b_w - b_x)/(n() + lambda))
#edx_movies <- edx_movies %>%
#  left_join(b_y, by = c("t_year", "genres")) %>%
#  mutate(b_y = replace_na(b_y, 0))

#b_z <- edx_movies %>%
#  group_by(t_year, year) %>%
#  summarise(b_z = sum(rating - mu - b_v - b_w - b_x - b_y)/(n() + lambda))
#edx_movies <- edx_movies %>%
#  left_join(b_z, by = c("t_year", "year")) %>%
#  mutate(b_z = replace_na(b_z, 0))

# Lowest to date : 0.8416967
# Current : 0.8417261 (regularized)
#RMSE(edx_movies$rating, mu + edx_movies$b_v + edx_movies$b_w + edx_movies$b_x + edx_movies$b_y + edx_movies$b_z)
# Lowest to date : 0.841729
# now 0.8417134
RMSE(edx_movies$rating, mu + edx_movies$b_v + edx_movies$b_w + edx_movies$b_x)

results <- results %>% add_row(Type = "2D/3D Interaction", RMSE = RMSE(edx_movies$rating, mu + edx_movies$b_v + edx_movies$b_w + edx_movies$b_x))

head(final_holdout_test_movies)
#final_holdout_test_movies <- final_holdout_test_movies %>% select(-b_v, -b_w, -b_x, -pred)
#final_holdout_test_movies <- final_holdout_test_movies %>% select(-b_v, -b_w, -b_x)
#final_holdout_test_movies <- final_holdout_test_movies %>% select(-b_v, -b_w, -b_x, -b_y, -b_z)
final_holdout_test_movies <- final_holdout_test_movies %>%
  left_join(b_v, by = c("movieId", "t_year")) %>%
  mutate(b_v = replace_na(b_v, 0))

final_holdout_test_movies <- final_holdout_test_movies %>%
  left_join(b_w, by = c("userId", "t_year")) %>%
  mutate(b_w = replace_na(b_w, 0))

final_holdout_test_movies <- final_holdout_test_movies %>%
  left_join(b_x, by = c("t_year", "year", "title")) %>%
  mutate(b_x = replace_na(b_x, 0))

#final_holdout_test_movies <- final_holdout_test_movies %>%
#  left_join(b_y, by = c("t_year", "genres")) %>%
#  mutate(b_y = replace_na(b_y, 0))

#final_holdout_test_movies <- final_holdout_test_movies %>%
#  left_join(b_z, by = c("t_year", "year")) %>%
#  mutate(b_z = replace_na(b_z, 0))

# Lowest to date : 0.8587368
#RMSE(final_holdout_test_movies$rating,
#     mu +
#       final_holdout_test_movies$b_v +
#       final_holdout_test_movies$b_w +
#       final_holdout_test_movies$b_x +
#       final_holdout_test_movies$b_y +
#       final_holdout_test_movies$b_z)

# Lowest to date : 0.8587364
# now 0.8587248
RMSE(final_holdout_test_movies$rating,
     mu +
       final_holdout_test_movies$b_v +
       final_holdout_test_movies$b_w +
       final_holdout_test_movies$b_x)

#####################################################
###             Final RMSE (test set)             ###
#####################################################

# We add the bias for the movie :
#final_holdout_test_movies <- final_holdout_test_movies %>% left_join(b_m, by = "movieId")

# Then we add the interaction for the user and year (timestamp) :
#final_holdout_test_movies <- final_holdout_test_movies %>%
#  left_join(b_i_uty, by = c("userId", "t_year")) %>%
#  mutate(b_i_uty = replace_na(b_i_uty, 0))

# The RMSE on the test set is 0.8628085
# below the target of 0.86490
#results <- results %>% add_row(Type = "Test set",
#                               RMSE = RMSE(final_holdout_test_movies$rating,
#                                           mu +
#                                             final_holdout_test_movies$b_m +
#                                             final_holdout_test_movies$b_i_uty))

# Display the updated RMSEs :
#kable(results) %>% kable_styling(full_width = F) %>% row_spec(0, background = "lightgrey")

#####################################################
###             End                               ###
#####################################################


# Generate combinations of size 3
combinations_3d <- combn(variables, 3, simplify = FALSE)

# Apply the function to each combination and combine results into a tibble
unique_rows_3d <- bind_rows(lapply(combinations_3d, get_nb_unique_rows)) %>%
  arrange(desc(`Nb Rows`))
unique_rows_3d

# Generate combinations of size 4
combinations_4d <- combn(variables, 4, simplify = FALSE)

# Apply the function to each combination and combine results into a tibble
unique_rows_4d <- bind_rows(lapply(combinations_4d, get_nb_unique_rows)) %>%
  arrange(desc(`Nb Rows`))
unique_rows_4d

edx_movies <- edx_movies %>% mutate(pred = mu + edx_movies$b_v + edx_movies$b_w + edx_movies$b_x)
head(edx_movies)
min(edx_movies$pred)
max(edx_movies$pred)
mean(edx_movies$pred)
RMSE(edx_movies$rating, edx_movies$pred)

data_summary <- data.frame(Variable = c("Rating", "Prediction"),
                           Min = c(min(edx_movies$rating), min(edx_movies$pred)),
                           Max = c(max(edx_movies$rating), max(edx_movies$pred)))
kable(data_summary) %>% kable_styling(full_width = F) %>% row_spec(0, background = "lightgrey")

vmaxs <- seq(4.25, 5, 0.01)

rmse_clamp_max_arr <- sapply(vmaxs, function(vmax) {
  edx_movies$pred_clamp <- pmin(edx_movies$pred, vmax)
  RMSE(edx_movies$rating, edx_movies$pred_clamp)
})

ggplot(mapping = aes(x = vmaxs, y = rmse_clamp_max_arr)) +
  geom_point(color = "darkred") +
  labs(x = "VMax", y = "RMSE") +
  theme_minimal() + theme(legend.position = "top")

vmaxs[which.min(rmse_clamp_max_arr)]
rmse_clamp_max_arr[which.min(rmse_clamp_max_arr)]

vmins <- seq(0.5, 1.5, 0.01)

rmse_clamp_min_arr <- sapply(vmins, function(vmin) {
  edx_movies$pred_clamp <- pmin(pmax(edx_movies$pred, vmin), 4.64)
  RMSE(edx_movies$rating, edx_movies$pred_clamp)
})

ggplot(mapping = aes(x = vmins, y = rmse_clamp_min_arr)) +
  geom_point(color = "darkred") +
  labs(x = "VMin", y = "RMSE") +
  theme_minimal() + theme(legend.position = "top")

vmins[which.min(rmse_clamp_min_arr)]
rmse_clamp_min_arr[which.min(rmse_clamp_min_arr)]

edx_movies$pred_clamp <- pmin(pmax(edx_movies$pred, 0.93), 4.64)
RMSE(edx_movies$rating, edx_movies$pred_clamp)

results <- results %>% add_row(Type = "2D/3D Interaction + Clamping", RMSE = RMSE(edx_movies$rating, edx_movies$pred_clamp))


final_holdout_test_movies$pred <- pmin(pmax(mu +
                                              final_holdout_test_movies$b_v +
                                              final_holdout_test_movies$b_w +
                                              final_holdout_test_movies$b_x, 0.93), 4.64)

RMSE(final_holdout_test_movies$rating, final_holdout_test_movies$pred)

stop("End of the code")




final_holdout_test_movies$pred <- pmin(pmax(mu +
                                              final_holdout_test_movies$b_v +
                                              final_holdout_test_movies$b_w +
                                              final_holdout_test_movies$b_x, 0.93), 4.64)

RMSE(final_holdout_test_movies$rating, final_holdout_test_movies$pred)















data_summary <- edx_movies %>% mutate(pred = mu + b_m) %>% select(userId, movieId, title, year, rating, pred) %>% sample_n(5)
kable(data_summary) %>% kable_styling(font_size = 9)

data_summary <- edx_movies %>% mutate(pred = mu + b_m + b_mu) %>% select(userId, movieId, title, year, rating, pred) %>% sample_n(5)
kable(data_summary) %>% kable_styling(font_size = 9)

edx_sample <- edx_movies %>% select(userId, movieId, title, year, rating) %>% sample_n(5)
edx_sample
data_summary <- edx_sample %>% mutate(pred1 = mu + edx_sample$b_m)

edx_sample <- edx_movies %>%
  mutate(pred_1 = mu + b_m, pred_2 = mu + b_m + b_mu, pred_3 = mu + b_v + b_w + b_x) %>%
  select(userId, movieId, title, year, rating, pred_1, pred_2, pred_3) %>%
  sample_n(5)
data_summary <- edx_sample %>% select(userId, movieId, title, year, rating, pred_1, pred_2, pred_3)
kable(data_summary) %>% kable_styling(font_size = 9)












































n





















head(edx_movies)
edx_movies <- edx_movies %>% select(-b_i_ug)
b_i_ug <- edx_movies %>%
  group_by(userId, genres) %>%
  summarise(b_i_ug = mean(rating - mu - b_m))
edx_movies <- edx_movies %>%
  left_join(b_i_ug, by = c("userId", "genres"))
RMSE(edx_movies$rating, mu + edx_movies$b_m + edx_movies$b_i_ug)
# The result is quite good : 0.5840494
results <- results %>% add_row(Type = "Interaction (User + Genres)", RMSE = RMSE(edx_movies$rating, mu + edx_movies$b_m + edx_movies$b_i_ug))

# Display the updated RMSEs :
kable(results) %>% kable_styling(full_width = F) %>% row_spec(0, background = "lightgrey")

final_holdout_test_movies <- final_holdout_test_movies %>% left_join(b_m, by = "movieId")
final_holdout_test_movies <- final_holdout_test_movies %>% left_join(b_u, by = "userId")
final_holdout_test_movies <- final_holdout_test_movies %>% left_join(b_mu, by = "userId")

final_holdout_test_movies <- final_holdout_test_movies %>%
  left_join(b_g, by = "genres")
b_g
final_holdout_test_movies <- final_holdout_test_movies %>%
  left_join(b_g, by = "genres") %>%
  mutate(value = replace_na(value, 0))
head(b_i_ug)
final_holdout_test_movies <- final_holdout_test_movies %>%
  left_join(b_i_ug, by = c("userId", "genres")) %>%
  mutate(b_i_ug = replace_na(b_i_ug, 0))
RMSE(final_holdout_test_movies$rating,
     mu + final_holdout_test_movies$b_m + final_holdout_test_movies$b_u + final_holdout_test_movies$b_i_ug)
head(final_holdout_test_movies)

final_holdout_test_movies <- final_holdout_test_movies %>% select(-b_g.x, -b_g.y)
final_holdout_test_movies <- final_holdout_test_movies %>% select(-b_i_ug)
head(edx_movies)
edx_movies <- edx_movies %>% select(-b_i_ug)
b_i_ug <- edx_movies %>%
  group_by(userId, year) %>%
  summarise(b_i_ug = mean(rating - mu - b_m))
edx_movies <- edx_movies %>%
  left_join(b_i_ug, by = c("userId", "year"))
RMSE(edx_movies$rating, mu + edx_movies$b_m + edx_movies$b_i_ug)

final_holdout_test_movies <- final_holdout_test_movies %>%
  left_join(b_mu, by = "userId")
RMSE(final_holdout_test_movies$rating,
     mu + final_holdout_test_movies$b_m + final_holdout_test_movies$b_mu)
RMSE(edx_movies$rating, mu + edx_movies$b_m + edx_movies$b_mu)


head(edx_movies)
edx_movies <- edx_movies %>% select(-b_i_ug)
b_i_ug <- edx_movies %>%
  group_by(t_year, title) %>%
  summarise(b_i_ug = mean(rating - mu - b_m))
edx_movies <- edx_movies %>%
  left_join(b_i_ug, by = c("t_year", "title"))
RMSE(edx_movies$rating, mu + edx_movies$b_m + edx_movies$b_i_ug)

head(edx_movies)
edx_movies <- edx_movies %>% select(-b_i_ug)
b_i_ug <- edx_movies %>%
  group_by(userId, t_year) %>%
  summarise(b_i_ug = mean(rating - mu - b_m))
edx_movies <- edx_movies %>%
  left_join(b_i_ug, by = c("userId", "t_year"))
RMSE(edx_movies$rating, mu + edx_movies$b_m + edx_movies$b_i_ug)

n




##################
# Final one
##################

edx_movies <- edx_movies %>% select(-b_i_ug)
b_i_ug <- edx_movies %>%
  group_by(userId, t_year) %>%
  summarise(b_i_ug = mean(rating - mu - b_m))
edx_movies <- edx_movies %>%
  left_join(b_i_ug, by = c("userId", "t_year"))
RMSE(edx_movies$rating, mu + edx_movies$b_m + edx_movies$b_i_ug)
# 0.8519394

head(b_i_ug)
final_holdout_test_movies <- final_holdout_test_movies %>% select(-b_i_ug)
final_holdout_test_movies <- final_holdout_test_movies %>%
  left_join(b_i_ug, by = c("userId", "t_year")) %>%
  mutate(b_i_ug = replace_na(b_i_ug, 0))
RMSE(final_holdout_test_movies$rating,
     mu + final_holdout_test_movies$b_m + final_holdout_test_movies$b_i_ug)
# 0.8628085

n

##################
# End of Final one
##################

edx_movies <- edx_movies %>% select(-b_i_ug)
b_i_ug <- edx_movies %>%
  group_by(t_year, year) %>%
  summarise(b_i_ug = mean(rating - mu - b_m))
edx_movies <- edx_movies %>%
  left_join(b_i_ug, by = c("t_year", "year"))
RMSE(edx_movies$rating, mu + edx_movies$b_m + edx_movies$b_mu + edx_movies$b_i_ug)
# 0.8581474

head(b_i_ug)
head(final_holdout_test_movies)
final_holdout_test_movies <- final_holdout_test_movies %>% select(-b_i_ug)
final_holdout_test_movies <- final_holdout_test_movies %>%
  left_join(b_i_ug, by = c("t_year", "year")) %>%
  mutate(b_i_ug = replace_na(b_i_ug, 0))
RMSE(final_holdout_test_movies$rating,
     mu + final_holdout_test_movies$b_m + final_holdout_test_movies$b_mu + final_holdout_test_movies$b_i_ug)
# 0.8668518








head(edx_movies)
edx_movies <- edx_movies %>% select(-b_i_ug)
b_i_ug <- edx_movies %>%
  group_by(userId, year) %>%
  summarise(b_i_ug = mean(rating - mu - b_m))
edx_movies <- edx_movies %>%
  left_join(b_i_ug, by = c("userId", "year"))
RMSE(edx_movies$rating, mu + edx_movies$b_m + edx_movies$b_i_ug)
# 0.7595269

head(b_i_ug)
head(final_holdout_test_movies)
final_holdout_test_movies <- final_holdout_test_movies %>% select(-b_i_ug)
final_holdout_test_movies <- final_holdout_test_movies %>%
  left_join(b_i_ug, by = c("userId", "year")) %>%
  mutate(b_i_ug = replace_na(b_i_ug, 0))
RMSE(final_holdout_test_movies$rating,
     mu + final_holdout_test_movies$b_m + final_holdout_test_movies$b_i_ug)
# 0.9211705





####################

#rm(b_my)
b_my <- edx_movies %>%
  group_by(year) %>%
  summarise(b_my = mean(rating - mu - b_m))
head(b_my)
edx_movies <- edx_movies %>% left_join(b_my, by = "year")
head(edx_movies)
#edx_movies <- edx_movies %>% select(-b_mu.y)

head(final_holdout_test_movies)
final_holdout_test_movies <- final_holdout_test_movies %>% select(-b_i_ug)
final_holdout_test_movies <- final_holdout_test_movies %>%
  left_join(b_my, by = "year")
RMSE(final_holdout_test_movies$rating,
     mu + final_holdout_test_movies$b_m + final_holdout_test_movies$b_my)

head(b_i_ug)
final_holdout_test_movies <- final_holdout_test_movies %>%
  left_join(b_i_ug, by = c("userId", "t_year")) %>%
  mutate(b_i_ug = replace_na(b_i_ug, 0))
RMSE(final_holdout_test_movies$rating,
     mu + final_holdout_test_movies$b_m + final_holdout_test_movies$b_my + final_holdout_test_movies$b_i_ug)











#####################
# And we compare User, Title and Genres against Movie :
avg_rating_comparison <- bind_rows(avg_rating_per_movie, avg_rating_per_user, avg_rating_per_title, avg_rating_per_genres)
head(avg_rating_comparison)
ggplot(avg_rating_comparison %>% filter(source %in% c("Movie", "User")), aes(x = avg_rating, fill = source)) +
  geom_histogram(position = "identity", alpha = 0.8, bins = 30) +
  scale_color_brewer(palette="Accent") + 
  labs(x = "Rating", y = "User") +
  theme_minimal() +
  scale_fill_manual(values = c("darkred", "grey"))

plot_grid(
  ggplot(avg_rating_comparison %>% filter(source %in% c("Movie", "User")), aes(x = avg_rating, fill = source)) +
    geom_histogram(position = "identity", alpha = 0.6, bins = 30) +
    scale_color_brewer(palette="Accent") + 
    labs(x = "Rating", y = "User") +
    theme_minimal() + theme(legend.position = "top") +
    scale_fill_manual(values = c("Movie" = "grey", "User" = "darkred")),
  
  ggplot(avg_rating_comparison %>% filter(source %in% c("Movie", "Title")), aes(x = avg_rating, fill = source)) +
    geom_histogram(position = "identity", alpha = 0.8, bins = 30) +
    scale_color_brewer(palette="Accent") + 
    labs(x = "Rating", y = "Title") +
    theme_minimal() + theme(legend.position = "top") +
    scale_fill_manual(values = c("Movie" = "grey", "Title" = "darkred")),
  
  ggplot(avg_rating_comparison %>% filter(source %in% c("Movie", "Genres")), aes(x = avg_rating, fill = source)) +
    geom_histogram(position = "identity", alpha = 0.8, bins = 30) +
    scale_color_brewer(palette="Accent") + 
    labs(x = "Rating", y = "Genres") +
    theme_minimal() + theme(legend.position = "top") +
    scale_fill_manual(values = c("Movie" = "grey", "Genres" = "darkred")),
  
  ncol = 3, align = 'hv', rel_heights = c(2, 2, 2))









































df <- avg_rating_comparison %>% filter(source %in% c("Movie", "User"))
ggplot(df, aes(x = avg_rating)) +
  # Histogram for Movie
  geom_histogram(data = df %>% filter(source == "Movie"), 
                 aes(fill = source), 
                 position = "identity", 
                 alpha = 0.5, 
                 bins = 30) +
  # Density line for User
  geom_density(data = df %>% filter(source == "User"),
               aes(color = source, group = source),
               size = 1) +
  # Customize scales
  scale_fill_manual(values = c("Movie" = "grey")) +
  scale_color_manual(values = c("User" = "darkred")) +
  labs(title = "Average Ratings Comparison",
       x = "Average Rating",
       y = "Count / Density") +
  theme_minimal()


































distinct_counts <- edx_movies %>%
  summarise(across(everything(), ~ n_distinct(.)))

# Display the result
print(distinct_counts)

# Distribution of average ratings per variable :
# Average rating per movie
avg_rating_per_movie <- edx_movies %>%
  group_by(movieId) %>%
  summarise(avg_rating = mean(rating)) %>%
  ungroup()
head(avg_rating_per_movie)
min(avg_rating_per_movie$avg_rating)
max(avg_rating_per_movie$avg_rating)

# Average rating per user
avg_rating_per_user <- edx_movies %>%
  group_by(userId) %>%
  summarise(avg_rating = mean(rating)) %>%
  ungroup()
head(avg_rating_per_user)
min(avg_rating_per_user$avg_rating)
max(avg_rating_per_user$avg_rating)

# Average rating per day of week
avg_rating_per_day_of_week <- edx_movies %>%
  group_by(t_day_of_week) %>%
  summarise(avg_rating = mean(rating)) %>%
  ungroup()
head(avg_rating_per_day_of_week)
min(avg_rating_per_day_of_week$avg_rating)
max(avg_rating_per_day_of_week$avg_rating)
summary(avg_rating_per_day_of_week)
nrow(avg_rating_per_day_of_week)
avg_rating_per_day_of_week
summary(edx_movies)
avg_rating_per_day_of_week <- edx_movies %>%
  group_by(rating) %>%
  summarise(avg_rating = n()) %>%
  ungroup()
avg_rating_per_day_of_week

# Average rating per day
avg_rating_per_day <- edx_movies %>%
  group_by(t_day) %>%
  summarise(avg_rating = mean(rating)) %>%
  ungroup()
head(avg_rating_per_day)

# Average rating per month
avg_rating_per_month <- edx_movies %>%
  group_by(t_month) %>%
  summarise(avg_rating = mean(rating)) %>%
  ungroup()
head(avg_rating_per_month)

# Average rating per year
avg_rating_per_year <- edx_movies %>%
  group_by(t_year) %>%
  summarise(avg_rating = mean(rating)) %>%
  ungroup()
head(avg_rating_per_year)

# Average rating per hour
avg_rating_per_hour <- edx_movies %>%
  group_by(t_year) %>%
  summarise(avg_rating = mean(rating)) %>%
  ungroup()
head(avg_rating_per_hour)

# Average rating per year of release
avg_rating_per_year_of_release <- edx_movies %>%
  group_by(year) %>%
  summarise(avg_rating = mean(rating)) %>%
  ungroup()
head(avg_rating_per_year_of_release)

# Average rating per title
avg_rating_per_title <- edx_movies %>%
  group_by(title) %>%
  summarise(avg_rating = mean(rating)) %>%
  ungroup()
head(avg_rating_per_title)

# Average rating per title
avg_rating_per_genres <- edx_movies %>%
  group_by(genres) %>%
  summarise(avg_rating = mean(rating)) %>%
  ungroup()
head(avg_rating_per_genres)
ggplot(avg_rating_per_genres, aes(x = avg_rating)) +
  geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
  xlim(x_limits) +
  scale_color_brewer(palette="Accent") + 
  theme_minimal() + theme(legend.position = "top") +
  labs(x = "Rating", y = "Genres")
x_limits <- c(0.5, 5)
plot_grid(
  ggplot(avg_rating_per_movie, aes(x = avg_rating)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Rating", y = "Movies"),
  
  ggplot(avg_rating_per_user, aes(x = avg_rating)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Rating", y = "Users"),
  
  ggplot(avg_rating_per_day_of_week, aes(x = avg_rating)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    xlim(x_limits) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Rating", y = "Days of Week"),
  
  ggplot(avg_rating_per_day, aes(x = avg_rating)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    xlim(x_limits) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Rating", y = "Days"),
  
  ggplot(avg_rating_per_month, aes(x = avg_rating)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    xlim(x_limits) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Rating", y = "Months"),
  
  ggplot(avg_rating_per_year, aes(x = avg_rating)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    xlim(x_limits) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Rating", y = "Years"),
  
  ggplot(avg_rating_per_hour, aes(x = avg_rating)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    xlim(x_limits) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Rating", y = "Hours"),
  
  ggplot(avg_rating_per_year_of_release, aes(x = avg_rating)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    xlim(x_limits) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Rating", y = "Years"),
  
  ggplot(avg_rating_per_title, aes(x = avg_rating)) +
    geom_histogram(color="darkred", fill="darkred", alpha = 0.1, position="dodge", bins = 30) +
    scale_color_brewer(palette="Accent") + 
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Rating", y = "Titles"),
  
  ncol = 3, align = 'hv', rel_heights = c(2, 2, 2))







































# Function to calculate average ratings
calculate_avg_rating <- function(data, grouping_var) {
  data %>%
    group_by(!!sym(grouping_var)) %>%
    summarise(avg_rating = mean(rating)) %>%
    ungroup()
}

# Variable names for grouping
grouping_vars <- c("movieId", "userId", "t_day_of_week", "t_day", 
                   "t_month", "t_year", "t_hour", "year", "title")

# Create a list to hold average rating data
avg_ratings_list <- lapply(grouping_vars, calculate_avg_rating, data = edx_movies)

# Function to create histogram plots
create_histogram <- function(data, label) {
  ggplot(data, aes(x = avg_rating)) +
    geom_histogram(color = "darkred", fill = "darkred", alpha = 0.1, position = "dodge", bins = 30) +
    xlim(c(0, 5)) +  # Set x-axis limits
    scale_color_brewer(palette = "Accent") +
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Rating", y = label)
}

# Labels corresponding to grouping_vars
labels <- c("Movies", "Users", "Days of Week", "Days", "Months", 
            "Years", "Hours", "Years of Release", "Titles")

# Create plots
plots <- mapply(create_histogram, avg_ratings_list, labels, SIMPLIFY = FALSE)

# Display plots in a grid
do.call("grid.arrange", c(plots, ncol = 3, top = "Distribution of Average Ratings"))












































# Function to calculate average ratings with NA handling
calculate_avg_rating <- function(data, grouping_var) {
  data %>%
    group_by(!!sym(grouping_var)) %>%
    summarise(avg_rating = mean(rating, na.rm = TRUE)) %>%
    filter(!is.na(avg_rating)) %>%
    ungroup()
}

# Variable names for grouping
grouping_vars <- c("movieId", "userId", "t_day_of_week", "t_day", 
                   "t_month", "t_year", "t_hour", "year", "title")

# Create a list to hold average rating data
avg_ratings_list <- lapply(grouping_vars, calculate_avg_rating, data = edx_movies)

# Function to create histogram plots with scale check
create_histogram <- function(data, label) {
  if (nrow(data) == 0) {
    stop(paste("No data available for", label))  # Ensure there's data for plotting
  }
  
  ggplot(data, aes(x = avg_rating)) +
    geom_histogram(color = "darkred", fill = "darkred", alpha = 0.1, position = "dodge", bins = 30) +
    xlim(c(0, 5)) +  # Set x-axis limits
    scale_color_brewer(palette = "Accent") +
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Rating", y = label)
}

# Labels for corresponding grouping_vars
labels <- c("Movies", "Users", "Days of Week", "Days", "Months", 
            "Years", "Hours", "Years of Release", "Titles")

# Create plots with error handling
plots <- vector("list", length(avg_ratings_list))
for (i in seq_along(avg_ratings_list)) {
  plots[[i]] <- tryCatch(
    create_histogram(avg_ratings_list[[i]], labels[i]),
    error = function(e) {
      message("Error in plotting: ", e$message)
      NULL  # Return NULL if there's an error
    }
  )
}

# Filter out NULL plots before displaying
plots <- Filter(Negate(is.null), plots)

# Display plots in a grid
do.call("grid.arrange", c(plots, ncol = 3, top = "Distribution of Average Ratings"))





















data_summary <- head(edx)
data_summary
# Replace '|' with ';' in the genres column
data_summary$genres <- gsub("\\|", ";", data_summary$genres)
data_summary
n
















# Function to calculate average ratings with NA handling
calculate_avg_rating <- function(data, grouping_var) {
  data %>%
    group_by(!!sym(grouping_var)) %>%
    summarise(avg_rating = mean(rating, na.rm = TRUE)) %>%
    filter(!is.na(avg_rating)) %>%
    ungroup()
}

# Variable names for grouping
grouping_vars <- c("movieId", "userId", "t_day_of_week", "t_day", 
                   "t_month", "t_year", "t_hour", "year", "title")

# Create a list to hold average rating data
avg_ratings_list <- lapply(grouping_vars, calculate_avg_rating, data = edx_movies)

# Function to create histogram plots
create_histogram <- function(data, label) {
  if (nrow(data) == 0) {
    stop(paste("No data available for", label))
  }
  
  # Check the range of avg_rating to avoid warnings
  rating_range <- range(data$avg_rating, na.rm = TRUE)
  
  ggplot(data, aes(x = avg_rating)) +
    geom_histogram(color = "darkred", fill = "darkred", alpha = 0.1, position = "dodge", bins = 30) +
    xlim(c(0, 5)) +
    scale_color_brewer(palette = "Accent") +
    theme_minimal() + theme(legend.position = "top") +
    labs(x = "Rating", y = label) +
    coord_cartesian(ylim = c(0, 20000)) # Extend the y-axis limit slightly
}

# Labels for corresponding grouping_vars
labels <- c("Movies", "Users", "Days of Week", "Days", "Months", 
            "Years", "Hours", "Years of Release", "Titles")

# Create plots with error handling
plots <- vector("list", length(avg_ratings_list))
for (i in seq_along(avg_ratings_list)) {
  plots[[i]] <- tryCatch(
    create_histogram(avg_ratings_list[[i]], labels[i]),
    error = function(e) {
      message("Error in plotting: ", e$message)
      NULL  # Return NULL if there's an error
    }
  )
}

# Filter out NULL plots before displaying
plots <- Filter(Negate(is.null), plots)

# Display plots in a grid
do.call("grid.arrange", c(plots, ncol = 3, top = "Distribution of Average Ratings"))