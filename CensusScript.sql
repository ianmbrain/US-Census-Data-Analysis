-- Fetch the `Native Hawaiian/Other Pacific Islander` column with 0's rather than N/A
SELECT IF(`Native Hawaiian/Other Pacific Islander` = 'N/A',0, `Native Hawaiian/Other Pacific Islander`)
FROM censusdata.demographic2019

-- Rename `Native Hawaiian/Other Pacific Islander`, `American Indian/Alaska Native`, and `Multiple Races` columns
ALTER TABLE censusdata.demographic2019 RENAME COLUMN `Native Hawaiian/Other Pacific Islander` TO pacific_islander,
	RENAME COLUMN `American Indian/Alaska Native` TO american_indian,
	RENAME COLUMN `Multiple Races` TO multiple_races
	
-- Remove N/A values in asian column
UPDATE CensusData.Demographic2019 
SET asian = 0
WHERE asian = 'N/A';

-- Remove N/A values in american_indian column
UPDATE CensusData.Demographic2019 
SET american_indian = 0
WHERE american_indian = 'N/A';

-- Remove N/A values in paciic_islander column
UPDATE CensusData.Demographic2019 
SET pacific_islander = 0
WHERE pacific_islander = 'N/A';

-- Fetch each demographic as a percentage of each states total population
SELECT location, ROUND((white/total)*100,2) as white_per,
	ROUND((black/total)*100,2) as black_per,
	ROUND((hispanic/total)*100,2) as hispanic_per,
	ROUND((asian/total)*100,2) as asian_per,
	ROUND((american_indian/total)*100,2) as american_indian_per,
	ROUND((pacific_islander/total)*100,2) as pacific_islander_per,
	ROUND((multiple_races/total)*100,2) as multiple_races_per
FROM CensusData.Demographic2019
WHERE location <> 'United States' AND location <> 'Puerto Rico'

-- Create a table containing demographic percentages
CREATE TABLE censusdata.demographic_per
AS 
SELECT location, ROUND((white/total)*100,2) as white_per,
	ROUND((black/total)*100,2) as black_per,
	ROUND((hispanic/total)*100,2) as hispanic_per,
	ROUND((asian/total)*100,2) as asian_per,
	ROUND((american_indian/total)*100,2) as american_indian_per,
	ROUND((pacific_islander/total)*100,2) as pacific_islander_per,
	ROUND((multiple_races/total)*100,2) as multiple_races_per
FROM CensusData.Demographic2019

-- Fetch states with black percentage greater than 30%
SELECT location, black_per
FROM CensusData.demographic_per
WHERE black_per > 30

-- Fetch states with a "diversity score" < than 100
WITH dem_scores AS (
	SELECT location,
		CASE
			WHEN white_per >= 25 THEN white_per - 25
			ELSE 25 - white_per
		END AS white_score,
		CASE
			WHEN black_per >= 25 THEN black_per - 25
			ELSE 25 - black_per
		END AS black_score,
		CASE
			WHEN hispanic_per >= 25 THEN hispanic_per - 25
			ELSE 25 - hispanic_per
		END AS hispanic_score,
		CASE
			WHEN asian_per >= 25 THEN asian_per - 25
			ELSE 25 - asian_per
		END AS asian_score
	FROM CensusData.demographic_per
	WHERE location <> 'United States' AND location <> 'Puerto Rico')
SELECT *, (white_score + black_score + hispanic_score + asian_score) AS total_score
FROM dem_scores
WHERE (white_score + black_score + hispanic_score + asian_score) < 100
ORDER BY total_score

-- Estimate 2025 demographic percentages 
	-- I will use 2020-2021 US average growth for each race: white (-.03%), black (.7%), hispanic (1.2%), asian (1.2%)
WITH 2025_demographic AS (
SELECT *, (white_2025+black_2025+hispanic_2025+asian_2025+american_indian+pacific_islander+multiple_races) AS total
FROM (
	SELECT location, ROUND(white*POWER((1+(-.0003/1)),6),0) AS white_2025, 
		ROUND(black*POWER((1+(.007/1)),6),0) AS black_2025,
		ROUND(hispanic*POWER((1+(.012/1)),6),0) AS hispanic_2025,
		ROUND(asian*POWER((1+(.012/1)),6),0) AS asian_2025,
		american_indian, pacific_islander, multiple_races
	FROM censusData.demographic2019) x)
SELECT location, ROUND((white_2025/total)*100,2) as white_per,
	ROUND((black_2025/total)*100,2) as black_per,
	ROUND((hispanic_2025/total)*100,2) as hispanic_per,
	ROUND((asian_2025/total)*100,2) as asian_per
FROM 2025_demographic