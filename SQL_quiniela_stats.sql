#---------------------------------------------------1----------------------------------------------------------------------------

-- Create new Database
CREATE DATABASE IF NOT EXISTS  quiniela;
USE quiniela;

#---------------------------------------------------2----------------------------------------------------------------------------

-- Function to create the UNION ALL code needed to unify all available tables within the specified quiniela (i.e., 'nacional', 'buenos_aires', etc)
DROP FUNCTION IF EXISTS check_tables;
DELIMITER $$
CREATE FUNCTION check_tables(quiniela_region_name VARCHAR(255)) RETURNS VARCHAR(2000)
DETERMINISTIC
NO SQL
READS SQL DATA
	BEGIN
		DECLARE iterator INT DEFAULT 0; -- Iterator to keep count of loops (periods)
        SET @quiniela_union_statement = ''; -- Variable to hold full UNION ALL code to be returned from the Function
        
        -- Loop through the 4 available periods
		while_label: WHILE iterator <= 3 DO
			SET @quiniela_table_name = 
				CASE iterator
					WHEN 0 THEN CONCAT(quiniela_region_name, '_primera')
					WHEN 1 THEN CONCAT(quiniela_region_name, '_matutina')
					WHEN 2 THEN CONCAT(quiniela_region_name, '_vespertina')
					ELSE CONCAT(quiniela_region_name, '_nocturna')
			END;
            
            -- If a table with the specified quiniela and current period exists, adds code selecting the table to be unified with the rest along with the UNION ALL statement
			IF (
				SELECT EXISTS(
					SELECT * FROM information_schema.tables 
					WHERE table_schema = 'quiniela' 
					AND table_name = @quiniela_table_name)
				)
			THEN
                SET @quiniela_union_statement = CONCAT(@quiniela_union_statement, 'SELECT * FROM quiniela.', @quiniela_table_name, ' UNION ALL ');
			END IF;
            
			SET iterator = iterator + 1; -- Add 1 to loop into the following period
            
		END WHILE while_label;
        
        -- Clean the variable's code by deleting the 'UNION ALL' statement at the end of the full code
        SET @quiniela_union_statement = LEFT(@quiniela_union_statement, (LENGTH(@quiniela_union_statement) - 11));
        
        RETURN @quiniela_union_statement;
        
	END$$
DELIMITER ;

#---------------------------------------------------3----------------------------------------------------------------------------

/*
The following code if focused on analyzing and cleaning data for a specific table ('nacional'), to understand what are the main steps required for a stored procedure to automate the cleaning of additional tables -as needed-
*/

-- Visually check the data
SELECT * FROM quiniela.nacional
LIMIT 21;

-- Rename 'date' to 'lottery_date', to avoid using reserved words as column names
ALTER TABLE quiniela.nacional
RENAME COLUMN `date` TO lottery_date;

-- Check the total number of occurrences (201.223)
SELECT COUNT(*)
FROM quiniela.nacional;

-- Separate position 'Letras' from number positions, into a new table
CREATE TABLE nacional_letras
SELECT * 
FROM quiniela.nacional
WHERE position = 'Letras';

	-- Visually check new table
    SELECT *
    FROM quiniela.nacional_letras
    LIMIT 50;

	-- Check total number of occurrences (9.563)
    SELECT COUNT(*)
    FROM quiniela.nacional_letras;

-- Remove all occurrences with position 'Letras' from original table. Check that rows affected match the total number of occurrences in the newly created table above
DELETE FROM quiniela.nacional
WHERE position = 'Letras';

	-- Check total number of occurrences (191.660)
    SELECT COUNT(*)
    FROM quiniela.nacional;

/*
The rest of the code will be only directed to analyze and clean data with a number position, discarding the 'letras' results from the analysis
*/

-- Check data types of each column
SHOW FIELDS
FROM quiniela.nacional;

-- Check for results that do not contain a number
SELECT DISTINCT(result)
FROM quiniela.nacional
ORDER BY result ASC;

-- Remove occurrences where results are not a number (339 rows removed)
DELETE FROM quiniela.nacional
WHERE result = '----' OR result = '';

