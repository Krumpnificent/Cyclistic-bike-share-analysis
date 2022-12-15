-- REARRANGING COLUMNS AND REDEFINING DATATYPES FOR SYMETRY

-- The CAST funtion converts values from one datatype to another
/* 
The INTO function creates a temporary table 
and stores the result of the query in the temporary table 
*/

DROP TABLE IF EXISTS rides_13_v1;
SELECT ride_id, started_at,
	ended_at, start_station_name, 
	CAST (start_station_id AS text), end_station_name, 
	CAST (end_station_id AS text), member_casual
INTO rides_13_v1
FROM rides_13;


DROP TABLE IF EXISTS rides_14_v1;
SELECT ride_id, started_at,
	ended_at, start_station_name, 
	CAST (start_station_id AS text), end_station_name, 
	CAST (end_station_id AS text), member_casual
INTO rides_14_v1
FROM rides_14;


DROP TABLE IF EXISTS rides_15_v1;
SELECT ride_id, started_at,
	ended_at, start_station_name, 
	CAST (start_station_id AS text), end_station_name, 
	CAST (end_station_id AS text), member_casual
INTO rides_15_v1
FROM rides_15;


DROP TABLE IF EXISTS rides_16_v1;
SELECT ride_id, started_at,
	ended_at, start_station_name, 
	CAST (start_station_id AS text), end_station_name, 
	CAST (end_station_id AS text), member_casual
INTO rides_16_v1
FROM rides_16;


DROP TABLE IF EXISTS rides_17_v1;
SELECT ride_id, started_at,
	ended_at, start_station_name, 
	CAST (start_station_id AS text), end_station_name, 
	CAST (end_station_id AS text), member_casual
INTO rides_17_v1
FROM rides_17;


DROP TABLE IF EXISTS rides_18_v1;
SELECT ride_id, started_at,
	ended_at, start_station_name, 
	CAST (start_station_id AS text), end_station_name, 
	CAST (end_station_id AS text), member_casual
INTO rides_18_v1
FROM rides_18;


DROP TABLE IF EXISTS rides_19_v1;
SELECT ride_id, started_at,
	ended_at, start_station_name, 
	CAST (start_station_id AS text), end_station_name, 
	CAST (end_station_id AS text), member_casual
INTO rides_19_v1
FROM rides_19;


DROP TABLE IF EXISTS rides_20_v1;
SELECT ride_id, started_at,
	ended_at, start_station_name, 
	start_station_id, end_station_name, 
	end_station_id, member_casual
INTO rides_20_v1
FROM rides_20;


DROP TABLE IF EXISTS rides_21_v1;
SELECT ride_id, started_at,
	ended_at, start_station_name, 
	CAST (start_station_id AS text), end_station_name, 
	CAST (end_station_id AS text), member_casual
INTO rides_21_v1
FROM rides_21;


DROP TABLE IF EXISTS rides_22_v1;
SELECT ride_id, started_at,
	ended_at, start_station_name, 
	CAST (start_station_id AS text), end_station_name, 
	CAST (end_station_id AS text), member_casual
INTO rides_22_v1
FROM rides_22;
----------------------------------------------------------------------------------



-- MERGING ALL THE TABLES INTO ONE TABLE USING THE "UNION" COMMAND

SELECT * 
INTO merged
FROM rides_13_v1

UNION

SELECT *
FROM rides_14_v1

UNION

SELECT *
FROM rides_15_v1

UNION

SELECT *
FROM rides_16_v1

UNION

SELECT *
FROM rides_17_v1

UNION

SELECT *
FROM rides_18_v1

UNION

SELECT *
FROM rides_19_v1

UNION

SELECT *
FROM rides_20_v1

UNION

SELECT *
FROM rides_21_v1

UNION

SELECT *
FROM rides_22_v1;
----------------------------------------------------------------------------------



-- INSPECTING THE NEW TABLE THAT HAS BEEN CREATED

-- provides the table name, column names and data types
-- replace column_name with '*' for a complete structural breakdwon
SELECT table_name, column_name, data_type 		
FROM information_schema.columns 		
WHERE table_name = 'merged';

-- provides the numbers of rows and columns of the new table
SELECT COUNT(*) AS number_of_rows, 
		(SELECT COUNT(*) FROM information_schema.columns
		WHERE table_name = 'merged') AS number_of_columns
FROM merged;

