# Load required packages
library(dplyr)
library(foreach)
library(doParallel)

lambdas <- seq(0, 1, 0.1)
get_rmse <- function(lambda) {
  b_m_reg <- edx_movies %>%
    group_by(movieId) %>%
    summarise(b_m_reg = sum(rating - mu) / (n() + lambda))
  
  edx_movies_temp <- edx_movies %>% left_join(b_m_reg, by = "movieId")
  
  b_mu_reg <- edx_movies_temp %>%
    group_by(userId) %>%
    summarise(b_mu_reg = sum(rating - mu - b_m_reg) / (n() + lambda))
  
  edx_movies_temp <- edx_movies_temp %>% left_join(b_mu_reg, by = "userId")
  
  # Calculate RMSE
  RMSE(edx_movies_temp$rating, mu + edx_movies_temp$b_m_reg + edx_movies_temp$b_mu_reg)
#  Sys.sleep(10)
}

start_time <- Sys.time()
rmse_arr <- sapply(lambdas, get_rmse)
end_time <- Sys.time()
as.numeric(difftime(end_time, start_time, units = "secs"))


# Load required packages
library(dplyr)
library(foreach)
library(doParallel)

start_time <- Sys.time()
cl <- makeCluster(detectCores() - 1)
clusterExport(cl,list("edx_movies","mu","RMSE"),envir=globalenv())
clusterEvalQ(cl, library(dplyr))
results <- parLapply(cl, lambdas, get_rmse)
stopCluster(cl)
print(results)
end_time <- Sys.time()
as.numeric(difftime(end_time, start_time, units = "secs"))
