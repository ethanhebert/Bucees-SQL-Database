/*
Timo’s Tots - Ethan Hebert, Elijah Payton, Grant Nelson, Spencer Rochel
CSC430 Project - Buc-ee’s Database System
Part 2 - Implementation & Utilization of Database
*/

/* CREATING DATABASE */
DROP DATABASE IF EXISTS bucees;
CREATE DATABASE bucees;
USE bucees;

/* CREATING TABLES */
DROP TABLE IF EXISTS food;
CREATE TABLE food(
food_no  	INTEGER  	NOT NULL,
food_price  FLOAT,
CONSTRAINT food_pk PRIMARY KEY (food_no)
);

DROP TABLE IF EXISTS jerky;
CREATE TABLE jerky(
jerky_no	INTEGER		NOT NULL,
flavor		VARCHAR(20)	NOT NULL,
CONSTRAINT jerky_pk PRIMARY KEY (jerky_no)
);

DROP TABLE IF EXISTS sandwich;
CREATE TABLE sandwich(
sandwich_no 	INTEGER 		NOT NULL,
sandwich_name	VARCHAR(20)		NOT NULL,
bread  			VARCHAR(20),
lettuce  		TINYINT,
tomato  		TINYINT,
pickles  		TINYINT,
CONSTRAINT sandwich_pk PRIMARY KEY (sandwich_no)
);

DROP TABLE IF EXISTS sandwich_meat;
CREATE TABLE sandwich_meat(
s_no		INTEGER		NOT NULL,
meat		VARCHAR(20)	NOT NULL,
CONSTRAINT sandwich_meat_pk PRIMARY KEY (s_no, meat)
);

DROP TABLE IF EXISTS dessert;
CREATE TABLE dessert(
dessert_no		INTEGER		NOT NULL,
dessert_name	VARCHAR(20)	NOT NULL,
CONSTRAINT dessert_pk PRIMARY KEY (dessert_no)
);

DROP TABLE IF EXISTS drink;
CREATE TABLE drink (
drink_no		INT			NOT NULL,
drink_price		FLOAT		NOT NULL,
drink_type		VARCHAR(20)	NOT NULL,
drink_size		CHAR(1)		NOT NULL,
CONSTRAINT drink_pk PRIMARY KEY (drink_no)
);

DROP TABLE IF EXISTS sale;
CREATE TABLE sale (
drink_item_no		INT		NOT NULL,
food_item_no		INT		NOT NULL,
sale_ticket_no		INT		NOT NULL,
CONSTRAINT sale_pk PRIMARY KEY (drink_item_no, food_item_no, sale_ticket_no)
);
	
DROP TABLE IF EXISTS shift;
CREATE TABLE shift (
shift_no	INTEGER		NOT NULL,
shift_time	DATETIME	NOT NULL,
position	VARCHAR(20)	NOT NULL,
essn		VARCHAR(9)	NOT NULL,
CONSTRAINT shift_pk PRIMARY KEY (shift_no)
);

DROP TABLE IF EXISTS employee;
CREATE TABLE employee (
emp_fname	VARCHAR(20)	NOT NULL,
emp_lname	VARCHAR(20)	NOT NULL,
ssn			VARCHAR(9)	NOT NULL,
CONSTRAINT employee_pk PRIMARY KEY (ssn)
);

DROP TABLE IF EXISTS ticket;
CREATE TABLE ticket(
ticket_time		DATETIME,
ticket_no		INTEGER		NOT NULL,
essn_fulfills	VARCHAR(9),
essn_cashiers	VARCHAR(9),
CONSTRAINT ticket_pk PRIMARY KEY (ticket_no)
);

DROP TABLE IF EXISTS customer;
CREATE TABLE customer(
cust_fname		VARCHAR(20),
cust_ticket_no	INTEGER			NOT NULL,
CONSTRAINT cust_pk PRIMARY KEY (cust_ticket_no)
);

/* FOREIGN KEYS */
ALTER TABLE sandwich
	ADD CONSTRAINT sandwich_no_fk
		FOREIGN KEY (sandwich_no) REFERENCES food(food_no)
			ON DELETE RESTRICT
			ON UPDATE CASCADE;

ALTER TABLE sandwich_meat
	ADD CONSTRAINT s_no_fk
		FOREIGN KEY (s_no) REFERENCES sandwich(sandwich_no)
			ON DELETE RESTRICT
			ON UPDATE CASCADE;

ALTER TABLE jerky
	ADD CONSTRAINT jerky_no_fk
		FOREIGN KEY (jerky_no) REFERENCES food(food_no)
			ON DELETE RESTRICT
			ON UPDATE CASCADE;

ALTER TABLE ticket
	ADD CONSTRAINT essn_fulfills_fk
		FOREIGN KEY (essn_fulfills) REFERENCES employee(ssn)
			ON DELETE SET NULL
			ON UPDATE CASCADE,
	ADD CONSTRAINT essn_cashiers_fk
		FOREIGN KEY (essn_cashiers) REFERENCES employee(ssn)
			ON DELETE SET NULL
			ON UPDATE CASCADE;

ALTER TABLE customer
	ADD CONSTRAINT cust_ticket_no_fk
		FOREIGN KEY (cust_ticket_no) REFERENCES ticket(ticket_no)
			ON DELETE RESTRICT
			ON UPDATE CASCADE;

