# Purpose: Conducts data preprocessing, correlation testing, model building, and EDA on incorrect predictions for the banks dataset created in the SQL script.
# First the banks.sql script must be run to create the banks dataset.
# Next the order follows:
# 1. Load Packages
# 2. Load the data
# 3. Data Preprocessing
# 4. Correlation Testing
# 5. Model Building
# 6. EDA for incorrect predictions
# 7. Tests to support discussion

######### Load Packages ################
library(ggplot2) # For data visualisation
library(dplyr) # For data manipulation
library(MASS) # For logistic regression
library(caTools) # For splitting the data
########################################

############ Load the data #############
# Load the data from GitHub
df <- read.csv("https://raw.githubusercontent.com/freddie-wallace/dissertation/main/data/banks.csv")
########################################


######### Data Preprocessing ###########

# Convert "true" to 1 and "false" to 0
df$suburb_bank <- ifelse(df$suburb_bank == "true", 1, 0)
df$within_rp <- ifelse(df$within_rp == "true", 1, 0)
df$closed_q1_2024 <- ifelse(df$closed_q1_2024 == "true", 1, 0)


# check data types
str(df)

# Set workers_current, hhd_census, pop_census to numeric
df$workers_current <- as.numeric(df$workers_current)
df$hhd_census <- as.numeric(df$hhd_census)
df$pop_census <- as.numeric(df$pop_census)

# Create dummy variables for the region column
df <- df %>%
  mutate(
    east_midlands = as.numeric(region == "East Midlands"),
    north_east = as.numeric(region == "North East"),
    south_west = as.numeric(region == "South West"),
    south_east = as.numeric(region == "South East"),
    north_west = as.numeric(region == "North West"),
    west_midlands = as.numeric(region == "West Midlands"),
    wales = as.numeric(region == "Wales"),
    london = as.numeric(region == "London"),
    eastern = as.numeric(region == "Eastern"),
    yorkshire_and_the_humber = as.numeric(region == "Yorkshire and The Humber")
  )

# Same for brand
df <- df %>%
  mutate(
    allied_irish_bank = as.numeric(brand == "Allied Irish Bank"),
    bank_of_scotland = as.numeric(brand == "Bank of Scotland"),
    barclays = as.numeric(brand == "Barclays"),
    clydesdale_bank = as.numeric(brand == "Clydesdale Bank"),
    coutts = as.numeric(brand == "Coutts"),
    coventry_building_society = as.numeric(brand == "Coventry Building Society"),
    halifax = as.numeric(brand == "Halifax"),
    handelsbanken = as.numeric(brand == "Handelsbanken"),
    hsbc = as.numeric(brand == "HSBC"),
    leeds_building_society = as.numeric(brand == "Leeds Building Society"),
    lloyds = as.numeric(brand == "Lloyds"),
    m_s_bank = as.numeric(brand == "M&S Bank"),
    metro_bank = as.numeric(brand == "Metro Bank"),
    nationwide = as.numeric(brand == "Nationwide"),
    natwest = as.numeric(brand == "NatWest"),
    royal_bank_of_scotland = as.numeric(brand == "Royal Bank of Scotland"),
    santander = as.numeric(brand == "Santander"),
    skipton_building_society = as.numeric(brand == "Skipton Building Society"),
    the_co_operative_bank = as.numeric(brand == "The Co-operative Bank"),
    tsb = as.numeric(brand == "TSB"),
    virgin_money = as.numeric(brand == "Virgin Money"),
    west_bromwich_building_society = as.numeric(brand == "West Bromwich Building Society"),
    yorkshire_bank = as.numeric(brand == "Yorkshire Bank"),
    yorkshire_building_society = as.numeric(brand == "Yorkshire Building Society")
  )

########################################


