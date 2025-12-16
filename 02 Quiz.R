# Quiz : MovieLens dataset
str(edx)
edx %>% filter(edx$rating == 0.0)

n_zero <- edx %>% filter(edx$rating == 0.0)
nrow(n_zero)

n_three <- edx %>% filter(edx$rating == 3.0)
nrow(n_three)

length(unique(edx$movieId))
length(unique(edx$userId))

edx %>% filter(grepl("Drama", genres)) %>% tally()
edx %>% filter(grepl("Comedy", genres)) %>% tally()
edx %>% filter(grepl("Thriller", genres)) %>% tally()
edx %>% filter(grepl("Romance", genres)) %>% tally()

# str_detect
genres = c("Drama", "Comedy", "Thriller", "Romance")
sapply(genres, function(g) {
  sum(str_detect(edx$genres, g))
})

# separate_rows, much slower!
edx %>% separate_rows(genres, sep = "\\|") %>%
  group_by(genres) %>%
  summarize(count = n()) %>%
  arrange(desc(count))


edx %>% arrange(desc(rating))
head(edx)
edx %>% filter(title == "Forrest Gump")
edx %>% filter(title == "Jurassic Park")
edx %>% filter(title == "Pulp Fiction")
edx %>% filter(title == "The Shawshank Redemption")
edx %>% filter(title == "Speed 2: Cruise Control")

edx %>% filter(str_detect(edx$title, "Forrest Gump")) %>% summarise(n = mean(rating))
edx %>% filter(str_detect(edx$title, "Jurassic Park")) %>% summarise(n = mean(rating))
edx %>% filter(str_detect(edx$title, "Pulp Fiction")) %>% summarise(n = mean(rating))
edx %>% filter(str_detect(edx$title, "The Shawshank Redemption") & !is.na(rating)) %>% summarise(n = mean(rating))
edx %>% filter(str_detect(edx$title, "Speed 2: Cruise Control")) %>% summarise(n = mean(rating))

edx %>% group_by(movieId, title) %>%
  summarize(count = n()) %>%
  arrange(desc(count))

edx %>% group_by(rating) %>%
  summarize(count = n()) %>%
  arrange(desc(count))

edx %>%
  group_by(rating) %>%
  summarize(count = n()) %>%
  ggplot(aes(x = rating, y = count)) +
  geom_line()

head(edx)

# End of Quiz : MovieLens dataset
