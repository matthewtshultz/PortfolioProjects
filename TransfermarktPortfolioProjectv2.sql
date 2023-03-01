--Demonstration of a variety of SQL skills

--Creating table

DROP TABLE IF EXISTS EuroInflationMultiplier
CREATE TABLE EuroInflationMultiplier
(Year DATE,
Multiplier DECIMAL(3, 2))

--Inserting data into created table

INSERT INTO EuroInflationMultiplier VALUES
('2004', 1.48),
('2005', 1.45),
('2006', 1.41),
('2007', 1.38),
('2008', 1.36),
('2009', 1.31),
('2010', 1.31),
('2011', 1.29),
('2012', 1.25),
('2013', 1.22),
('2014', 1.21),
('2015', 1.20),
('2016', 1.20),
('2017', 1.20),
('2018', 1.18),
('2019', 1.15),
('2020', 1.14),
('2021', 1.13),
('2022', 1.10),
('2023', 1.00)

SELECT TOP(5) *
FROM EuroInflationMultiplier
ORDER BY Year

--Using TOP statement to return tallest players 
SELECT TOP(100) *
FROM players
ORDER BY height_in_cm DESC

--Using DISTINCT to return possible options for a player's position
SELECT DISTINCT(position)
FROM players

--Using COUNT to see numeric representation of players by country
SELECT country_of_citizenship, COUNT(country_of_citizenship) AS country_count
FROM players
GROUP BY country_of_citizenship
ORDER BY COUNT(country_of_citizenship) DESC

--Using MIN, MAX, and AVG effectively to identify interesting data points and qualities
SELECT MIN(height_in_cm) AS ShortestPlayerHeight, 
	MAX(market_value_in_eur) AS HighestMarketValue, 
	AVG(market_value_in_eur) AS AverageMarketValue
FROM players
WHERE height_in_cm > 100

--Using multiple conditions in a where statement to see if any players meet conditions
SELECT *
FROM players
WHERE name LIKE '%Messi%' AND foot = 'Left' AND height_in_cm < 174 OR 
	country_of_citizenship = 'Portugal' AND current_club_name LIKE '%juve%'

--Returning market value data for two popular players
SELECT *
FROM player_valuations
WHERE player_id = 8198 OR player_id = 28003
ORDER BY datecleaned

--Using GROUP BY and ORDER BY to return what teams in the Premier League (GB1) are most represented in this dataset
SELECT current_club_name, COUNT(current_club_name) roster_count, current_club_domestic_competition_id
FROM players
WHERE current_club_domestic_competition_id = 'GB1'
GROUP BY current_club_name, current_club_domestic_competition_id
ORDER BY roster_count DESC, current_club_name 

SELECT *
FROM clubs
ORDER BY stadium_seats

--Using a join to see by name which clubs in the Premier League (GB1) have had the highest valued players
SELECT players.name, current_club_name, players.current_club_domestic_competition_id, highest_market_value_in_eur
FROM players
LEFT OUTER JOIN clubs
	ON players.current_club_id = clubs.club_id
WHERE current_club_domestic_competition_id = 'GB1' AND highest_market_value_in_eur > 50000000
ORDER BY highest_market_value_in_eur DESC

--Using multiple CASE statements to characterize Premier League (GB1) teams based on seating capacity, player age,
--and foreign player percentages.
SELECT name, average_age, stadium_seats, foreigners_percentage, average_age,
CASE
	WHEN stadium_seats > 50000 THEN 'Large Venue'
	WHEN stadium_seats BETWEEN 30000 AND 50000 THEN 'Medium Venue'
	ELSE 'Small Venue'
END AS venue_sizes,
CASE
	WHEN average_age > 27 THEN 'Aging'
	WHEN average_age BETWEEN 25.5 AND 27 THEN 'Prime'
	ELSE 'Young'
END AS team_youthfulness,
CASE
	WHEN foreigners_percentage < 50 THEN 'Majority English'
	WHEN foreigners_percentage BETWEEN 50 AND 66.7 THEN 'Mid Amount English'
	ELSE 'Less than 1/3 English'