-- check for null values 
SELECT *
FROM merged
WHERE ride_id ISNULL
	OR started_at ISNULL
	OR ended_at ISNULL
	OR start_station_name ISNULL
	OR start_station_id ISNULL
	OR end_station_name ISNULL
	OR end_station_id ISNULL
	OR member_casual ISNULL;
----------------------------------------------------------------------------------	
	
	
	
-- DATA CLEANING

/* 
The member_casual column contains 5 categories:
MEMBER, SUBSCRIBER, CUSTOMER, DEPENDENT AND CASUAL.
We need to reduce these categories into MEMBER AND CASUAL.
To do this, we will replace all SUBSCRIBERS with MEMBERS
and all CUSTOMERS with CASUAL, and lastly, drop rows with
the DEPENDENT user types
*/

-- returns the categories present int the memeber_casual column
SELECT DISTINCT member_casual
from merged;


-- returns the number of observations that fall under each categgory
SELECT member_casual, COUNT(*) as total
FROM merged
GROUP BY member_casual;



-- Assign member_causal categories the appropriate names
UPDATE merged
SET member_casual = CASE
						WHEN member_casual = 'Subscriber' THEN 'member'
						WHEN member_casual = 'Customer' THEN 'casual'
						ELSE member_casual
						END
WHERE member_casual IN ('Subscriber', 'Customer');


-- Inspect changes for accuracy
SELECT member_casual, COUNT(*)
FROM merged
GROUP BY member_casual;


-- Adding more columns
ALTER TABLE merged
ADD COLUMN year_month_day date,
ADD COLUMN years numeric,
ADD COLUMN months numeric,
ADD COLUMN days numeric,
ADD COLUMN day_of_week numeric,
ADD COLUMN ride_length numeric;

-- fill columns 

UPDATE merged
SET year_month_day = (SELECT CAST(started_at AS date));

UPDATE merged
SET years = EXTRACT(year FROM year_month_day);

UPDATE merged
SET months = EXTRACT(month FROM year_month_day);

UPDATE merged
SET days = EXTRACT(day FROM year_month_day);

UPDATE merged
SET day_of_week = EXTRACT(dow FROM started_at);

-- difference of end and start times in seconds
UPDATE merged
SET ride_length = EXTRACT(EPOCH FROM (ended_at - started_at)); 

-- Removing bad data

/* 	
Our ride data has some unreleavant records which must be dropped
to further clean this data.
*/
	
DELETE FROM merged
where start_station_name = 'HQ QR' OR ride_length < 0 OR member_casual = 'Dependent';

-- check results (We have now completely cleaned our data)
select distinct member_casual
from merged;
-----------------------------------------------------------------------------------------



-- ANALYZING DATA


SELECT member_casual, AVG(ride_length) AS mean_time,  MIN(ride_length) AS min_time, MAX(ride_length) AS max_time, 
		PERCENTILE_CONT(.5) WITHIN GROUP (ORDER BY ride_length) AS med_time
FROM merged 
GROUP BY member_casual;


-- CTE
WITH ca AS
(SELECT day_of_week, COUNT(*) AS no_of_casual_rides,
		ROUND(AVG(ride_length), 2) AS avg_casual_ride_time
FROM merged 
WHERE member_casual = 'casual'
GROUP BY day_of_week),

me AS
(SELECT day_of_week, COUNT(*) AS no_of_member_rides,
 ROUND(AVG(ride_length), 2) AS avg_member_ride_time
FROM merged
WHERE member_casual = 'member'
GROUP BY day_of_week)

SELECT ca.day_of_week, 
		ca.no_of_casual_rides,
		me.no_of_member_rides,
		ca.avg_casual_ride_time, me.avg_member_ride_time
FROM ca
LEFT JOIN me
ON ca.day_of_week = me.day_of_week

ORDER BY CASE
			WHEN ca.day_of_week = 'Sunday' THEN 0
			WHEN ca.day_of_week = 'Monday' THEN 1
			WHEN ca.day_of_week = 'Tuesday' THEN 2
			WHEN ca.day_of_week = 'Wednesday' THEN 3
			WHEN ca.day_of_week = 'Thursday' THEN 4
			WHEN ca.day_of_week = 'Friday' THEN 5
			WHEN ca.day_of_week = 'Saturday' THEN 6
			END;

SELECT years, member_casual, COUNT(*) AS total_rides
FROM merged
GROUP BY years, member_casual