######### Correlation Testing ###########
## Test correlations between variables
cor_matrix <- cor(df[c
("avg_distance_to_comp", "distance_to_nearest_home_bank",
 "distance_to_postoffice", "avg_urbanity", "pop_census",
  "hhd_census", "workers_current", "ab_perc", "c1_perc",
  "c2_perc", "de_perc", "age0to17_perc", "age18to24_perc",
  "age25to44_perc", "age45to59_perc", "age60to74_perc",
  "age75plus_perc", "students_perc", "white_perc", "sme_lending", "estimated_value", "avg_iuc")
])

# Print correlation matrix
print(cor_matrix)

# Export the correlation matrix to a csv file
write.csv(cor_matrix, "correlation_matrix.csv")
########################################


######### Model Building ################

### Model 1: Spatial Variables Only ###

# Build logistic regression model
model_1 <- glm(closed_q1_2024 ~ 
              east_midlands
            + north_east
            + south_west
            + north_west
            + west_midlands
            + wales
            + london
            + eastern
            + yorkshire_and_the_humber
            + within_rp
            + avg_distance_to_comp
            + distance_to_nearest_home_bank
            + distance_to_postoffice,
            family = binomial, data = df)

# Summary of the model
summary(model_1)

# print the summary coefficients to csv
write.csv(summary(model_1)$coefficients, "model_1_summary.csv")

# Nobs
nobs(model_1)

# create a test set using caTools
set.seed(123)
split <- sample.split(df$closed_q1_2024, SplitRatio = 0.75)
train <- subset(df, split == TRUE)
test <- subset(df, split == FALSE)

# predict the test set
model_1_predictions <- predict(model_1, test, type = "response")

# create a confusion matrix
model_1_confusion_matrix <- table(test$closed_q1_2024, model_1_predictions > 0.5)
print(model_1_confusion_matrix)

# print the confusion matrix to csv
write.csv(model_1_confusion_matrix, "model_1_confusion_matrix.csv")

# calculate the accuracy
model_1_accuracy <- sum(diag(model_1_confusion_matrix)) / sum(model_1_confusion_matrix)
print(model_1_accuracy)

### Model 2 ###

# Build logistic regression model
model_2 <- glm(closed_q1_2024 ~ 
              east_midlands
            + north_east
            + south_west
            + north_west
            + west_midlands
            + wales
            + london
            + eastern
            + yorkshire_and_the_humber
            + within_rp
            + avg_distance_to_comp
            + distance_to_nearest_home_bank
            + distance_to_postoffice
            + avg_urbanity
            + workers_current
            + c1_perc
            + de_perc
            + age0to17_perc
            + age18to24_perc,
            family = binomial, data = df)

# Summary of the model
summary(model_2)

# print the summary coefficients to csv
write.csv(summary(model_2)$coefficients, "model_2_summary.csv")

# Nobs
nobs(model_2)

# predict the test set
model_2_predictions <- predict(model_2, test, type = "response")

# create a confusion matrix
model_2_confusion_matrix <- table(test$closed_q1_2024, model_2_predictions > 0.5)

# print the confusion matrix to csv
write.csv(model_2_confusion_matrix, "model_2_confusion_matrix.csv")

# calculate the accuracy
model_2_accuracy <- sum(diag(model_2_confusion_matrix)) / sum(model_2_confusion_matrix)
print(model_2_accuracy)

### Model 3 ###

# Build logistic regression model
model_3 <- glm(closed_q1_2024 ~ 
              east_midlands
            + north_east
            + south_west
            + north_west
            + west_midlands
            + wales
            + london
            + eastern
            + yorkshire_and_the_humber
            + within_rp
            + avg_distance_to_comp
            + distance_to_nearest_home_bank
            + distance_to_postoffice
            + avg_urbanity
            + workers_current
            + c1_perc
            + de_perc
            + age0to17_perc
            + age18to24_perc
            + allied_irish_bank
            + bank_of_scotland
            + clydesdale_bank
            + coutts
            + coventry_building_society
            + halifax
            + handelsbanken
            + hsbc
            + leeds_building_society
            + lloyds
            + m_s_bank
            + metro_bank
            + nationwide
            + natwest
            + royal_bank_of_scotland
            + santander
            + skipton_building_society
            + the_co_operative_bank
            + tsb
            + virgin_money
            + west_bromwich_building_society
            + yorkshire_bank
            + yorkshire_building_society
            + suburb_bank,
            family = binomial, data = df)

