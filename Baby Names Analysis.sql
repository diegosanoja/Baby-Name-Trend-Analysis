USE baby_names_db;

-- Initial Exploratory Data Analysis

SELECT *                  -- This query shows the first 10 rows of the names table.
FROM names
LIMIT 10;

SELECT DISTINCT(Year)      -- This query shows the year range of the data.
FROM names;               

SELECT DISTINCT(Gender)
FROM names;

SELECT *                             -- This query checks if there are null / missing values in the columns.
FROM Names          
WHERE
    State IS NULL
    OR Gender IS NULL
    OR Year IS NULL
    OR Name IS NULL
    OR Births IS NULL;   -- there are no null values in any columns.           

SELECT                                             -- This query count the number of distinct names per gender and get the total names (without
    Gender,                                        -- looking at the gender).
    COUNT(DISTINCT(Name)) AS Total_Names
FROM names               
GROUP BY Gender                                                              
UNION
SELECT
    "Both Genders",
    COUNT(DISTINCT(Name)) AS Total_Names
FROM names;          --  Some names are given to both boys and girls.

SELECT * FROM regions;      -- The table has 50 rows (1 per state).

SELECT DISTINCT(State) FROM names;    -- The table has 51 rows (need to find out why there are not only 50 states).

WITH states_1 AS (SELECT DISTINCT(State) FROM names)                    -- This query finds the extra state inside the names table using a LEFT JOIN.
SELECT *
FROM states_1 s
LEFT JOIN regions r
ON s.State = r.State;   -- The state of MI is missing in the Midwest region.

-- Objective 1: Track changes in name popularity

-- 1. Find the overall most popular girl and boy names and show how they have changed in popularity rankings over the years

WITH births_per_gender_year AS                    -- This query first creates a CTE that groups the data by gender, name and year to them aggregate
(SELECT                                           -- the total births. Then, a column to show the popularity is added to the CTE using the ROW_NUMBER
    Gender,                                       -- window function to determine the popularity of the names per gender and year.
    Name,
    Year,
    SUM(Births) AS Total_babies
FROM names
GROUP BY
   Gender,
    Name,
    Year)
SELECT
	*,
	ROW_NUMBER() OVER (PARTITION BY Gender, Year ORDER BY Total_babies DESC) AS Popularity
FROM births_per_gender_year;       

SELECT                                               -- This query filters the data by male gender, then groups the observations by name to calculate
    Name, SUM(Births) AS Total_babies                -- the total number of births. Finally, the result is sorted in descending order by total babies
FROM names                                           -- born and only the first row is returned.
WHERE Gender = "M"
GROUP BY Name
LIMIT 1;                                               -- The most Popular name for boys is Michael 

SELECT                                                 -- Same logic as the previous query but the gender used to filter is Female in this one.
    Name,
    SUM(Births) AS Total_babies              
FROM names
WHERE Gender = "F"
GROUP BY Name
LIMIT 1;                                               -- The most Popular name for girls is Jessica

WITH female_year AS                                  -- This query first creates 2 CTEs, one that groups the data for females by name and year to them 
(SELECT                                              -- aggregate the total births. The second CTE, adds a column to the previous CTE to show the
    Name,                                            -- popularity using the ROW_NUMBER function. Finally, the rows whose first name is not Jessica
    Year,                                            -- are filtered out to show the popularity of that name per year.
    SUM(Births) AS Total_babies
FROM names
WHERE Gender = "F"
GROUP BY
    Name,
    Year),
popularity_per_year AS
(SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY Year ORDER BY Total_babies DESC) AS Popularity
FROM female_year)
SELECT *
FROM popularity_per_year
WHERE Name = "Jessica"; 

WITH male_year AS                            -- Same logic as the previous query but this one searches for the popularity of the most used male name
(SELECT                                      -- through the names table.
    Name,
    Year,
    SUM(Births) AS Total_babies
FROM names
WHERE Gender = "M"
GROUP BY
    Name,
    Year),
