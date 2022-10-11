DROP DATABASE ruk_database;
CREATE DATABASE ruk_database;
USE ruk_database;

# 01. Table Design
CREATE TABLE branches (
id INT PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(30) UNIQUE NOT NULL
);

CREATE TABLE employees(
id INT PRIMARY KEY AUTO_INCREMENT,
first_name VARCHAR(20) NOT NULL,
last_name VARCHAR(20) NOT NULL,
salary DECIMAL(10, 2) NOT NULL,
started_on DATE NOT NULL,
branch_id INT NOT NULL,
CONSTRAINT fk_employees_branches
	FOREIGN KEY(branch_id) REFERENCES branches(id)
);

CREATE TABLE clients(
id INT PRIMARY KEY AUTO_INCREMENT,
full_name VARCHAR(50) NOT NULL,
age INT NOT NULL
);

CREATE TABLE employees_clients(
employee_id INT,
client_id INT,
KEY pk_employees_clients(employee_id, client_id),
CONSTRAINT fk_employees_clients_employees
	FOREIGN KEY(employee_id) REFERENCES employees(id),
CONSTRAINT fk_employees_clients_clients
	FOREIGN KEY(client_id) REFERENCES clients(id)
);

CREATE TABLE bank_accounts(
id INT PRIMARY KEY AUTO_INCREMENT,
account_number VARCHAR(10) NOT NULL,
balance DECIMAL(10, 2) NOT NULL,
client_id INT UNIQUE NOT NULL,
CONSTRAINT fk_bank_accounts_clients
	FOREIGN KEY(client_id) REFERENCES clients(id)
);

CREATE TABLE cards(
id INT PRIMARY KEY AUTO_INCREMENT,
card_number VARCHAR(19) NOT NULL,
card_status VARCHAR(7) NOT NULL,
bank_account_id INT NOT NULL,
CONSTRAINT fk_cards_bank_accounts
	FOREIGN KEY(bank_account_id) REFERENCES bank_accounts(id)
);

-- filling the database

# 02. Insert
INSERT INTO cards(card_number, card_status, bank_account_id)
SELECT REVERSE(full_name), 'Active', id
FROM clients
WHERE id >= 191 AND id <= 200;

# 03. Update
UPDATE employees_clients 
SET employee_id = 
(SELECT * 
	FROM (SELECT employee_id
	FROM employees_clients
	GROUP BY employee_id
	ORDER BY COUNT(client_id), employee_id
	LIMIT 1) AS s)
WHERE employee_id = client_id;

# 04. Delete
DELETE e
FROM employees AS e
	LEFT JOIN employees_clients AS ec ON e.id = ec.employee_id
WHERE ec.client_id IS NULL;

# 05. Clients
SELECT id, full_name
FROM clients
ORDER BY id;

# 06. Newbies
SELECT
	id,
    CONCAT_WS(' ', first_name, last_name) AS full_name,
    CONCAT('$', salary)AS salary,
    started_on
FROM employees
WHERE salary >= 100000
	AND YEAR(started_on) > 2017
ORDER BY salary DESC, id DESC;

# 07. Cards against Humanity
SELECT 
	c.id,
    CONCAT_WS(' : ', c.card_number, cl.full_name) AS card_token
FROM cards AS c
	JOIN bank_accounts AS ba ON c.bank_account_id = ba.id
	JOIN clients AS cl ON ba.client_id = cl.id
ORDER BY c.id DESC;

# 08. Top 5 Employees
SELECT
	CONCAT_WS(' ', e.first_name, e.last_name) AS name,
    e.started_on,
	COUNT(ec.client_id) AS count_of_clients
FROM employees AS e
	LEFT JOIN employees_clients AS ec ON e.id = ec.employee_id
GROUP BY e.id
ORDER BY count_of_clients DESC, e.id 
LIMIT 5;

# 09. Branch cards
SELECT 
	b.name,
    COUNT(cr.id) AS count_of_cards
FROM branches AS b
	LEFT JOIN employees AS e ON b.id = e.branch_id
    LEFT JOIN employees_clients AS ec ON e.id = ec.employee_id
    LEFT JOIN clients AS c ON ec.client_id = c.id
    LEFT JOIN bank_accounts AS ba ON c.id = ba.client_id
    LEFT JOIN cards AS cr ON ba.id = cr.bank_account_id
GROUP BY b.id
ORDER BY count_of_cards DESC, b.name;

# 10. Extract card's count
DELIMITER $$
CREATE FUNCTION udf_client_cards_count(name VARCHAR(30))
RETURNS INT
DETERMINISTIC
	BEGIN
		DECLARE result INT;
		SET result := 
			(SELECT 
			COUNT(c.id) AS cards
			FROM clients AS c
				LEFT JOIN bank_accounts AS ba ON c.id = ba.client_id
				LEFT JOIN cards AS cr		  ON ba.id = cr.bank_account_id
			WHERE c.full_name = name);
		RETURN result;
    END $$

# 11. Client Info
DELIMITER $$
CREATE PROCEDURE udp_clientinfo(given_full_name VARCHAR(100))
	BEGIN 
		SELECT 
			c.full_name,
			c.age,
			ba.account_number,
			CONCAT('$', ba.balance) AS balance
		FROM clients AS c
			JOIN bank_accounts AS ba ON c.id = ba.client_id
		WHERE c.full_name = given_full_name;
    END $$



















