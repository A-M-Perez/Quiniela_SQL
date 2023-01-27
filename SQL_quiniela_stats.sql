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


-- Procedure to create 1 unified table with all the period for a specific 'quiniela' (i.e., 'nacional', 'buenos_aires', etc)
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

	END$$
DELIMITER ;


CALL process_quiniela('nacional');


