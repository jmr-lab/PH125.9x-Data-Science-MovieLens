MovieLens Recommendation ProjectAuthor: Jean‑Marie Roy | Date: 2025‑12‑16 | Version: 1.0
This repository contains everything needed to reproduce a movie‑rating prediction model built on the MovieLens 10 M data set. The goal is to predict user ratings with a root‑mean‑square error (RMSE) ≤ 0.86490. The final model achieves an RMSE of 0.8579873 on the hold‑out test set.

Repository Layout
├── README.md                ← This file
├── MovieLens.Rmd            ← R Markdown notebook (analysis + narrative)
├── MovieLens.pdf            ← Rendered PDF version of the notebook
├── 01_Setup.R               ← Data download, cleaning, and train/test split
├── 03_MovieLens.R           ← Core modelling code (biases, regularisation, clamping)
├── data/
│   ├── ml-10M100K/          ← Raw MovieLens files (downloaded automatically)
│   └── edx.rds              ← Pre‑processed training set (saved by 01_Setup.R)
├── results/
│   └── rmse_plot.png        ← Plot of RMSE vs. λ (included for reference)
└── .Rprofile                ← Optional: sets knitr options for reproducibility

All R scripts are written for R ≥ 4.0 and use the tidyverse ecosystem.

What the Project Does


Download & Prepare the Data

Retrieves the MovieLens 10 M zip file from https://grouplens.org/datasets/movielens/10m/.
Parses ratings.dat and movies.dat, merges them, and creates two data frames:

edx – 90 % of the records (training set).
final_holdout_test – 10 % of the records (validation set).


Guarantees that every user‑movie pair appearing in the test set also exists in the training set.



Feature Engineering

Extracts temporal components from the Unix timestamp (day_of_week, day, month, year, hour).
Splits the title field into title (cleaned) and release_year.
Keeps the original genres column (semicolon‑separated) for potential future use.



Exploratory Data Analysis (EDA)

Summary statistics for users, movies, and ratings.
Visualisations of rating distributions, popularity of movies/users, and temporal trends.
Counts of distinct values for each variable.



Modelling Strategy – Bias‑Based Regularised Regression

Global mean rating: μ.
Single‑bias models (movie, user, genre, timestamp‑year, release‑year).
Two‑bias model (movie + user).
Three‑bias model (movie + user + year‑title).
Regularisation: each bias is shrunk by a penalty λ (optimal λ ≈ 0.5).
Clamping: predicted values are forced into the realistic rating interval [0.93, 4.64].



Evaluation

RMSE is computed with caret::RMSE.
Table of results (rounded to six decimals) is produced in the R Markdown file.



ModelRMSETarget (required)0.864900Global average1.060331Movie bias only0.942348Movie + User bias (no reg.)0.876753All three biases (regularised)0.841713All three biases + clamping0.841222Final test set (clamped)0.857987
The final model comfortably beats the target threshold.

How to Reproduce the Analysis


Clone the Repository
git clone https://github.com/<your‑username>/movielens-recommendation.git
cd movielens-recommendation


Install Required Packages (run once)
install.packages(c(
  "tidyverse", "lubridate", "caret", "knitr", "kableExtra",
  "ggplot2", "cowplot", "scales", "scatterplot3d"
))


Run the Setup Script – this downloads the data, creates the train/test split, and saves the intermediate objects.
source("01_Setup.R")
The script creates edx.rds and final_holdout_test.rds in the data/ folder.


Execute the Modelling Script (optional – the R Markdown already runs it)
source("03_MovieLens.R")
This script computes all bias terms, selects the optimal λ, clamps predictions, and prints the final RMSE.


Render the Report (produces both HTML and PDF)
rmarkdown::render("MovieLens.Rmd", output_format = c("html_document", "pdf_document"))
The rendered HTML is saved as MovieLens.html; the PDF version is already committed as MovieLens.pdf.



Dependencies & Versions (as of 2025‑12‑16)
PackageVersion Usedtidyverse2.0.0lubridate1.9.3caret6.0‑94knitr1.45kableExtra1.4.0ggplot23.5.0cowplot1.1.1scales1.3.0scatterplot3d0.3‑43
If you encounter version conflicts, updating to the latest CRAN releases generally works because the code relies only on stable APIs.

Key Take‑aways

Bias‑based regularisation is sufficient to beat the competition baseline without resorting to computationally intensive matrix factorisation or deep learning.
Clamping predictions to the feasible rating range (0.93 – 4.64) yields a noticeable RMSE improvement.
The three‑bias model (movie, user, year‑title) with λ = 0.5 attains the best performance on the training data (RMSE ≈ 0.8417).
On the unseen hold‑out set, the final RMSE is 0.8579873, satisfying the project requirement (≤ 0.86490).

Future Work

Two‑stage modeling – first classify whether a rating will be a half‑star or a full‑star, then apply separate bias‑adjusted regressions for each group.
Incorporate genre embeddings or collaborative‑filtering techniques (e.g., matrix factorisation) to capture higher‑order interactions.
Hyper‑parameter optimisation with Bayesian methods to fine‑tune λ and the clamping thresholds.


License
The code in this repository is released under the MIT License.
The MovieLens data set is provided under the GroupLens Research license (see https://grouplens.org/datasets/movielens/10m/ for details).
