CREATE DATABASE stc;
USE stc;

# 01. Table Design
CREATE TABLE addresses
(
	`id` INT PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL
);

CREATE TABLE categories
(
	`id` INT PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(10) NOT NULL
);

CREATE TABLE clients
(
	`id` INT PRIMARY KEY AUTO_INCREMENT,
    `full_name` VARCHAR(50) NOT NULL,
    `phone_number` VARCHAR(20) NOT NULL
);

CREATE TABLE drivers
(
	`id` INT PRIMARY KEY AUTO_INCREMENT,
    `first_name` VARCHAR(30) NOT NULL,
    `last_name` VARCHAR(30) NOT NULL,
    `age` INT NOT NULL,
    `rating` FLOAT DEFAULT 5.5
);

CREATE TABLE cars
(
	`id` INT PRIMARY KEY AUTO_INCREMENT,
    `make` VARCHAR(20) NOT NULL,
    `model` VARCHAR(20),
    `year` INT NOT NULL DEFAULT 0,
    `mileage` INT DEFAULT 0,
    `condition` CHAR(1) NOT NULL,
    `category_id` INT NOT NULL,
    CONSTRAINT fk_cars_categories
		FOREIGN KEY(category_id) REFERENCES categories(id)
);

CREATE TABLE courses
(
	`id` INT PRIMARY KEY AUTO_INCREMENT,
    `from_address_id` INT NOT NULL,
    `start` DATETIME NOT NULL,
    `bill` DECIMAL(10, 2) DEFAULT 10,
    `car_id` INT NOT NULL,
    `client_id` INT NOT NULL,
    CONSTRAINT fk_courses_addresses
		FOREIGN KEY(from_address_id) REFERENCES addresses(id),
	CONSTRAINT fk_courses_cars
		FOREIGN KEY(car_id) REFERENCES cars(id),
	CONSTRAINT fk_courses_clients
		FOREIGN KEY(client_id) REFERENCES clients(id)
);

CREATE TABLE cars_drivers
(
	`car_id` INT NOT NULL,
    `driver_id` INT NOT NULL,
    CONSTRAINT pk_car_driver
		PRIMARY KEY(car_id, driver_id),
	CONSTRAINT fk_carsDrivers_cars
		FOREIGN KEY(car_id) REFERENCES cars(id),
	CONSTRAINT fk_carsDrivers_drivers
		FOREIGN KEY(driver_id) REFERENCES drivers(id)
);

-- filling the database

# 02. Insert
INSERT INTO clients (full_name, phone_number)
SELECT CONCAT(d.first_name, ' ', d.last_name), CONCAT('(088) 9999', d.id * 2)
FROM drivers AS d 
WHERE id BETWEEN 10 AND 20 ;

# 03. Update
UPDATE cars
SET `condition` = 'C'
WHERE (mileage >= 800000 OR mileage IS NULL) 
	AND `year` <= 2010
    AND `make` NOT LIKE '%Mercedes-Benz%';
   
# 04. Delete
DELETE c
FROM clients AS c
	LEFT JOIN courses AS co ON c.id = co.client_id
WHERE co.`start` IS NULL
	AND LENGTH(c.full_name) > 3;
  
-- resets the entire DATABASE softuni_imdb

# 05. Cars
SELECT `make`, `model`, `condition`
FROM cars
ORDER BY id;

# 06. Drivers and Cars
SELECT d.first_name, d.last_name, c.`make`, c.`model`, c.mileage
FROM drivers AS d
	JOIN cars_drivers AS cd ON d.id = cd.driver_id
    JOIN cars AS c ON cd.car_id = c.id
WHERE c.mileage IS NOT NULL
ORDER BY c.mileage DESC, d.first_name;

# 07. Number of courses
# SELECT *
SELECT 
	c.id,
    c.`make`,
    c.mileage,
    COUNT(co.id) AS count_of_courses,
    ROUND(AVG(co.bill), 2) AS avg_bill
FROM cars AS c
	LEFT JOIN courses AS co ON c.id = co.car_id
GROUP BY c.id
HAVING count_of_courses != 2
ORDER BY count_of_courses DESC, c.id;

# 08. Regular clients
SELECT
	c.full_name,
    COUNT(*) AS count_of_cars,
    SUM(co.bill) AS total_sum
FROM clients AS c
	JOIN courses AS co ON c.id = co.client_id
WHERE  LOCATE('a', c.full_name) = 2
GROUP BY c.id
HAVING count_of_cars > 1
ORDER BY full_name;

# 09. Full info for courses
SELECT 
	a.name,
    CASE
		WHEN HOUR(`start`) BETWEEN 6 AND 20 THEN 'Day'
        ELSE 'Night'
    END AS day_time,
    co.bill,
    c.full_name,
    cr.make,
    cr.model,
    cat.name
FROM addresses AS a
	 JOIN courses AS co ON a.id = co.from_address_id
	 JOIN clients AS c ON co.client_id = c.id
     JOIN cars AS cr ON co.car_id = cr.id
     JOIN categories AS cat ON cr.category_id = cat.id
ORDER BY co.id;

# 10. Find all courses by client’s phone number
DELIMITER $$
CREATE FUNCTION udf_courses_by_client(phone_num VARCHAR (20))
RETURNS INT
DETERMINISTIC
	BEGIN
		DECLARE result INT;
        
        SET result := 
			(SELECT 
				COUNT(co.id)  
			FROM courses AS co
				JOIN clients AS cl ON co.client_id = cl.id
			WHERE cl.phone_number LIKE phone_num);
        
        RETURN result;
    END $$
    
# 11. Full info for address
DELIMITER $$
CREATE PROCEDURE udp_courses_by_address(address_name VARCHAR (100))
	BEGIN
		SELECT 
	a.name,
    cl.full_name,
	CASE
		WHEN co.bill < 20 THEN 'Low'
        WHEN co.bill < 30 THEN 'Medium'
        ELSE 'High'
    END AS level_of_bill,
	cr.make,
    cr.`condition`,
    ca.name AS cat_name
FROM addresses AS a
	JOIN courses 	AS co ON a.id = co.from_address_id
    JOIN clients 	AS cl ON co.client_id = cl.id
    JOIN cars 		AS cr ON co.car_id = cr.id
    JOIN categories AS ca ON cr.category_id = ca.id
WHERE a.name LIKE address_name
ORDER BY cr.make, cl.full_name;
    END $$





