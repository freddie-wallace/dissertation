# UK Bank Closure Modelling

## Overview

This repository contains code, data and maps for modelling bank closures in the UK. The research focuses on exploring various factors influencing bank closures, including urbanity/rurality, socioeconomic status, network size, and the role of the Internet in a multichannel banking era.

The PDF document will be added to this repository once it has been officially released.

## Contents

- **Data:** The processed banks dataset in csv format used for the analysis.
- **Code:** The SQL script used to create the banks csv and an R Script for data preprocessing, exploratory data analysis, modelling, and evaluation.
- **Maps:** High resolution SVGs of Maps used in the document.

## Data

The analysis utilizes banking data from [https://geolytix.com/blog/bank-branch-data-open-and-free-from-geolytix/] and census data from [https://drive.google.com/file/d/162Pk2eao9wWtExjOqLUtxZxpiiE-_gj8/view]. The datasets include information on bank locations, socioeconomic indicators, Internet usage, and other relevant variables.

## Code

The code is organized into the following sections:
- `banks.sql`: The creation of the banks csv - data preprocessing and spatial joins.
- `analysis.r`: Data preprocessing, exploratory data analysis, modeling, and evaluation.

## Results

### Key Findings

- Urbanity/rurality: Contrary to earlier studies, rural areas were found to be more heavily impacted by bank closures.
- Socioeconomic status: Areas with lower socioeconomic status were less likely to experience bank closures.
- Network size: The number of bank branches within a network significantly influenced closure rates, highlighting the importance of brand presence.
- Internet usage: Individuals less comfortable with using the Internet were more likely to experience bank closures, posing challenges for financial inclusion.

## Conclusion

The analysis provides valuable insights into the factors driving bank closures in the UK. While certain variables such as urbanity/rurality and socioeconomic status align with previous research, the role of network size and Internet usage sheds new light on the dynamics of bank closures in the digital age.

### Limitations

- The analysis is based on cross-sectional data and does not account for longitudinal changes in variables.
- Data for Scotland and Northern Ireland are not included.
- The Internet Usage Category (IUC) variable may become outdated over time, requiring periodic updates for accurate predictions.

## Future Work

Future research could focus on finding specific areas at risk of financial exclusion using the variables found in this study.