ALTER TABLE shift
	ADD CONSTRAINT shift_ssn_fk
		FOREIGN KEY (essn) REFERENCES employee(ssn)
			ON DELETE RESTRICT
			ON UPDATE CASCADE;

ALTER TABLE dessert
	ADD CONSTRAINT dessert_no_fk
		FOREIGN KEY (dessert_no) REFERENCES food(food_no)
			ON DELETE RESTRICT
			ON UPDATE CASCADE;

ALTER TABLE sale
	ADD CONSTRAINT drink_no_fk
		FOREIGN KEY (drink_item_no) REFERENCES drink(drink_no)
			ON DELETE RESTRICT
			ON UPDATE CASCADE,
	ADD CONSTRAINT food_no_fk
		FOREIGN KEY (food_item_no) REFERENCES food(food_no)
			ON DELETE RESTRICT
			ON UPDATE CASCADE,
	ADD CONSTRAINT ticket_no_fk
		FOREIGN KEY (sale_ticket_no) REFERENCES ticket(ticket_no)
			ON DELETE RESTRICT
			ON UPDATE CASCADE;
            
/* INSERT, DELETE, AND UPDATE COMMANDS */
/* Adding XL Icee size */
INSERT INTO drink VALUES (110, 2.49, 'Icee', 'X');
/* Deleting XL Icee size */
DELETE FROM drink WHERE drink_no = 110;
/* Updating the price of the "Big Mama" sandwich */
UPDATE food
SET food_price = 24.99
WHERE food_no = 205;

/* 5 RETRIEVAL QUERIES */
/* See how much each dessert item costs */
SELECT d.dessert_name, f.food_price
FROM dessert d, food f
WHERE d.dessert_no = f.food_no;

/* See what position each employee is shifted at a given shift */
SELECT s.shift_no, s.position, e.emp_fname, e.emp_lname
FROM employee e, shift s
WHERE s.essn = e.ssn;

/* See all sandiwches that have pickles on them */
SELECT s.sandwich_no, s.sandwich_name
FROM sandwich s
WHERE s.pickles = 1;

/* See total profit from all tickets */
SELECT ROUND(SUM(f.food_price + d.drink_price), 2) AS total_profit
FROM ticket t, sale s, food f, drink d
WHERE t.ticket_no = s.sale_ticket_no AND f.food_no = s.food_item_no AND d.drink_no = s.drink_item_no;

/* See the names of the customer, chef, and cashier for each ticket */
SELECT chef.ticket_no, chef.cust_fname, chef.emp_fname AS chef_fname, chef.emp_lname AS chef_lname, cashier.emp_fname AS cashier_fname, cashier.emp_lname AS cashier_lname
FROM (SELECT *
	FROM ticket t, customer c, employee e, shift s
	WHERE t.ticket_no = c.cust_ticket_no AND t.essn_fulfills = e.ssn AND s.essn = e.ssn) chef
JOIN
	(SELECT *
	FROM ticket t, customer c, employee e, shift s
	WHERE t.ticket_no = c.cust_ticket_no AND t.essn_cashiers = e.ssn AND s.essn = e.ssn) cashier
ON chef.ticket_no = cashier.ticket_no
ORDER BY chef.ticket_no;

/* TRIGGER DEFINITION AND EXECUTION */
DROP TRIGGER IF EXISTS new_dessert_trig;
DELIMITER $$
CREATE TRIGGER new_dessert_trig
BEFORE INSERT ON dessert
FOR EACH ROW
BEGIN
	INSERT INTO food VALUES (NEW.dessert_no, NULL);
END$$
DELIMITER ;

INSERT INTO dessert VALUES (306, 'Pudding');

/* 3 VIEWS */
/* See what meats are on each sandwich */
DROP VIEW IF EXISTS sandiwich_meats_view;
CREATE VIEW sandwich_meats_view
AS
	SELECT s.sandwich_name, sm.meat
	FROM sandwich s, sandwich_meat sm
	WHERE s.sandwich_no = sm.s_no;
    
/* Order tickets by the time they were ordered */
DROP VIEW IF EXISTS ticket_by_time;
CREATE VIEW ticket_by_time
AS
	SELECT *
	FROM ticket t
	ORDER BY t.ticket_time;
   
/* See each customer and what specific food and drink items they ordered */
DROP VIEW IF EXISTS sale_items_view;
CREATE VIEW sale_items_view
AS
	SELECT s.sale_ticket_no AS ticket_no, c.cust_fname AS customer, sw.sandwich_name AS food, d.drink_type AS drink
	FROM sale s, ticket t, drink d, customer c, sandwich sw
	WHERE s.sale_ticket_no = t.ticket_no AND s.food_item_no = sw.sandwich_no AND s.drink_item_no = d.drink_no AND t.ticket_no = c.cust_ticket_no
	UNION
	SELECT s.sale_ticket_no, c.cust_fname, ds.dessert_name, d.drink_type
	FROM sale s, ticket t, drink d, customer c, dessert ds
	WHERE s.sale_ticket_no = t.ticket_no AND s.food_item_no = ds.dessert_no AND s.drink_item_no = d.drink_no AND t.ticket_no = c.cust_ticket_no
	UNION
	SELECT s.sale_ticket_no, c.cust_fname, j.flavor, d.drink_type
	FROM sale s, ticket t, drink d, customer c, jerky j
	WHERE s.sale_ticket_no = t.ticket_no AND s.food_item_no = j.jerky_no AND s.drink_item_no = d.drink_no AND t.ticket_no = c.cust_ticket_no;