-- Correct format for each of the columns
ALTER TABLE quiniela.nacional
MODIFY lottery_date DATE,
MODIFY quiniela VARCHAR(100),
MODIFY period VARCHAR(100),
MODIFY position SMALLINT(2),
MODIFY result SMALLINT(4) ZEROFILL;
    
-- Visually check data
SELECT *
FROM quiniela.nacional
LIMIT 40;

-- Check if the date field has NULL values
SELECT *
FROM quiniela.nacional
WHERE lottery_date IS NULL;

-- If any, delete lottery dates with NULL values
DELETE FROM quiniela.nacional
WHERE lottery_date IS NULL;

-- Check for columns' values
SELECT DISTINCT(period)
FROM quiniela.nacional;

SELECT DISTINCT(position)
FROM quiniela.nacional;

-- Look at occurrences by period of the day
SELECT period, COUNT(*) AS number_of_occurrences
FROM quiniela.nacional
GROUP BY period
ORDER BY COUNT(*) DESC;

-- Count the number of days and approximate number of years for which there is lottery data, by period
SELECT period, COUNT(DISTINCT(lottery_date)) AS number_of_days, (COUNT(DISTINCT(lottery_date)) / 6 / 52) AS number_of_years -- years = total days / 6 (days a week of lotteries) / 52 (weeks in a year)
FROM quiniela.nacional
GROUP BY period
ORDER BY COUNT(DISTINCT(lottery_date)) DESC;

-- Check non-matching dates in all periods (88 results - 0.04% approximately)

/*
Most of exceptions occur in a holiday -where the number of periods may vary- or Saturday -where there are only 3 periods-
*/

SELECT lottery_date, COUNT(DISTINCT(period)) AS number_of_periods, DAYOFWEEK(lottery_date) AS day_of_week
FROM quiniela.nacional
GROUP BY lottery_date
HAVING COUNT(DISTINCT(period)) != 4
ORDER BY COUNT(DISTINCT(period)) ASC, lottery_date ASC;

-- Check that all dates, for each period, have the same number of positions (numbers drawn), by retrieving those whose count is different than 20 (28 results, representing 221 rows, mostly 'nocturna' - 0.45%)
SELECT lottery_date, period, COUNT(*) AS number_of_positions
FROM quiniela.nacional
GROUP BY lottery_date, period
HAVING COUNT(position) != 20;

	-- Check number of total rows representing dates and periods with less than 20 positions
	SELECT qn.lottery_date, qn.period, qn.position
	FROM quiniela.nacional qn
	INNER JOIN
		(SELECT lottery_date, period, COUNT(*) AS number_of_positions
		FROM quiniela.nacional
		GROUP BY lottery_date, period
		HAVING COUNT(position) != 20) ft -- filtered table
	WHERE qn.lottery_date = ft.lottery_date 
		AND qn.period = ft.period
	ORDER BY qn.lottery_date ASC, qn.period, qn.position ASC;

-- Delete full records of "Quinielas" with incomplete position information
DELETE oqn
FROM quiniela.nacional oqn -- original quiniela nacional
JOIN 
(SELECT lottery_date, period, COUNT(*) AS number_of_positions
	FROM quiniela.nacional
	GROUP BY lottery_date, period
	HAVING COUNT(position) != 20) ft -- filtered table
WHERE oqn.lottery_date = ft.lottery_date
AND oqn.period = ft.period;

-- Check there are no lotteries on a Sunday
SELECT *, DAYOFWEEK(lottery_date) as day_of_week
FROM quiniela.nacional
WHERE DAYOFWEEK(lottery_date) = 1
ORDER BY lottery_date ASC;

	-- Remove records dated as Sundays (40 records)
    DELETE FROM quiniela.nacional
    WHERE DAYOFWEEK(lottery_date) = 1;

#---------------------------------------------------4----------------------------------------------------------------------------