END AS 'domestic_players_per_club'
	FROM clubs
WHERE domestic_competition_id = 'GB1'
ORDER BY stadium_seats

--Using HAVING to filter the aggregate function and demonstrate which large leagues have most of their players from
--the country in which the league games are played
SELECT domestic_competition_id, COUNT(domestic_competition_id) teams_in_league, AVG(squad_size) avg_squad_size,
AVG(foreigners_percentage) avg_foreigners_percentage
FROM clubs
GROUP BY domestic_competition_id
HAVING COUNT(domestic_competition_id) > 31
ORDER BY AVG(foreigners_percentage)

--Using PARTITION BY to identify number of players from both Manchester Premier League teams that are from each respective country,
--and the number of players in each position on those two teams (Attack, Midfield, Defender, Goalkeeper)
SELECT name, current_club_name, country_of_citizenship, COUNT(country_of_citizenship) OVER (PARTITION BY country_of_citizenship) numplayers_per_country,
	position, COUNT(position) OVER (PARTITION BY position) numplayers_by_position
FROM players
WHERE current_club_name LIKE '%manchester%'
ORDER BY country_of_citizenship

--Uses a CTE to explore the value of footedness (Right, Left, or Both) in the Spanish League of players valued over 50 million
WITH CTE_FootValue AS
(SELECT players.name, domestic_competition_id, foot, COUNT(foot) OVER (PARTITION BY foot) number_footedness,
AVG(highest_market_value_in_eur) OVER (PARTITION BY foot) value_foot
FROM players
JOIN clubs
	ON players.current_club_id = clubs.club_id
WHERE highest_market_value_in_eur > 50000000 AND domestic_competition_id = 'ES1')
SELECT name, foot, number_footedness, value_foot
FROM CTE_FootValue

--Exploring, in general, which positions have the tallest players (Goalkeepers, Center-Backs, Center-Forwards),
--the shortest players (Attacking Midfield, Right and Left Wingers) and the respective average value by position
--of players valued in 2022
SELECT sub_position, COUNT(sub_position) count_position, AVG(height_in_cm) avgheight_by_position,
AVG(highest_market_value_in_eur) avgvalue_by_position
FROM players
WHERE last_season = 2022 AND sub_position is NOT NULL 
GROUP BY sub_position
HAVING COUNT(sub_position) > 100
ORDER BY AVG(highest_market_value_in_eur) DESC

--Populating the sub_position column for Goalkeepers, whose sub_position was previously NULL
SELECT sub_position,
	CASE
		WHEN position = 'Goalkeeper' THEN 'Goalkeeper'
		ELSE sub_position
	END updated_sub_position
FROM players

UPDATE players
SET sub_position = 
	CASE
		WHEN position = 'Goalkeeper' THEN 'Goalkeeper'
		ELSE sub_position
	END

--Creating a temp table using previous query to compare players to average values for their position

CREATE TABLE #temp_players (
sub_position nvarchar(255),
count_position int,
avgheight_by_position float,
avgvalue_by_position float)

INSERT INTO #temp_players
SELECT sub_position, COUNT(sub_position) count_position, AVG(height_in_cm) avgheight_by_position,
AVG(highest_market_value_in_eur) avgvalue_by_position
FROM players
WHERE last_season = 2022 AND sub_position is NOT NULL 
GROUP BY sub_position
HAVING COUNT(sub_position) > 100
ORDER BY AVG(highest_market_value_in_eur) DESC

SELECT *
FROM #temp_players
ORDER BY avgvalue_by_position DESC

--Created a stored procedure that could return the previously built temp table based on a specified grouped row, which in this case
--was the sub position of the player.
CREATE PROCEDURE temp_players
AS
CREATE TABLE #temp_players (
sub_position nvarchar(255),
count_position int,
avgheight_by_position float,
avgvalue_by_position float)