# Summary of the model
summary(model_3)

# print the summary coefficients to csv
write.csv(summary(model_3)$coefficients, "model_3_summary.csv")

# Nobs
nobs(model_3)

# predict the test set
model_3_predictions <- predict(model_3, test, type = "response")

# create a confusion matrix
model_3_confusion_matrix <- table(test$closed_q1_2024, model_3_predictions > 0.5)

# print the confusion matrix to csv
write.csv(model_3_confusion_matrix, "model_3_confusion_matrix.csv")

# calculate the accuracy
model_3_accuracy <- sum(diag(model_3_confusion_matrix)) / sum(model_3_confusion_matrix)
print(model_3_accuracy)

################ Backward Elimination ################
model_no_iuc <- stepAIC(model_3, direction = "backward")
######################################################

# Summary of the model
summary(model_no_iuc)

# print the summary coefficients to csv
write.csv(summary(model_no_iuc)$coefficients, "model_no_iuc_summary.csv")

# Nobs
nobs(model_no_iuc)

# predict the test set
model_no_iuc_predictions <- predict(model_no_iuc, test, type = "response")

# create a confusion matrix
model_no_iuc_confusion_matrix <- table(test$closed_q1_2024, model_no_iuc_predictions > 0.5)

# print the confusion matrix to csv
write.csv(model_no_iuc_confusion_matrix, "model_no_iuc_confusion_matrix.csv")

# calculate the accuracy
model_no_iuc_accuracy <- sum(diag(model_no_iuc_confusion_matrix)) / sum(model_no_iuc_confusion_matrix)
print(model_no_iuc_accuracy)

############ Model with IUC #################

# Build logistic regression model using model_no_iuc + iuc
model_iuc <- glm(closed_q1_2024 ~ 
              east_midlands
            + south_west
            + north_west
            + london
            + yorkshire_and_the_humber
            + within_rp
            + avg_distance_to_comp
            + distance_to_nearest_home_bank
            + distance_to_postoffice
            + avg_urbanity
            + de_perc
            + allied_irish_bank
            + clydesdale_bank
            + coutts
            + coventry_building_society
            + halifax
            + handelsbanken
            + leeds_building_society
            + lloyds
            + m_s_bank
            + metro_bank
            + nationwide
            + natwest
            + royal_bank_of_scotland
            + santander
            + skipton_building_society
            + the_co_operative_bank
            + tsb
            + virgin_money
            + west_bromwich_building_society
            + yorkshire_bank
            + yorkshire_building_society
            + suburb_bank
            + avg_iuc,
            family = binomial, data = df)

# Summary of the model
summary(model_iuc)

# print the summary coefficients to csv
write.csv(summary(model_iuc)$coefficients, "model_iuc_summary.csv")

# Nobs
nobs(model_iuc)

# predict the test set
model_iuc_predictions <- predict(model_iuc, test, type = "response")

# create a confusion matrix
model_iuc_confusion_matrix <- table(test$closed_q1_2024, model_iuc_predictions > 0.5)

# print the confusion matrix to csv
write.csv(model_iuc_confusion_matrix, "model_iuc_confusion_matrix.csv")

# calculate the accuracy
model_iuc_accuracy <- sum(diag(model_iuc_confusion_matrix)) / sum(model_iuc_confusion_matrix)
print(model_iuc_accuracy)

######################################## ##########
########## EDA for incorrect predictions ##########

