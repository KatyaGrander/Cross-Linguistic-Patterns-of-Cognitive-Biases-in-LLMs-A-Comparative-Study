#-------------------------------------------------------------------------------
# 1. SETUP: LOAD PACKAGES
#-------------------------------------------------------------------------------
library(tidyverse)
library(rstatix)
library(vcd)
library(readxl)
library(logistf)

#-------------------------------------------------------------------------------
# 2. CONFIGURATION
#-------------------------------------------------------------------------------

# UPDATED: Main Excel file
main_file_path <- "Final_Project_Data.xlsx"

# Sheet to analyze (unchanged)
sheet_to_analyze <- "ConfirmationBias_RUS_NEW"

# Column names (unchanged)
gpt_col_name    <- "GPT_true_OR_false"
claude_col_name <- "Claude_true_OR_false"
gemini_col_name <- "Gemini_true_OR_false"
human_col_name  <- "Human_true_OR_false"

#-------------------------------------------------------------------------------
# 3. DATA PREPARATION
#-------------------------------------------------------------------------------

data_raw <- read_excel(main_file_path, sheet = sheet_to_analyze)

data_long <- data_raw |>
  select(all_of(c(human_col_name, gpt_col_name, claude_col_name, gemini_col_name))) |>
  pivot_longer(
    cols = everything(),
    names_to = "Source_Original",
    values_to = "Correctness"
  )

analysis_data <- data_long |>
  mutate(
    Source = case_when(
      Source_Original == human_col_name  ~ "Human",
      Source_Original == gpt_col_name    ~ "ChatGPT",
      Source_Original == claude_col_name ~ "Claude",
      Source_Original == gemini_col_name ~ "Gemini"
    ),
    Is_Correct_Binary = ifelse(Correctness == TRUE, 1, 0),
    Source = factor(Source, levels = c("Human", "ChatGPT", "Claude", "Gemini"))
  )

#-------------------------------------------------------------------------------
# 4. ANALYSIS 1 & 2: CHI-SQUARE, POST-HOC, & EFFECT SIZE
#-------------------------------------------------------------------------------

contingency_table <- table(analysis_data$Source, analysis_data$Correctness)

cat("--- CONTINGENCY TABLE ---\n")
print(contingency_table)

cat("\n--- CHI-SQUARE TEST ---\n")
print(chisq.test(contingency_table))

cat("\n--- POST-HOC PAIRWISE TESTS ---\n")
print(pairwise_prop_test(contingency_table, p.adjust.method = "bonferroni"))

cat("\n--- EFFECT SIZE (CRAMER'S V) ---\n")
print(assocstats(contingency_table))

#-------------------------------------------------------------------------------
# 5. ANALYSIS 3: LOGISTIC REGRESSION
#-------------------------------------------------------------------------------

logistic_model <- glm(
  Is_Correct_Binary ~ Source,
  data = analysis_data,
  family = "binomial"
)

cat("\n--- LOGISTIC REGRESSION MODEL SUMMARY ---\n")
print(summary(logistic_model))

cat("\n--- ODDS RATIOS ---\n")
print(exp(coef(logistic_model)))

#-------------------------------------------------------------------------------
# 6. ANALYSIS 4: FIRTH PENALIZED REGRESSION
#-------------------------------------------------------------------------------

firth_model <- logistf(
  Is_Correct_Binary ~ Source,
  data = analysis_data
)

cat("\n--- FIRTH PENALIZED LOGISTIC REGRESSION SUMMARY ---\n")
print(summary(firth_model))

cat("\n--- FIRTH ODDS RATIOS (with 95% CI) ---\n")
firth_or <- exp(coef(firth_model))
firth_ci <- exp(confint(firth_model))
print(cbind("OR" = firth_or, firth_ci))