popularity_per_year AS
(SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY Year ORDER BY Total_babies DESC) AS Popularity
FROM male_year)
SELECT *
FROM popularity_per_year
WHERE Name = "Michael";       

-- 2. Find the names with the biggest jumps in popularity from the first year of the data set to the last year.

WITH all_births AS                          -- This query uses 3 CTES to find the popularity change of the names present in both 1980 and 2009. To do
(SELECT                                     -- this, first the CTE called all_births which calculates the total births per year and name is created.
    Year,                                   -- Then, it is used to create the other 2 CTEs (popularity_1980 and popularity_2009) which returns the
    Name,                                   -- number of births per name for the years 1980 and 2009 and their respective popularity for those years.
    SUM(Births) AS Total_babies             -- Finally, an INNER JOIN is used to return only the names that were present in both years and their
FROM names                                  -- popularities are substracted to measure their changes.
GROUP BY 
    Year,
    Name),
popularity_1980 AS
(SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY YEAR ORDER BY Total_babies DESC) AS Popularity_1980
FROM all_births
WHERE Year = 1980),
popularity_2009 AS
(SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY YEAR ORDER BY Total_babies DESC) AS Popularity_2009
FROM all_births
WHERE Year = 2009)
SELECT
    p1.Name,
    p1.Popularity_1980,
    p2.Popularity_2009,
    CAST(p2.Popularity_2009 AS SIGNED) - CAST(p1.Popularity_1980 AS SIGNED) AS Popularity_Change
FROM popularity_1980 p1
INNER JOIN popularity_2009 p2
ON p1.Name = p2.Name
ORDER BY Popularity_Change DESC;

-- Objective 2: Compare popularity across decades

-- 1. For each year, return the 3 most popular girl names and 3 most popular boy names

WITH births_per_year AS               -- This query uses the first CTE to first calculate the total births per year, gender and name and then another 
(SELECT                               -- adds the popularity to the previous results based on the births per year and gender. Finally, the names whose
    Year,                             -- popularity are 4 or higher are filtered out to keep the 3 most popular for each year and gender.
    Gender,
    Name,
    SUM(Births) AS Total_babies
FROM names
GROUP BY
    Year,
    Gender,
    Name),
popularity_per_year AS
(SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY Year, Gender ORDER BY Total_babies DESC) AS Popularity
FROM births_per_year)
SELECT *
FROM popularity_per_year
WHERE Popularity < 4
ORDER BY
    Gender,
    Year;

-- 2. For each decade, return the 3 most popular girl names and 3 most popular boy names

WITH decades AS                   -- This query follows the same logic as the previous one, except that an additional CTE is used at the beginning to
(SELECT                           -- add a column to determine the decade. Then, the process is repeated except that the decade is used to create the
    Year,                         -- groups to determine the total births and the popularity.
    Gender,
    Name,
    Births,
    CASE
        WHEN Year BETWEEN 1980 AND 1989 THEN "1980s"
        WHEN Year BETWEEN 1990 AND 1999 THEN "1990s"
	WHEN Year BETWEEN 2000 AND 2009 THEN "2000s"
	END AS Decade
FROM names),
births_per_decade AS
(SELECT
    Decade,
    Gender,
    Name,
    SUM(Births) AS Total_babies
FROM decades
GROUP BY
    Decade,
    Gender,
    Name),
popularity_per_decade AS
(SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY Decade, Gender ORDER BY Total_babies DESC) AS Popularity
FROM births_per_decade)
SELECT *
FROM popularity_per_decade
WHERE Popularity < 4
ORDER BY
    Gender,
    Decade;

-- Objective 3: Compare popularity across regions

-- 1. Return the number of babies born in each of the six regions (NOTE: The state of MI should be in the Midwest region)

SELECT                                   -- This query calculates the number of births per region by doing a LEFT JOIN between a modified version of
    Region,                              -- the regions table and the names table.
    SUM(Births) AS Total_babies