INSERT INTO #temp_players
SELECT sub_position, COUNT(sub_position) count_position, AVG(height_in_cm) avgheight_by_position,
AVG(highest_market_value_in_eur) avgvalue_by_position
FROM players
WHERE last_season = 2022 AND sub_position is NOT NULL 
GROUP BY sub_position
HAVING COUNT(sub_position) > 100
ORDER BY AVG(highest_market_value_in_eur) DESC

SELECT *
FROM #temp_players
ORDER BY avgvalue_by_position DESC

EXEC temp_players @sub_position = 'Left Winger'

--Here using a CTE to delete duplicate data from the temp table that INSERTed multiple times
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY sub_position,
				count_position,
				avgheight_by_position,
				avgvalue_by_position
				ORDER BY sub_position) row_num
FROM #temp_players
)
DELETE
FROM RowNumCTE
WHERE row_num > 1

--Query to see if there is a general correlation between height of players as they compare to the postional average
--and their appraised market value over a 10 million euro valuation range
SELECT name, players.sub_position, current_club_name, country_of_citizenship, (height_in_cm - avgheight_by_position) height_diff,
	(highest_market_value_in_eur - avgvalue_by_position) value_diff
FROM players
JOIN #temp_players
	ON players.sub_position = #temp_players.sub_position
WHERE last_season = 2022 AND highest_market_value_in_eur BETWEEN 4999999 AND 15000001 and players.sub_position = 'Centre-Back'
ORDER BY height_diff

SELECT *
FROM #temp_players

--Using a CTE to determine the STDEV of the market values of players and the average of the market value to determine
--a useful range of market values and then evaluate the corresponding players
WITH CTE_avgstdev AS (
SELECT sub_position, CAST(AVG(highest_market_value_in_eur) AS int) avg_per_pos, CAST(STDEV(highest_market_value_in_eur) AS int) stdev_per_pos,
	CAST(AVG(highest_market_value_in_eur) + STDEV(highest_market_value_in_eur) AS int) one_stdev_pos
FROM players
WHERE sub_position is NOT NULL
GROUP BY sub_position
)
SELECT AVG(one_stdev_pos)
FROM CTE_avgstdev

--Discovering the quartiles of market value as well as the maximum and minimum for each sub position for players 
--valued in 2022
SELECT DISTINCT(sub_position) as sub_position,
	MIN(highest_market_value_in_eur) OVER (PARTITION BY sub_position) as minvalue,
	PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY highest_market_value_in_eur)
	OVER (PARTITION BY sub_position) as q_one_disc,
	PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY highest_market_value_in_eur)
	OVER (PARTITION BY sub_position) as median_disc,
	PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY highest_market_value_in_eur)
	OVER (PARTITION BY sub_position) as q_three_disc,
	MAX(highest_market_value_in_eur) OVER (PARTITION BY sub_position) as maxvalue
FROM players
WHERE sub_position is NOT NULL and last_season = 2022
ORDER BY median_disc

--Cleaning some of the data containing odd characters in certain names
SELECT city_of_birth, REPLACE(city_of_birth, 'Â Â', '') as city_of_birth_fixed 
FROM players

UPDATE players
SET city_of_birth = REPLACE(city_of_birth, 'Â Â', '')

--Re-uploaded data for the players table and it effectively fixed issues I was having with accents, tildes and the like with
--players' names, city of birth, and country of birth
SELECT *
FROM players2

--A couple of subquery examples:

--Returns each player alongside their highest market value and the average of all highest market values
SELECT player_id, highest_market_value_in_eur, (SELECT AVG(highest_market_value_in_eur) FROM players2) avg_highest_val
FROM players2

--Returns players who have at some point had their market value equal or surpass 100 million after adjusting their
--respective values for inflation
SELECT player_id, name, country_of_citizenship, current_club_name, current_club_domestic_competition_id, last_season
FROM players2
WHERE player_id IN (
	SELECT player_id
	FROM player_valuations
	WHERE val_inf_adj >= 100000000)
ORDER BY last_season DESC