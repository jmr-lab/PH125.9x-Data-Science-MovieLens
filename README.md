<h1>MovieLens Recommendation Project</h1><div class="content-visibility-auto"><p><strong>Author:</strong> Jean‑Marie Roy | <strong>Date:</strong> 2025‑12‑16 | <strong>Version:</strong> 1.0</p>
<p>This repository contains everything needed to reproduce a <strong>movie‑rating prediction model</strong> built on the <strong>MovieLens 10 M</strong> data set. The goal is to predict user ratings with a <strong>root‑mean‑square error (RMSE) ≤ 0.86490</strong>. The final model achieves an RMSE of <strong>0.8579873</strong> on the hold‑out test set.</p>
<hr>
<h2>Repository Layout</h2>
<pre><code>├── README.md                ← This file
├── MovieLens.Rmd            ← R Markdown notebook (analysis + narrative)
├── MovieLens.pdf            ← Rendered PDF version of the notebook
├── 01_Setup.R               ← Data download, cleaning, and train/test split
└── 03_MovieLens.R           ← Core modelling code (biases, regularisation, clamping)
</code></pre>
<p><em>All R scripts are written for <strong>R ≥ 4.0</strong> and use the tidyverse ecosystem.</em></p>
<hr>
<h2>What the Project Does</h2>
<ol>
<li>
<p><strong>Download &amp; Prepare the Data</strong></p>
<ul>
<li>Retrieves the MovieLens 10 M zip file from <a href="https://grouplens.org/datasets/movielens/10m/">https://grouplens.org/datasets/movielens/10m/</a>.</li>
<li>Parses <code>ratings.dat</code> and <code>movies.dat</code>, merges them, and creates two data frames:
<ul>
<li><code>edx</code> – 90 % of the records (training set).</li>
<li><code>final_holdout_test</code> – 10 % of the records (validation set).</li>
</ul>
</li>
<li>Guarantees that every user‑movie pair appearing in the test set also exists in the training set.</li>
</ul>
</li>
<li>
<p><strong>Feature Engineering</strong></p>
<ul>
<li>Extracts temporal components from the Unix timestamp (<code>day_of_week</code>, <code>day</code>, <code>month</code>, <code>year</code>, <code>hour</code>).</li>
<li>Splits the <code>title</code> field into <code>title</code> (cleaned) and <code>release_year</code>.</li>
<li>Keeps the original <code>genres</code> column (semicolon‑separated) for potential future use.</li>
</ul>
</li>
<li>
<p><strong>Exploratory Data Analysis (EDA)</strong></p>
<ul>
<li>Summary statistics for users, movies, and ratings.</li>
<li>Visualisations of rating distributions, popularity of movies/users, and temporal trends.</li>
<li>Counts of distinct values for each variable.</li>
</ul>
</li>
<li>
<p><strong>Modelling Strategy – Bias‑Based Regularised Regression</strong></p>
<ul>
<li>Global mean rating: <code>μ</code>.</li>
<li><strong>Single‑bias models</strong> (movie, user, genre, timestamp‑year, release‑year).</li>
<li><strong>Two‑bias model</strong> (movie + user).</li>
<li><strong>Three‑bias model</strong> (movie + user + year‑title).</li>
<li><strong>Regularisation</strong>: each bias is shrunk by a penalty <code>λ</code> (optimal <code>λ ≈ 0.5</code>).</li>
<li><strong>Clamping</strong>: predicted values are forced into the realistic rating interval <code>[0.93, 4.64]</code>.</li>
</ul>
</li>
<li>
<p><strong>Evaluation</strong></p>
<ul>
<li>RMSE is computed with <code>caret::RMSE</code>.</li>
<li>Table of results (rounded to six decimals) is produced in the R Markdown file.</li>
</ul>
</li>
</ol>
<div class="markdown-table-wrapper"><table node="[object Object]"><thead><tr><th>Model</th><th style="text-align: right;">RMSE</th></tr></thead><tbody><tr><td>Target (required)</td><td style="text-align: right;">0.864900</td></tr><tr><td>Global average</td><td style="text-align: right;">1.060331</td></tr><tr><td>Movie bias only</td><td style="text-align: right;">0.942348</td></tr><tr><td>Movie + User bias (no reg.)</td><td style="text-align: right;">0.876753</td></tr><tr><td>All three biases (regularised)</td><td style="text-align: right;"><strong>0.841713</strong></td></tr><tr><td>All three biases + clamping</td><td style="text-align: right;"><strong>0.841222</strong></td></tr><tr><td><strong>Final test set</strong> (clamped)</td><td style="text-align: right;"><strong>0.857987</strong></td></tr></tbody></table></div>
<p>The final model comfortably beats the target threshold.</p>
<hr>
<h2>How to Reproduce the Analysis</h2>
<ol>
<li>
<p><strong>Clone the Repository</strong></p>
<pre><div class="message-container code-container relative"><div class="flex flex-row flex-nowrap"><div class="flex-auto"><div style="background: rgb(250, 250, 250); color: rgb(56, 58, 66); font-family: &quot;Fira Code&quot;, &quot;Fira Mono&quot;, Menlo, Consolas, &quot;DejaVu Sans Mono&quot;, monospace; direction: ltr; text-align: left; white-space: pre; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none; padding: 1em; margin: 0.5em 0px; overflow: auto; border-radius: 0.3em;"><code class="language-bash" style="white-space: pre; background: rgb(250, 250, 250); color: rgb(56, 58, 66); font-family: &quot;Fira Code&quot;, &quot;Fira Mono&quot;, Menlo, Consolas, &quot;DejaVu Sans Mono&quot;, monospace; direction: ltr; text-align: left; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none;"><span><span class="token" style="color: rgb(64, 120, 242);">git</span><span> clone https://github.com/</span><span class="token" style="color: rgb(64, 120, 242);">&lt;</span><span>your‑username</span><span class="token" style="color: rgb(64, 120, 242);">&gt;</span><span>/movielens-recommendation.git
</span></span><span><span></span><span class="token" style="color: rgb(183, 107, 1);">cd</span><span> movielens-recommendation</span></span></code></div></div></div><div class="lumo-no-copy absolute top-0 right-0 z-10" style="transform: translate(4px, -4px);"><button class="button button-for-icon button-small button-ghost-weak" aria-busy="false" type="button" aria-label="Copy" aria-describedby="tooltip-324"><svg viewBox="0 0 16 16" class="icon-size-4" role="img" focusable="false" aria-hidden="true"><use xlink:href="#ic-squares"></use></svg></button></div></div></pre>
</li>
<li>
<p><strong>Install Required Packages</strong> (run once)</p>
<pre><div class="message-container code-container relative"><div class="flex flex-row flex-nowrap"><div class="flex-auto"><div style="background: rgb(250, 250, 250); color: rgb(56, 58, 66); font-family: &quot;Fira Code&quot;, &quot;Fira Mono&quot;, Menlo, Consolas, &quot;DejaVu Sans Mono&quot;, monospace; direction: ltr; text-align: left; white-space: pre; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none; padding: 1em; margin: 0.5em 0px; overflow: auto; border-radius: 0.3em;"><code class="language-r" style="white-space: pre; background: rgb(250, 250, 250); color: rgb(56, 58, 66); font-family: &quot;Fira Code&quot;, &quot;Fira Mono&quot;, Menlo, Consolas, &quot;DejaVu Sans Mono&quot;, monospace; direction: ltr; text-align: left; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none;"><span><span>install.packages</span><span class="token" style="color: rgb(56, 58, 66);">(</span><span>c</span><span class="token" style="color: rgb(56, 58, 66);">(</span><span>
</span></span><span><span>  </span><span class="token" style="color: rgb(80, 161, 79);">"tidyverse"</span><span class="token" style="color: rgb(56, 58, 66);">,</span><span> </span><span class="token" style="color: rgb(80, 161, 79);">"lubridate"</span><span class="token" style="color: rgb(56, 58, 66);">,</span><span> </span><span class="token" style="color: rgb(80, 161, 79);">"caret"</span><span class="token" style="color: rgb(56, 58, 66);">,</span><span> </span><span class="token" style="color: rgb(80, 161, 79);">"knitr"</span><span class="token" style="color: rgb(56, 58, 66);">,</span><span> </span><span class="token" style="color: rgb(80, 161, 79);">"kableExtra"</span><span class="token" style="color: rgb(56, 58, 66);">,</span><span>
</span></span><span><span>  </span><span class="token" style="color: rgb(80, 161, 79);">"ggplot2"</span><span class="token" style="color: rgb(56, 58, 66);">,</span><span> </span><span class="token" style="color: rgb(80, 161, 79);">"cowplot"</span><span class="token" style="color: rgb(56, 58, 66);">,</span><span> </span><span class="token" style="color: rgb(80, 161, 79);">"scales"</span><span class="token" style="color: rgb(56, 58, 66);">,</span><span> </span><span class="token" style="color: rgb(80, 161, 79);">"scatterplot3d"</span><span>
</span></span><span><span></span><span class="token" style="color: rgb(56, 58, 66);">)</span><span class="token" style="color: rgb(56, 58, 66);">)</span></span></code></div></div></div><div class="lumo-no-copy absolute top-0 right-0 z-10" style="transform: translate(4px, -4px);"><button class="button button-for-icon button-small button-ghost-weak" aria-busy="false" type="button" aria-label="Copy" aria-describedby="tooltip-325"><svg viewBox="0 0 16 16" class="icon-size-4" role="img" focusable="false" aria-hidden="true"><use xlink:href="#ic-squares"></use></svg></button></div></div></pre>
</li>
<li>
<p><strong>Run the Setup Script</strong> – this downloads the data, creates the train/test split, and saves the intermediate objects.</p>
<pre><div class="message-container code-container relative"><div class="flex flex-row flex-nowrap"><div class="flex-auto"><div style="background: rgb(250, 250, 250); color: rgb(56, 58, 66); font-family: &quot;Fira Code&quot;, &quot;Fira Mono&quot;, Menlo, Consolas, &quot;DejaVu Sans Mono&quot;, monospace; direction: ltr; text-align: left; white-space: pre; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none; padding: 1em; margin: 0.5em 0px; overflow: auto; border-radius: 0.3em;"><code class="language-r" style="white-space: pre; background: rgb(250, 250, 250); color: rgb(56, 58, 66); font-family: &quot;Fira Code&quot;, &quot;Fira Mono&quot;, Menlo, Consolas, &quot;DejaVu Sans Mono&quot;, monospace; direction: ltr; text-align: left; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none;"><span><span>source</span><span class="token" style="color: rgb(56, 58, 66);">(</span><span class="token" style="color: rgb(80, 161, 79);">"01_Setup.R"</span><span class="token" style="color: rgb(56, 58, 66);">)</span></span></code></div></div></div><div class="lumo-no-copy absolute top-0 right-0 z-10" style="transform: translate(4px, -4px);"><button class="button button-for-icon button-small button-ghost-weak" aria-busy="false" type="button" aria-label="Copy" aria-describedby="tooltip-326"><svg viewBox="0 0 16 16" class="icon-size-4" role="img" focusable="false" aria-hidden="true"><use xlink:href="#ic-squares"></use></svg></button></div></div></pre>
<p><em>The script creates <code>edx.rds</code> and <code>final_holdout_test.rds</code> in the <code>data/</code> folder.</em></p>
</li>
<li>
<p><strong>Execute the Modelling Script</strong> (optional – the R Markdown already runs it)</p>
<pre><div class="message-container code-container relative"><div class="flex flex-row flex-nowrap"><div class="flex-auto"><div style="background: rgb(250, 250, 250); color: rgb(56, 58, 66); font-family: &quot;Fira Code&quot;, &quot;Fira Mono&quot;, Menlo, Consolas, &quot;DejaVu Sans Mono&quot;, monospace; direction: ltr; text-align: left; white-space: pre; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none; padding: 1em; margin: 0.5em 0px; overflow: auto; border-radius: 0.3em;"><code class="language-r" style="white-space: pre; background: rgb(250, 250, 250); color: rgb(56, 58, 66); font-family: &quot;Fira Code&quot;, &quot;Fira Mono&quot;, Menlo, Consolas, &quot;DejaVu Sans Mono&quot;, monospace; direction: ltr; text-align: left; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none;"><span><span>source</span><span class="token" style="color: rgb(56, 58, 66);">(</span><span class="token" style="color: rgb(80, 161, 79);">"03_MovieLens.R"</span><span class="token" style="color: rgb(56, 58, 66);">)</span></span></code></div></div></div><div class="lumo-no-copy absolute top-0 right-0 z-10" style="transform: translate(4px, -4px);"><button class="button button-for-icon button-small button-ghost-weak" aria-busy="false" type="button" aria-label="Copy" aria-describedby="tooltip-327"><svg viewBox="0 0 16 16" class="icon-size-4" role="img" focusable="false" aria-hidden="true"><use xlink:href="#ic-squares"></use></svg></button></div></div></pre>
<p>This script computes all bias terms, selects the optimal <code>λ</code>, clamps predictions, and prints the final RMSE.</p>
</li>
<li>
<p><strong>Render the Report</strong> (produces both HTML and PDF)</p>
<pre><div class="message-container code-container relative"><div class="flex flex-row flex-nowrap"><div class="flex-auto"><div style="background: rgb(250, 250, 250); color: rgb(56, 58, 66); font-family: &quot;Fira Code&quot;, &quot;Fira Mono&quot;, Menlo, Consolas, &quot;DejaVu Sans Mono&quot;, monospace; direction: ltr; text-align: left; white-space: pre; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none; padding: 1em; margin: 0.5em 0px; overflow: auto; border-radius: 0.3em;"><code class="language-r" style="white-space: pre; background: rgb(250, 250, 250); color: rgb(56, 58, 66); font-family: &quot;Fira Code&quot;, &quot;Fira Mono&quot;, Menlo, Consolas, &quot;DejaVu Sans Mono&quot;, monospace; direction: ltr; text-align: left; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none;"><span><span>rmarkdown</span><span class="token" style="color: rgb(64, 120, 242);">::</span><span>render</span><span class="token" style="color: rgb(56, 58, 66);">(</span><span class="token" style="color: rgb(80, 161, 79);">"MovieLens.Rmd"</span><span class="token" style="color: rgb(56, 58, 66);">,</span><span> output_format </span><span class="token" style="color: rgb(64, 120, 242);">=</span><span> c</span><span class="token" style="color: rgb(56, 58, 66);">(</span><span class="token" style="color: rgb(80, 161, 79);">"html_document"</span><span class="token" style="color: rgb(56, 58, 66);">,</span><span> </span><span class="token" style="color: rgb(80, 161, 79);">"pdf_document"</span><span class="token" style="color: rgb(56, 58, 66);">)</span><span class="token" style="color: rgb(56, 58, 66);">)</span></span></code></div></div></div><div class="lumo-no-copy absolute top-0 right-0 z-10" style="transform: translate(4px, -4px);"><button class="button button-for-icon button-small button-ghost-weak" aria-busy="false" type="button" aria-label="Copy" aria-describedby="tooltip-328"><svg viewBox="0 0 16 16" class="icon-size-4" role="img" focusable="false" aria-hidden="true"><use xlink:href="#ic-squares"></use></svg></button></div></div></pre>
<p>The rendered HTML is saved as <code>MovieLens.html</code>; the PDF version is already committed as <code>MovieLens.pdf</code>.</p>
</li>
</ol>
<hr>
<h2>Dependencies &amp; Versions (as of 2025‑12‑16)</h2>
<div class="markdown-table-wrapper"><table node="[object Object]"><thead><tr><th>Package</th><th>Version Used</th></tr></thead><tbody><tr><td>tidyverse</td><td>2.0.0</td></tr><tr><td>lubridate</td><td>1.9.3</td></tr><tr><td>caret</td><td>6.0‑94</td></tr><tr><td>knitr</td><td>1.45</td></tr><tr><td>kableExtra</td><td>1.4.0</td></tr><tr><td>ggplot2</td><td>3.5.0</td></tr><tr><td>cowplot</td><td>1.1.1</td></tr><tr><td>scales</td><td>1.3.0</td></tr><tr><td>scatterplot3d</td><td>0.3‑43</td></tr></tbody></table></div>
<p>If you encounter version conflicts, updating to the latest CRAN releases generally works because the code relies only on stable APIs.</p>
<hr>
<h2>Key Take‑aways</h2>
<ul>
<li><strong>Bias‑based regularisation</strong> is sufficient to beat the competition baseline without resorting to computationally intensive matrix factorisation or deep learning.</li>
<li><strong>Clamping</strong> predictions to the feasible rating range (0.93 – 4.64) yields a noticeable RMSE improvement.</li>
<li>The <strong>three‑bias model</strong> (movie, user, year‑title) with <code>λ = 0.5</code> attains the best performance on the training data (RMSE ≈ 0.8417).</li>
<li>On the unseen hold‑out set, the final RMSE is <strong>0.8579873</strong>, satisfying the project requirement (≤ 0.86490).</li>
</ul>
<h3>Future Work</h3>
<ul>
<li><strong>Two‑stage modeling</strong> – first classify whether a rating will be a half‑star or a full‑star, then apply separate bias‑adjusted regressions for each group.</li>
<li>Incorporate <strong>genre embeddings</strong> or <strong>collaborative‑filtering</strong> techniques (e.g., matrix factorisation) to capture higher‑order interactions.</li>
<li>Hyper‑parameter optimisation with Bayesian methods to fine‑tune <code>λ</code> and the clamping thresholds.</li>
</ul>
<hr>
<h2>License</h2>
<p>The code in this repository is released under the <strong>MIT License</strong>.<br>
The MovieLens data set is provided under the <strong>GroupLens Research</strong> license (see <a href="https://grouplens.org/datasets/movielens/10m/">https://grouplens.org/datasets/movielens/10m/</a> for details).</p>