FROM
(SELECT
	CASE
            WHEN n.State = "MI" THEN "Midwest"
            WHEN r.Region = "New England" THEN "New_England"
            ELSE r.Region
	END AS Region, n.Births
FROM names n
LEFT JOIN regions r
ON n.State = r.State) regions_new
GROUP BY Region
ORDER BY Total_babies;                    -- New England is the region with least babies born and South had more babies from the 6 regions.

-- 2. Return the 3 most popular girl names and 3 most popular boy names within each region

WITH names_per_region AS                -- This query first uses a CTE that has uses the a modified version previous query to calculate the number of
(SELECT                                 -- babies per region, gender and name. Then, follows the logic used in previous queries to find the 3 most
	Region,                         -- popular names per region and year for males and females.
    Gender,
    Name, SUM(Births) AS Total_babies
FROM 
(SELECT
	CASE
		WHEN n.State = "MI" THEN "Midwest"
        WHEN r.Region = "New England" THEN "New_England"
        ELSE r.Region
	END AS Region,
    n.Gender,
    n.Name,
    n.Births
FROM names n
LEFT JOIN regions r
ON n.State = r.State) regions_new
GROUP BY
	Region,
    Gender,
    Name
ORDER BY Total_babies),
Popularity AS
(SELECT
	*,
    ROW_NUMBER() OVER (PARTITION BY Region, Gender ORDER BY Total_babies DESC) AS Popularity
FROM names_per_region)
SELECT *
FROM Popularity
WHERE Popularity < 4
ORDER BY Gender, Region;

-- Objective 4: Explore unique names in the dataset

-- 1. Find the 10 most popular androgynous names (names given to both females and males)

SELECT                                -- This query first calculates the total number of babies who received a specific name. Then, filters out those
    Name,                             -- that were only used for a single gender. Finally, only the rows with the 10 most used are returned.
    SUM(Births) AS Total_babies
FROM names
GROUP BY Name
HAVING COUNT(DISTINCT(Gender)) > 1
ORDER BY Total_babies DESC;

-- 2. Find the length of the shortest and longest names, and identify the most popular short names (those with the fewest characters) and long names
-- (those with the most characters)

WITH long_names AS                   -- This query starts by grouping the names to add the total babies who received a particular name and the length
(SELECT                              -- of that name. Then, keeps only the rows with the greatest amount of characters to find their popularity.
    Name,
    LENGTH(Name) AS Name_length,
    SUM(Births) AS Total_babies
FROM names
GROUP BY Name
ORDER BY Name_length DESC)
SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY Total_babies DESC) AS Popularity
FROM long_names
WHERE
    Name_length = (SELECT MAX(Name_length) FROM long_names); 

WITH short_names AS                      -- Same logic as the previous query but this one returns the popularity of the shortest names.      
(SELECT
    Name,
    LENGTH(Name) AS Name_length,
    SUM(Births) AS Total_babies
FROM names
GROUP BY Name
ORDER BY Name_length)
SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY Total_babies DESC) AS Popularity
FROM short_names
WHERE
    Name_length = (SELECT MIN(Name_length) FROM short_names); 

-- 3. The founder of Maven Analytics is named Chris. Find the state with the highest percent of babies named "Chris"

WITH babies_per_states AS           -- This query first creates 2 CTEs, one with the total babies per region and the other with the total babies that
(SELECT			            -- received the name Chris per region. Then, an INNER JOIN is used to calculate the percentage of babies called
    State,                          -- Chris per state.
    SUM(Births) AS Total_babies
FROM names
GROUP BY State),
chrises_per_states AS
(SELECT
    State,
    SUM(Births) AS Total_babies
FROM names
WHERE Name = "Chris"
GROUP BY State)
SELECT
    b.State,
    (c.Total_babies / b.Total_babies) * 100 AS Chris_percentage
FROM babies_per_states b
INNER JOIN chrises_per_states c
ON b.State = c.State
ORDER BY Chris_percentage;
