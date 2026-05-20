#-------------------------------------------------------------------------------
# 1. SETUP: LOAD PACKAGES
#-------------------------------------------------------------------------------
library(tidyverse)
library(rstatix)
library(vcd)
library(readxl)
library(logistf)
library(irr)

#-------------------------------------------------------------------------------
# 2. CONFIGURATION
#-------------------------------------------------------------------------------

# UPDATED: Main Excel file
main_file_path <- "Final_Project_Data.xlsx"

# Sheet to analyze (unchanged)
sheet_to_analyze <- "IRR_Relevance"

# Column names (unchanged)
owft_col_name <- "OWFT"
mwft_col_name <- "MWFT"
mwst_col_name <- "MWST"

# G-item column names
# g_cols <- paste0("G", 1:11)

#-------------------------------------------------------------------------------
# 3. LOAD DATA
#-------------------------------------------------------------------------------

raw_data <- read_excel(main_file_path, sheet = sheet_to_analyze)

cat("=== Raw Data ===\n")
print(raw_data)
cat("\n")

#-------------------------------------------------------------------------------
# 4. PREPARE RATER MATRIX
#    Orientation: rows = judges, columns = tasks
#    kripp.alpha()   expects rows = raters,   columns = subjects  -> use as-is
#    kappam.fleiss() expects rows = subjects, columns = raters    -> use t()
#-------------------------------------------------------------------------------

task_cols <- c(owft_col_name, mwft_col_name, mwst_col_name) #g_cols,

rater_matrix <- raw_data |>
  select(all_of(task_cols)) |>
  as.matrix()

rownames(rater_matrix) <- raw_data[[1]]  # first column holds judge IDs

# --- Orientation check ---
stopifnot(
  "Rows must be judges" = all(rownames(rater_matrix) %in% raw_data[[1]]),
  "Columns must be tasks" = all(colnames(rater_matrix) == task_cols)
)

# --- Likert scale check (1–5) ---
cell_min <- min(rater_matrix, na.rm = TRUE)
cell_max <- max(rater_matrix, na.rm = TRUE)
if (cell_min < 1 || cell_max > 5) {
  stop(sprintf(
    "Values outside 1-5 Likert range: min = %g, max = %g",
    cell_min, cell_max
  ))
}

cat("=== Rater Matrix (rows = judges, columns = tasks) ===\n")
cat(sprintf("Dimensions: %d judges x %d tasks\n",
            nrow(rater_matrix), ncol(rater_matrix)))
cat(sprintf("Value range: %g - %g  [expected: 1-5 Likert]\n",
            cell_min, cell_max))
print(rater_matrix)
cat("\n")

#-------------------------------------------------------------------------------
# 5. KRIPPENDORFF'S ALPHA
#    method = "ordinal" is appropriate for ordinal / Likert-type ratings.
#    Change to "nominal" for categorical, "interval" for continuous scales.
#-------------------------------------------------------------------------------

alpha_result <- kripp.alpha(rater_matrix, method = "ordinal")

cat("=== Krippendorff's Alpha (ordinal) ===\n")
print(alpha_result)
cat("\n")

cat(sprintf("Alpha = %.4f\n", alpha_result$value))
cat("Interpretation:\n")
cat("  < 0.667  : insufficient agreement (Krippendorff 2004 threshold)\n")
cat("  >= 0.667 : acceptable agreement\n")
cat("  >= 0.800 : good agreement\n")
cat(sprintf("  => This result indicates: %s\n",
            ifelse(alpha_result$value >= 0.800, "GOOD agreement",
                  ifelse(alpha_result$value >= 0.667, "ACCEPTABLE agreement",
                         "INSUFFICIENT agreement"))))

