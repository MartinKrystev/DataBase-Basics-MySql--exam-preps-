DROP DATABASE colonial_journey_management_system_db;
CREATE DATABASE colonial_journey_management_system_db;
USE colonial_journey_management_system_db;

# 00. Table Design
CREATE TABLE planets(
	id INT PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(30) NOT NULL
);

CREATE TABLE spaceports(
	id INT PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(50) NOT NULL,
	planet_id INT,
CONSTRAINT fk_spaceports_planets
	FOREIGN KEY(planet_id) REFERENCES planets(id)
);

CREATE TABLE spaceships(
	id INT PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(50) NOT NULL,
    manufacturer VARCHAR(30) NOT NULL,
    light_speed_rate INT DEFAULT 0
);

CREATE TABLE colonists(
	id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    ucn CHAR(10) UNIQUE NOT NULL,
    birth_date DATE NOT NULL
);

CREATE TABLE journeys(
	id INT PRIMARY KEY AUTO_INCREMENT,
    journey_start DATETIME NOT NULL,
    journey_end DATETIME NOT NULL,
    purpose ENUM('Medical', 'Technical', 'Educational', 'Military'),
    destination_spaceport_id INT,
    spaceship_id INT,
    CONSTRAINT fk_journeys_spaceports
		FOREIGN KEY(destination_spaceport_id) REFERENCES spaceports(id),
	CONSTRAINT fk_journeys_spaceships
		FOREIGN KEY(spaceship_id) REFERENCES spaceships(id)
);

CREATE TABLE travel_cards(
	id INT PRIMARY KEY AUTO_INCREMENT,
    card_number CHAR(10) UNIQUE NOT NULL,
    job_during_journey ENUM('Pilot', 'Engineer', 'Trooper', 'Cleaner', 'Cook'),
    colonist_id INT,
    journey_id INT,
    CONSTRAINT fk_travel_cards_colonists
		FOREIGN KEY(colonist_id) REFERENCES colonists(id),
	CONSTRAINT fk_travel_cards_journeys
		FOREIGN KEY(journey_id) REFERENCES journeys(id)
);

-- filling the database

# 01. Insert
INSERT INTO travel_cards(card_number, job_during_journey, colonist_id, journey_id)
SELECT 
	IF(YEAR(birth_date) > 1979, 
		CONCAT(YEAR(birth_date), DAY(birth_date), LEFT(ucn, 4)),
		CONCAT(YEAR(birth_date), MONTH(birth_date), RIGHT(ucn, 4))
        ) ,
	CASE
		WHEN id % 2 = 0 THEN 'Pilot'
        WHEN id % 3 = 0 THEN 'Cook'
        ELSE 'Engineer'
    END,
    id,
    LEFT(ucn, 1) 
FROM colonists
WHERE id BETWEEN 96 AND 100;

# 02. Update
UPDATE journeys
SET purpose =
	CASE
		WHEN id % 2 = 0 THEN 'Medical'
        WHEN id % 3 = 0 THEN 'Technical'
        WHEN id % 5 = 0 THEN 'Educational'
        WHEN id % 7 = 0 THEN 'Military'
        ELSE purpose
    END;

# 03. Delete
DELETE c
FROM colonists AS c
	LEFT JOIN travel_cards AS tc ON c.id = tc.colonist_id
    LEFT JOIN journeys AS j ON tc.journey_id = j.id
WHERE journey_id IS NULL;

# 04. Extract all travel cards
SELECT card_number, job_during_journey
FROM travel_cards
ORDER BY card_number;

# 05. Extract all colonists
SELECT id, 
	CONCAT_WS(' ', first_name, last_name) AS full_name, 
	ucn
FROM colonists
ORDER BY first_name, last_name, id;

# 06. Extract all military journeys
SELECT id,
	journey_start,
	journey_end
FROM journeys
WHERE purpose LIKE 'Military'
ORDER BY journey_start;

