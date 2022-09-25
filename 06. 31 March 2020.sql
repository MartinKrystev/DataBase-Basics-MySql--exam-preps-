CREATE DATABASE instd;
USE instd;

# 01. Table Design
CREATE TABLE users
(
	`id` INT PRIMARY KEY AUTO_INCREMENT,
    `username` VARCHAR(30) NOT NULL UNIQUE,
    `password` VARCHAR(30) NOT NULL,
    `email` VARCHAR(50) NOT NULL,
    `gender` CHAR(1) NOT NULL,
    `age` INT NOT NULL,
    `job_title` VARCHAR(40) NOT NULL,
    `ip` VARCHAR(30) NOT NULL
);

CREATE TABLE addresses
(
	`id` INT PRIMARY KEY AUTO_INCREMENT,
    `address` VARCHAR(30) NOT NULL,
    `town` VARCHAR(30) NOT NULL,
    `country` VARCHAR(30) NOT NULL,
    `user_id` INT NOT NULL,
    CONSTRAINT fk_addresses_users
		FOREIGN KEY(user_id) REFERENCES users(id)
);

CREATE TABLE photos
(
	`id` INT PRIMARY KEY AUTO_INCREMENT,
    `description` TEXT NOT NULL,
    `date` DATETIME NOT NULL,
    `views` INT NOT NULL DEFAULT 0
);

CREATE TABLE comments
(
	`id` INT PRIMARY KEY AUTO_INCREMENT,
    `comment` VARCHAR(255) NOT NULL,
    `date` DATETIME NOT NULL,
    `photo_id` INT NOT NULL,
    CONSTRAINT fk_comments_photos
		FOREIGN KEY(photo_id) REFERENCES photos(id)
);

CREATE TABLE users_photos
(
	`user_id` INT NOT NULL,
    `photo_id` INT NOT NULL,
    KEY pk_usersPhotos(user_id, photo_id),
	CONSTRAINT fk_usersPhotos_users
		FOREIGN KEY(user_id) REFERENCES users(id),
	CONSTRAINT fk_usersPhotos_photos
		FOREIGN KEY(photo_id) REFERENCES photos(id)
);

CREATE TABLE likes
(
	`id` INT PRIMARY KEY AUTO_INCREMENT,
    `photo_id` INT,
    `user_id` INT,
    CONSTRAINT fk_likes_photos
		FOREIGN KEY(photo_id) REFERENCES photos(id),
	CONSTRAINT fk_likes_users
		FOREIGN KEY(user_id) REFERENCES users(id)
);

-- filling the database

# 02. Insert
INSERT INTO addresses (address, town, country, user_id)
SELECT username, `password`, ip, age
FROM users
WHERE gender LIKE 'M';

# 03. Update
UPDATE addresses
SET country = 
	CASE
		WHEN country LIKE 'B%' THEN 'Blocked'
        WHEN country LIKE 'T%' THEN 'Test'
        WHEN country LIKE 'P%' THEN 'In Progress'
        ELSE country
    END;
    
# 04. Delete
DELETE
FROM addresses
WHERE id % 3 = 0;

# 05. Users
SELECT
	username,
    gender,
    age
FROM users
ORDER BY age DESC, username;

# 06. Extract 5 most commented photos
SELECT
	p.id,
    p.`date` AS date_and_time,
    p.`description`,
    COUNT(p.id) AS commentsCount
FROM photos AS p
	JOIN comments AS c ON p.id = c.photo_id
GROUP BY p.id
ORDER BY commentsCount DESC, p.id
LIMIT 5;

# 07. Lucky users
SELECT
	CONCAT_WS(' ', u.id, u.username) AS id_username,
    u.email
FROM users AS u
	JOIN users_photos AS up ON u.id = up.user_id
WHERE u.id = up.photo_id
ORDER BY u.id;

# 08. Count likes and comments
SELECT 
	p.id AS photo_id,
	(SELECT COUNT(id)
    FROM likes
    WHERE photo_id = p.id) AS likes_count,
    (SELECT COUNT(id)
    FROM comments
    WHERE photo_id = p.id) AS comments_count
FROM photos AS p
ORDER BY 
	likes_count DESC,
	comments_count DESC,
    p.id;
    
# 09. The photo on the tenth day of the month
SELECT
	CONCAT(LEFT(`description`, 30), '...') AS summary,
    `date`
FROM photos
WHERE DAY(`date`) = 10
ORDER BY `date` DESC;

# 10. Get user’s photos count
DELIMITER $$
CREATE FUNCTION udf_users_photos_count(username VARCHAR(30))
RETURNS INT
DETERMINISTIC
	BEGIN
		DECLARE result INT;
        SET result := 
			(SELECT COUNT(up.user_id)
			FROM users AS u
				LEFT JOIN users_photos AS up ON u.id = up.user_id
			WHERE u.username LIKE username);
		RETURN result;
    END $$
    
#11. Increase user age
DELIMITER $$
CREATE PROCEDURE udp_modify_user(address VARCHAR(30), town VARCHAR(30))
	BEGIN
		UPDATE users AS u
			JOIN addresses AS a ON u.id = a.user_id
		SET u.age = u.age + 10
		WHERE a.address LIKE address
			AND a.town LIKE town;
    END $$




