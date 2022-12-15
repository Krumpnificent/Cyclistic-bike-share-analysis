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



-- MERGING ALL THE TABLES INTO ONE TABLE USING THE "UNION" OPERATOR

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
FROM merged;


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
ADD COLUMN day_of_week numeric,
ADD COLUMN ride_length numeric;

-- Update columns 

UPDATE merged
SET year_month_day = (SELECT CAST(started_at AS date));

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
SELECT DISTINCT member_casual
FROM merged;
-----------------------------------------------------------------------------------------



-- ANALYZING DATA

-- Groups Rides by date and rider-category
SELECT year_month_day, member_casual, COUNT(*)
FROM merged
GROUP BY year_month_day, member_casual



/*
I found outliers in the max ride lengths for member and casual rides respectively.
I will remove these outliers to have more accurate results
*/
SELECT member_casual, 
		AVG(ride_length) AS avg_ride_length,  
		MIN(ride_length) AS min_ride_length, 
		MAX(ride_length) AS max_ride_length, 
		PERCENTILE_CONT(.5) WITHIN GROUP (ORDER BY ride_length) AS med_ride_length
FROM merged 
GROUP BY member_casual;

/*
	             avg	     min	 max        med
----------+-----------------------+--------+------------+---------
"casual"    2259.7121001688636024	0     14340041	    1259 
----------+-----------------------+--------+------------+---------
"member"    795.5894388260353929	0.    13561217	    588  
----------+-----------------------+--------+------------+---------

*/



-- provides sample standard deviation of the ride_lengths
SELECT member_casual, 
		STDDEV_SAMP(ride_length) 
FROM merged 
GROUP BY member_casual;

/*

----------+-------------------
"casual"    29056.98595453   
----------+-------------------
"member"    9468.974410373880
----------+-------------------

*/


/*
We will keep only the 95% data closest to the average with this formula: 
(Average - Standard Deviation * 2) < DATA WE KEEP < (Average + Standard Deviation * 2)
*/

SELECT (AVG(ride_length) - STDDEV_SAMP(ride_length)*2) AS lower_bound,
		(AVG(ride_length) + STDDEV_SAMP(ride_length*2)) AS upper_bound
FROM merged

--result
/*
       lower_bound      |     upper_bound
------------------------+-----------------------
-34730.4970357056059048   37227.7408573043940952
------------------------+-----------------------

This means that for our trimmed average, 
we would consider only the rides with lengths between -34730s & 37227s
This would give us a much more reasonable result than the 
*/

WITH bounds AS (
SELECT (AVG(ride_length) - STDDEV_SAMP(ride_length)*2) AS lower_bound,
		(AVG(ride_length) + STDDEV_SAMP(ride_length*2)) AS upper_bound
FROM merged
)

SELECT member_casual, 
		ROUND(AVG(ride_length), 2) AS avg_ride_length,  
		MIN(ride_length) AS min_ride_length, 
		MAX(ride_length) AS max_ride_length, 
		PERCENTILE_CONT(.5) WITHIN GROUP (ORDER BY ride_length) AS med_ride_length
FROM merged 
WHERE ride_length BETWEEN 
						(SELECT lower_bound FROM bounds) 
						AND 
						(SELECT upper_bound FROM bounds)
GROUP BY member_casual;


/*
--------------+-----------------------+----+---------+--------
"casual" 	 1796.3326091004387510 	0     37225	1254 |
--------------+-----------------------+----+---------+--------
"member" 	 748.1919291220953066  	0     37212  	588  |
--------------+-----------------------+----+---------+--------
*/


-- casual and member ride lengths by date		
		
WITH bounds AS (
SELECT (AVG(ride_length) - STDDEV_SAMP(ride_length)*2) AS lower_bound,
		(AVG(ride_length) + STDDEV_SAMP(ride_length*2)) AS upper_bound
FROM merged
)

SELECT year_month_day, member_casual,
 		ROUND(AVG(ride_length), 2) AS avg_ride_length
FROM merged
WHERE ride_length BETWEEN 
					(SELECT lower_bound FROM bounds) 
					AND 
					(SELECT upper_bound FROM bounds)
GROUP BY year_month_day, member_casual;


/*
TOP 20 stations by traffic
ranks stations by activity
*/ 
SELECT end_station_name station_name, COUNT(end_station_name) total_visits, 
		RANK() OVER(
		ORDER BY COUNT(end_station_name) DESC
		) activity_rank
FROM merged
WHERE end_station_name IS NOT NULL
GROUP BY end_station_name
LIMIT 20;

