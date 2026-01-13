# PH125.9x-Data-Science-MovieLens
The purpose of this document is to explain how to create a movie recommendation system using the MovieLens dataset.
During the PH125.8x: Data Science: Machine Learning course, the dataset used was from the the dslabs package. For this exercise, we will use a 10M rows dataset available here :

>https://grouplens.org/datasets/movielens/10m/

The history and context of this dataset are available here :


>F. Maxwell Harper and Joseph A. Konstan. 2015. The MovieLens Datasets: History and Context. ACM Transactions on Interactive Intelligent Systems (TiiS) 5, 4, Article 19 (December 2015), 19 pages. DOI=http://dx.doi.org/10.1145/2827872

First we will setup the environment and download and generate the dataset, then we will analyse the data, and finally we will train a machine learning algorithm using the inputs in the first subset (edx) to predict the movie ratings in the validation set (final_holdout_test).

The goal of this exercise is to be able to predict the movie ratings in the test set with a root mean square error (RMSE) lower than **0.86490**.

This task is inspired by the Netflix challenge, which aimed to predict ratings without utilizing any user data (such as age or gender) due to privacy concerns. Ultimately, the goal is to predict which films a user would enjoy based on their previous ratings.
