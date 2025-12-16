# MovieLens Project

# We add 2 columns :
# rating_year is extracted from timestamp and shows the year the rating was given,
# movie_year is extracted from the title and shows the year the movie was released.
movies <- edx %>%
  mutate(rating_year = 1970 + (timestamp %/% (365.25 * 24 * 3600))) %>%
  mutate(movie_year = as.integer(str_extract(title, "(?<=\\()\\d{4}(?=\\))")))
head(movies)



# Histogram of ratings per year :
# the graph shows that ratings started in 1995 until 2009
# and were relatively constants throughout the years.
#hist(movies$rating_year)
min(movies$rating_year)
max(movies$rating_year)
p <- ggplot(movies, aes(x=rating_year)) +
  geom_histogram(color="darkgreen", fill="lightgreen", position="dodge", xName="weight")
p + scale_color_brewer(palette="Accent") + 
  theme_minimal() + theme(legend.position = "top") +
  xlim(1910, 2010) + labs(title = "Number of ratings per year", x = "year")

# Histogram of rated movies per year :
# the graph shows a small amount of movies rated prior to the 1980s
# and the highest numbers in the 1990s.
#hist(movies$movie_year)
min(movies$movie_year)
max(movies$movie_year)
p <- ggplot(movies, aes(x=movie_year)) +
  geom_histogram(color="darkblue", fill="lightblue", position="dodge")
p + scale_color_brewer(palette="Accent") + 
  theme_minimal()+theme(legend.position="top") +
  xlim(1910, 2010) + labs(title = "Number of ratings / Year of movie released", x = "year")

# Histogram of time elapsed between the year a movie was released and the year it was rated :
# this graph shows most of the ratings were given within 10 years of the release of the movies.
#hist(movies$rating_year - movies$movie_year)
min(movies$rating_year - movies$movie_year)
max(movies$rating_year - movies$movie_year)
p <- ggplot(movies, aes(x=rating_year - movie_year)) +
  geom_histogram(color="darkorange", fill="orange", position="dodge")
p + scale_color_brewer(palette="Accent") + 
  theme_minimal() + theme(legend.position="top") +
  labs(title = "Number of ratings / Years between movie released and rating given", x = "year")

# Histogram of movies :
# a small amount of movies got the most ratings, most of them didn't get much ratings.
p <- ggplot(movies, aes(x=movieId)) +
  geom_histogram(color="darkred", fill="red", position="dodge")
p + scale_color_brewer(palette="Accent") + 
  theme_minimal() + theme(legend.position="top") +
  labs(title = "Number of ratings / Movie", x = "Movie ID")

# Histogram of ratings : most ratings are 3 and 4
hist(movies$rating)
# Histogram of ratings per users : the numbers are approximately the same
hist(movies$userId)