# 07. Extract all pilots
SELECT
	c.id,
    CONCAT_WS(' ', c.first_name, c.last_name) AS full_name
FROM colonists AS c
	JOIN travel_cards AS tc ON c.id = tc.colonist_id
WHERE job_during_journey LIKE 'Pilot'
ORDER BY id;

# 08. Count all colonists
SELECT COUNT(*) AS count
FROM colonists AS c
	JOIN travel_cards AS tc ON c.id = tc.colonist_id
    JOIN journeys AS j ON tc.journey_id = j.id
WHERE j.purpose LIKE 'Technical';

# 09.Extract the fastest spaceship
SELECT 
	s.name AS spaceship_name,
    p.name AS spaceport_name
FROM spaceships AS s
	JOIN journeys AS j ON s.id = j.spaceship_id
    JOIN spaceports AS p ON j.destination_spaceport_id = p.id
ORDER BY s.light_speed_rate DESC
LIMIT 1;

# 10. Extract - pilots younger than 30 years
SELECT 
	s.name,
    s.manufacturer
FROM spaceships AS s
	 JOIN journeys AS j ON s.id = j.spaceship_id
     JOIN travel_cards AS tc ON j.id = tc.journey_id
     JOIN colonists AS c ON tc.colonist_id = c.id
WHERE YEAR(c.birth_date) > 1989
	 AND tc.job_during_journey LIKE 'Pilot'
ORDER BY s.name;

# 11. Extract all educational mission
SELECT
	p.name AS planet_name,
    s.name AS spaceport_name
FROM planets AS p
	JOIN spaceports AS s ON p.id = s.planet_id
    JOIN journeys AS j ON s.id = j.destination_spaceport_id
WHERE j.purpose LIKE 'Educational'
ORDER BY s.name DESC;

# 12. Extract all planets and their journey count
SELECT
	p.name AS planet_name,
    COUNT(*) AS journey_count
FROM planets AS p
	JOIN spaceports AS s ON p.id = s.planet_id
    JOIN journeys AS j ON s.id = j.destination_spaceport_id
GROUP BY p.id
ORDER BY journey_count DESC, p.name;

# 13. Extract the shortest journey
SELECT
	j.id,
    p.name AS planet_name,
    s.name AS spaceport_name,
    j.purpose AS journey_purpose
FROM planets AS p
	JOIN spaceports AS s ON p.id = s.planet_id
    JOIN journeys AS j ON s.id = j.destination_spaceport_id
ORDER BY (j.journey_end - j.journey_start)
LIMIT 1; 

# 14. Extract the less popular job
SELECT
	tc.job_during_journey AS job_name	
FROM journeys AS j
	JOIN travel_cards AS tc ON j.id = tc.journey_id
ORDER BY (j.journey_end - j.journey_start) DESC
LIMIT 1;

# 15. Get colonists count
DELIMITER $$
CREATE FUNCTION udf_count_colonists_by_destination_planet (planet_name VARCHAR (30))
RETURNS INT
DETERMINISTIC
	BEGIN
		DECLARE result INT;
        SET result :=
			(SELECT COUNT(*)
				FROM planets AS p
					JOIN spaceports AS s ON p.id = s.planet_id
					JOIN journeys AS j ON s.id = j.destination_spaceport_id
					JOIN travel_cards AS tc ON j.id = tc.journey_id
				WHERE p.name LIKE planet_name);
                
        RETURN result;
    END $$
    
# 16. Modify spaceship
DELIMITER $$
CREATE PROCEDURE udp_modify_spaceship_light_speed_rate(spaceship_name VARCHAR(50), 
														light_speed_rate_increse INT(11))
		BEGIN
            IF((SELECT COUNT(id)
				FROM spaceships
                WHERE name LIKE spaceship_name) > 0)
			THEN UPDATE spaceships
				SET light_speed_rate = light_speed_rate + light_speed_rate_increse
                WHERE name LIKE spaceship_name;
			ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Spaceship you are trying to modify does not exists.';
            END IF;
        END $$







