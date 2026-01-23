README for Movie Rating Prediction Project

Overview

This project, titled "Movie Rating Prediction," aims to explore and create a movie recommendation system using the MovieLens dataset. The dataset utilized contains approximately 10 million ratings, and the objective is to predict movie ratings with a root mean square error (RMSE) lower than 0.86490.

Author : Jean-Marie Roy
Date : December 16, 2025

Requirements

To run this project, ensure you have the following packages installed:

    install.packages(c("dplyr", "ggplot2", "knitr", "kableExtra", "tidyverse"))

Running the Analysis

Setup Environment:

  The setup and MovieLens script can be executed separately for efficiency.

  Use the following command to render the entire document:

    rmarkdown::render("MovieLens.Rmd")

  Alternatively, you can include scripts directly by uncommenting the source lines in the setup code chunk.

Data Sources:
  The MovieLens dataset can be downloaded from MovieLens 10M Dataset.
  Background context can be referred to in the paper by F. Maxwell Harper and Joseph A. Konstan (2015).

This project illustrates a systematic approach to developing a movie recommendation system while following data science principles and techniques. The analysis provides insights into user behavior, movie ratings, and factors influencing the predictions, rounded out with exploratory data analysis and necessary transformations for effective modeling.

For a complete exploration, refer to the provided R Markdown document, which contains detailed code and outputs for each step in the process.
License

This project is licensed under the MIT License - see the LICENSE file for details.