-- Procedure to create 1 unified table with all the period for a specific 'quiniela' (i.e., 'nacional', 'buenos_aires', etc) and clean the created table
DROP PROCEDURE IF EXISTS process_quiniela;
DELIMITER $$
CREATE PROCEDURE process_quiniela(IN quiniela_name VARCHAR(255))
	BEGIN
		-- Create and run statement to unite all tables into a single table
        SET @quiniela_union_all = CONCAT(
			'CREATE TABLE IF NOT EXISTS ', quiniela_name, ' ', 
            check_tables(quiniela_name));
		PREPARE run_union_statement FROM @quiniela_union_all;
        EXECUTE run_union_statement;
        
        -- Rename 'date' to 'lottery_date', to avoid using reserved words as column names
		SET @change_column_name = CONCAT(
			'ALTER TABLE quiniela.', quiniela_name,
			' RENAME COLUMN `date` TO lottery_date');
		PREPARE change_name FROM @change_column_name;
        EXECUTE change_name;

		-- Display the total number of records
		SET @display_count = CONCAT(
			'SELECT COUNT(*) AS total_number_of_records
			FROM quiniela.', quiniela_name);
        PREPARE count_records FROM @display_count;
        EXECUTE count_records;

		-- Separate position 'Letras' from number positions, into a new table
		SET @split_tables = CONCAT(
			'CREATE TABLE ', quiniela_name, '_letras ',
			'SELECT * 
			FROM quiniela.', quiniela_name,
			' WHERE position = "Letras"');
		PREPARE create_table_letras FROM @split_tables;
        EXECUTE create_table_letras;

		-- Remove all occurrences with position 'Letras' from original table. Check that rows affected match the total number of occurrences in the newly created table above
		SET @remove_letras = CONCAT(
			'DELETE FROM quiniela.', quiniela_name,
			' WHERE position = "Letras"');		
        PREPARE delete_letras FROM @remove_letras;
        EXECUTE delete_letras;

		-- Remove occurrences where results are not a number (339 rows removed)
		SET @clean_result = CONCAT(
			'DELETE FROM quiniela.', quiniela_name,
			' WHERE result = "----" OR result = ""');
		PREPARE clean_invalid_results FROM @clean_result;
        EXECUTE clean_invalid_results;

		-- Correct format for each of the columns
		SET @correct_format = CONCAT(
			'ALTER TABLE quiniela.', quiniela_name,
			' MODIFY lottery_date DATE,
			MODIFY quiniela VARCHAR(100),
			MODIFY period VARCHAR(100),
			MODIFY position SMALLINT(2),
			MODIFY result SMALLINT(4) ZEROFILL');
		PREPARE reformat_table FROM @correct_format;
        EXECUTE reformat_table;
        
        -- If any, delete lottery dates with NULL values
		SET @delete_null_dates = CONCAT(
			'DELETE FROM quiniela.', quiniela_name,
			' WHERE lottery_date IS NULL');
		PREPARE delete_null_lottery_dates FROM @delete_null_dates;
        EXECUTE delete_null_lottery_dates;

		-- Check for columns' values
		SET @check_period_values = CONCAT(
            'SELECT DISTINCT(period)
			FROM quiniela.', quiniela_name);
		PREPARE check_periods FROM @check_period_values;

		SET @check_position_values = CONCAT(
			'SELECT DISTINCT(position)
			FROM quiniela.', quiniela_name);
		PREPARE check_positions FROM @check_position_values;
        EXECUTE check_periods;
        EXECUTE check_positions;
        
        -- Delete full records of "Quinielas" with incomplete position information
		SET @delete_incomplete = CONCAT(
			'DELETE oqn
			FROM quiniela.', quiniela_name, ' oqn
			JOIN 
			(SELECT lottery_date, period, COUNT(*) AS number_of_positions
				FROM quiniela.', quiniela_name,
				' GROUP BY lottery_date, period
				HAVING COUNT(position) != 20) ft
			WHERE oqn.lottery_date = ft.lottery_date
			AND oqn.period = ft.period');
        PREPARE delete_incomplete_quinielas FROM @delete_incomplete;
        EXECUTE delete_incomplete_quinielas;
        
        -- Remove records dated as Sundays (40 records)
		SET @check_weekday = CONCAT(
			'DELETE FROM quiniela.', quiniela_name,
			' WHERE DAYOFWEEK(lottery_date) = 1');
		PREPARE remove_sundays FROM @check_weekday;
        EXECUTE remove_sundays;
        
	END$$
DELIMITER ;

#---------------------------------------------------5----------------------------------------------------------------------------

-- Execute stored procedure for 'Quiniela nacional'
CALL process_quiniela('nacional');