# create a dataframe of the test set with the predictions
test_with_predictions <- cbind(test, model_iuc_predictions)

# create a column for whether the prediction was correct
test_with_predictions$correct_prediction <- ifelse(test_with_predictions$closed_q1_2024 == (test_with_predictions$model_iuc_predictions > 0.5), 1, 0)

# add column 'predicted' either 'Open' or 'Closed'
test_with_predictions$predicted <- ifelse(test_with_predictions$model_iuc_predictions > 0.5, "Closed", "Open")

# add column 'actual' either 'Open' or 'Closed'
test_with_predictions$actual <- ifelse(test_with_predictions$closed_q1_2024 == 1, "Closed", "Open")

summary(test_with_predictions)

# export to csv
write.csv(test_with_predictions, "test_with_predictions.csv")

# create incorrect predictions dataframe
incorrect_predictions <- subset(test_with_predictions, correct_prediction == 0)

# Conduct EDA on incorrect predictions

# Plot incorrect prediction % by region
test_with_predictions %>%
  group_by(region) %>%
  summarise(incorrect_prediction_rate = sum(correct_prediction == 0) / n()) %>%
  ggplot(aes(x = reorder(region, -incorrect_prediction_rate), y = incorrect_prediction_rate, fill = region)) +
  geom_bar(stat = "identity") +
  labs(title = "Incorrect Prediction Rate by Region",
       x = "Region",
       y = "Incorrect Prediction Rate") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "none", theme_minimal())

# Export incorrect prediction rate and count by region to csv
test_with_predictions %>%
  group_by(region) %>%
  summarise(incorrect_prediction_rate = sum(correct_prediction == 0) / n(), count = n()) %>%
  write.csv("incorrect_prediction_rate_by_region.csv")

# Plot incorrect prediction % by brand
test_with_predictions %>%
  group_by(brand) %>%
  summarise(incorrect_prediction_rate = sum(correct_prediction == 0) / n()) %>%
  ggplot(aes(x = reorder(brand, -incorrect_prediction_rate), y = incorrect_prediction_rate, fill = brand)) +
  geom_bar(stat = "identity") +
  labs(title = "Incorrect Prediction Rate by Brand",
       x = "Brand",
       y = "Incorrect Prediction Rate") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "none")

# Export incorrect prediction rate and count by brand to csv
test_with_predictions %>%
  group_by(brand) %>%
  summarise(incorrect_prediction_rate = sum(correct_prediction == 0) / n(), count = n()) %>%
  write.csv("incorrect_prediction_rate_by_brand.csv")

# Plot suburb bank correct/incorrect predictions
test_with_predictions %>%
  group_by(suburb_bank) %>%
  summarise(incorrect_prediction_rate = sum(correct_prediction == 0) / n()) %>%
  ggplot(aes(x = reorder(suburb_bank, -incorrect_prediction_rate), y = incorrect_prediction_rate, fill = suburb_bank)) +
  geom_bar(stat = "identity") +
  labs(title = "Incorrect Prediction Rate by Suburb Bank",
       x = "Suburb Bank",
       y = "Incorrect Prediction Rate") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "none")

# Export incorrect prediction rate and count by suburb bank to csv
test_with_predictions %>%
  group_by(suburb_bank) %>%
  summarise(incorrect_prediction_rate = sum(correct_prediction == 0) / n(), count = n()) %>%
  write.csv("incorrect_prediction_rate_by_suburb_bank.csv")

# Boxplot of social grade DE percentage by correct/incorrect prediction
ggplot(test_with_predictions, aes(x = factor(correct_prediction), y = de_perc, fill = factor(correct_prediction))) +
  geom_boxplot(alpha = 0.7) +
  scale_fill_manual(values = c("blue", "red")) +
  labs(title = "Boxplot of Social Grade Percentage by Correct/Incorrect Prediction",
       x = "Prediction Correctness",
       y = "Social Grade Percentage") +
  theme_minimal()

