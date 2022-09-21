CREATE DATABASE sgd;
USE sgd;

# 01. Table Design
CREATE TABLE addresses
(
	`id` 	INT PRIMARY KEY AUTO_INCREMENT,
    `name` 	VARCHAR(50) NOT NULL
);

CREATE TABLE categories
(
	`id` 	INT PRIMARY KEY AUTO_INCREMENT,
    `name` 	VARCHAR(10) NOT NULL
);

CREATE TABLE offices
(
	`id` 					INT PRIMARY KEY AUTO_INCREMENT,
    `workspace_capacity` 	INT NOT NULL,
    `website` 				VARCHAR(50),
    `address_id` 			INT NOT NULL,
    CONSTRAINT fk_offices_addresses
		FOREIGN KEY (address_id) REFERENCES addresses (id)
);

CREATE TABLE employees
(
	`id` 				INT PRIMARY KEY AUTO_INCREMENT,
    `first_name` 		VARCHAR(30) NOT NULL,
    `last_name` 		VARCHAR(30) NOT NULL,
    `age` 				INT NOT NULL,
    `salary` 			DECIMAL(10, 2) NOT NULL,
    `job_title` 		VARCHAR(20) NOT NULL,
    `happiness_level` 	CHAR(1) NOT NULL
);

CREATE TABLE teams
(
	 `id` 			INT PRIMARY KEY AUTO_INCREMENT,
     `name` 		VARCHAR(40) NOT NULL,
     `office_id`	INT NOT NULL,
     `leader_id` 	INT NOT NULL UNIQUE,
     CONSTRAINT fk_teams_offices
		FOREIGN KEY (office_id) REFERENCES offices (id),
	 CONSTRAINT fk_teams_employees
		FOREIGN KEY (leader_id) REFERENCES employees (id)
);

CREATE TABLE games
(
	`id` 			INT PRIMARY KEY AUTO_INCREMENT,
    `name` 			VARCHAR(50) NOT NULL UNIQUE,
    `description` 	TEXT,
    `rating` 		FLOAT NOT NULL DEFAULT 5.5,
    `budget` 		DECIMAL(10, 2) NOT NULL,
    `release_date`	DATE,
    `team_id` 		INT NOT NULL,
    CONSTRAINT fk_games_teams
		FOREIGN KEY (team_id) REFERENCES teams (id)
);

CREATE TABLE games_categories
(
	`game_id` 	  INT NOT NULL,
    `category_id` INT NOT NULL,
    CONSTRAINT pk_games_categories 
		PRIMARY KEY (game_id, category_id),
    CONSTRAINT fk_game_id_games
		FOREIGN KEY (game_id) REFERENCES games (id),
	CONSTRAINT fk_game_id_categories
		FOREIGN KEY (category_id) REFERENCES categories (id)
);

-- filling the database

# 02. Insert
INSERT INTO games (`name`, `rating`, `budget`, `team_id`)
SELECT (REVERSE(LOWER(SUBSTR((t.`name`), 2)))), t.id, t.leader_id * 1000, t.id
FROM teams AS t
WHERE t.id BETWEEN 1 AND 9;

# 03. Update
UPDATE employees AS e
	JOIN teams AS t ON e.id = t.leader_id
SET e.salary = e.salary + 1000
WHERE e.age <= 40 AND salary < 5000;

# 04. Delete
DELETE g
FROM games AS g
	LEFT JOIN games_categories as gc ON g.id = gc.game_id
WHERE g.release_date IS NULL
	AND gc.category_id IS NULL;
    
# 05. Employees
SELECT first_name, last_name, age, salary, happiness_level
FROM employees AS e
ORDER BY salary, id;

# 06. Addresses of the teams
SELECT 
	t.`name` AS team_name, 
    a.`name` AS address_name,
    LENGTH(a.`name`)
FROM teams AS t
	JOIN offices AS o ON t.office_id = o.id
    RIGHT JOIN addresses AS a on o.address_id = a.id
WHERE o.website IS NOT NULL
ORDER BY team_name, address_name;

# 07. Categories Info
-- SELECT *
SELECT c.name, COUNT(g.name) AS 'games_count', ROUND(AVG(g.budget), 2) AS avg_budget, MAX(g.rating) AS max_rating
FROM categories AS c
	JOIN games_categories AS gc ON c.id = gc.category_id
    JOIN games AS g ON gc.game_id = g.id
GROUP BY c.name
HAVING max_rating >= 9.5
ORDER BY games_count DESC, c.name;

# 08. Games of 2022
-- SELECT *
SELECT 
	g.name,
    g.release_date,
	CONCAT(SUBSTR(g.description,1 , 10), '...') AS summary,
		CASE
			WHEN MONTH(g.release_date) BETWEEN 1 AND 3 THEN 'Q1'
			WHEN MONTH(g.release_date) BETWEEN 4 AND 6 THEN 'Q2'
			WHEN MONTH(g.release_date) BETWEEN 7 AND 9 THEN 'Q3'
			WHEN MONTH(g.release_date) BETWEEN 10 AND 12 THEN 'Q4'
        END AS `quarter`,
	t.name
FROM games AS g
	JOIN teams AS t ON g.team_id = t.id
WHERE YEAR(g.release_date) = 2022 
	AND MONTH(g.release_date) IN (2,4,6,8,10,12)
    AND RIGHT(g.name, 1) LIKE 2
ORDER BY `quarter`;

# 09. Full info for games
SELECT
	g.name,
    IF(g.budget < 50000, 'Normal budget', 'Insufficient budget') AS budget_level,
    t.name AS team_name,
    a.name AS address_name
FROM games AS g
	LEFT JOIN games_categories AS gc ON g.id = gc.game_id
    JOIN teams AS t 		ON g.team_id = t.id
    JOIN offices AS o 		ON t.office_id = o.id
    JOIN addresses AS a 	ON o.address_id = a.id
WHERE g.release_date IS NULL
	AND gc.category_id IS NULL
ORDER BY g.name;
	
# 10. Find all basic information for a game
DELIMITER $$
CREATE FUNCTION udf_game_info_by_name (game_name VARCHAR (20))
RETURNS TEXT
DETERMINISTIC
	BEGIN
		DECLARE result_text TEXT;
        
        SET result_text := (SELECT CONCAT(
					'The ',
                    g.name,
                    ' is developed by a ',
                    t.name,
                    ' in an office with an address ',
                    a.name
					)
		FROM games AS g
			JOIN teams AS t 		ON g.team_id = t.id
			JOIN offices AS o 		ON t.office_id = o.id
			JOIN addresses AS a 	ON o.address_id = a.id
		WHERE g.name LIKE game_name);
        
        RETURN result_text;
	END $$

# 11. Update Budget of the Games
DELIMITER $$
CREATE PROCEDURE udp_update_budget(min_game_rating FLOAT)
	BEGIN
		UPDATE games AS g
			LEFT JOIN games_categories AS gc ON g.id = gc.game_id
		SET g.budget = g.budget + 100000,
			g.release_date = ADDDATE(g.release_date, INTERVAL 1 YEAR) 
		WHERE category_id IS NULL
			AND g.rating > min_game_rating
            AND g.release_date IS NOT NULL;
    END $$

CALL udp_update_budget(8);
-- congrats, the procedure works hence - the budget is now increased 