# Boxplot of distance to nearest home bank by correct/incorrect prediction without outliers
ggplot(test_with_predictions, aes(x = factor(correct_prediction), y = distance_to_nearest_home_bank, fill = factor(correct_prediction))) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA) + # Exclude outliers using outlier.shape = NA
  scale_fill_manual(values = c("#e67171", "#abf17c"), guide = FALSE) + # Remove the legend
  labs(title = "Boxplot of Distance to Nearest Home Bank by Correct/Incorrect Prediction",
       x = "Prediction Correctness",
       y = "Distance to Nearest Home Bank") +
  ylim(0, quantile(test_with_predictions$distance_to_nearest_home_bank, 0.95)) + # Adjust ylim to exclude top 5% of data
  theme_minimal() +
  scale_x_discrete(labels = c("Incorrect", "Correct")) # Change x-axis labels

# Median, lower and upper quartiles of distance to nearest home bank by correct/incorrect prediction
test_with_predictions %>% 
  group_by(correct_prediction) %>% 
  summarise(m_nearest_home_bank = median(distance_to_nearest_home_bank),
            lq_nearest_home_bank = quantile(distance_to_nearest_home_bank, 0.25),
            uq_nearest_home_bank = quantile(distance_to_nearest_home_bank, 0.75))

# Boxplot of distance to post office by correct/incorrect prediction without outliers
ggplot(test_with_predictions, aes(x = factor(correct_prediction), y = distance_to_postoffice, fill = factor(correct_prediction))) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA) + # Exclude outliers using outlier.shape = NA
  scale_fill_manual(values = c("blue", "red")) +
  labs(title = "Boxplot of Distance to Post Office by Correct/Incorrect Prediction",
       x = "Prediction Correctness",
       y = "Distance to Post Office") +
  ylim(0, quantile(test_with_predictions$distance_to_postoffice, 0.95)) + # Adjust ylim to exclude top 5% of data
  theme_minimal()

# Boxplot of average distance to competitors by correct/incorrect prediction without outliers
ggplot(test_with_predictions, aes(x = factor(correct_prediction), y = avg_distance_to_comp, fill = factor(correct_prediction))) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA) + # Exclude outliers using outlier.shape = NA
  scale_fill_manual(values = c("blue", "red")) +
  labs(title = "Boxplot of Average Distance to Competitors by Correct/Incorrect Prediction",
       x = "Prediction Correctness",
       y = "Average Distance to Competitors") +
  ylim(0, quantile(test_with_predictions$avg_distance_to_comp, 0.8)) + # Adjust ylim to exclude top 5% of data
  theme_minimal()

# Boxplot of average iuc by correct/incorrect prediction
ggplot(test_with_predictions, aes(x = factor(correct_prediction), y = avg_iuc, fill = factor(correct_prediction))) +
  geom_boxplot(alpha = 0.7) +
  scale_fill_manual(values = c("#e67171", "#abf17c"), guide = FALSE) + # Remove the legend
  labs(title = "Boxplot of Average IUC by Correct/Incorrect Prediction",
       x = "Prediction Correctness",
       y = "Average IUC") +
  theme_minimal() +
  scale_x_discrete(labels = c("Incorrect", "Correct")) # Change x-axis labels

# Median, lower and upper quartiles of avg_iuc by correct/incorrect prediction
test_with_predictions %>%
  group_by(correct_prediction) %>%
  summarise(median_iuc = median(avg_iuc),
            lower_quartile_iuc = quantile(avg_iuc, 0.25),
            upper_quartile_iuc = quantile(avg_iuc, 0.75))


################ Tests to support discussion ################
# t-test between suburb bank and average urbanity
t.test(df$suburb_bank, df$avg_urbanity)

# correlation between iuc and de_perc
cor.test(df$avg_iuc, df$de_perc)

# count banks from df where london is true
sum(df$london == 1)