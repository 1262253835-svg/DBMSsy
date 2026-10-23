-- =========================================================
-- SOCIAL GRAPH
-- DBMS Mini Project
-- MySQL 8.0
-- =========================================================

CREATE DATABASE IF NOT EXISTS social_graph;
USE social_graph;

-- =========================================================
-- 1. TABLE CREATION (DDL)
-- =========================================================

CREATE TABLE IF NOT EXISTS PERSON (
    person_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    age INT,
    city VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS INTEREST (
    interest_id INT PRIMARY KEY AUTO_INCREMENT,
    interest_name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS COMMUNITY (
    community_id INT PRIMARY KEY AUTO_INCREMENT,
    community_name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS EVENT (
    event_id INT PRIMARY KEY AUTO_INCREMENT,
    event_name VARCHAR(100) NOT NULL,
    event_date DATE,
    location VARCHAR(150),
    INDEX idx_event_date (event_date)
);

CREATE TABLE IF NOT EXISTS PERSON_INTEREST (
    person_id INT,
    interest_id INT,
    PRIMARY KEY (person_id, interest_id),
    INDEX idx_person_interest_interest (interest_id),
    FOREIGN KEY (person_id) REFERENCES PERSON(person_id),
    FOREIGN KEY (interest_id) REFERENCES INTEREST(interest_id)
);

CREATE TABLE IF NOT EXISTS FRIENDSHIP (
    person1_id INT,
    person2_id INT,
    since_date DATE,
    PRIMARY KEY (person1_id, person2_id),
    INDEX idx_friendship_person2 (person2_id),
    FOREIGN KEY (person1_id) REFERENCES PERSON(person_id),
    FOREIGN KEY (person2_id) REFERENCES PERSON(person_id)
);

CREATE TABLE IF NOT EXISTS EVENT_ATTENDANCE (
    person_id INT,
    event_id INT,
    PRIMARY KEY (person_id, event_id),
    INDEX idx_event_attendance_event (event_id),
    FOREIGN KEY (person_id) REFERENCES PERSON(person_id),
    FOREIGN KEY (event_id) REFERENCES EVENT(event_id)
);

CREATE TABLE IF NOT EXISTS MEMBERSHIP (
    person_id INT,
    community_id INT,
    join_date DATE,
    PRIMARY KEY (person_id, community_id),
    INDEX idx_membership_community (community_id),
    FOREIGN KEY (person_id) REFERENCES PERSON(person_id),
    FOREIGN KEY (community_id) REFERENCES COMMUNITY(community_id)
);

CREATE INDEX idx_person_city ON PERSON(city);
CREATE INDEX idx_person_age ON PERSON(age);

-- =========================================================
-- 2. SAMPLE DATA (DML)
-- =========================================================

INSERT INTO PERSON (person_id, name, age, city) VALUES
(1, 'Alice', 20, 'Pune'),
(2, 'Rahul', 21, 'Mumbai'),
(3, 'Sneha', 20, 'Pune'),
(4, 'Arjun', 22, 'Delhi'),
(5, 'Meera', 21, 'Bangalore'),
(6, 'Kabir', 20, 'Pune'),
(7, 'Riya', 22, 'Hyderabad'),
(8, 'Aman', 21, 'Mumbai'),
(9, 'Ritika', 21, 'Pune'),
(10, 'Chaitanya', 21, 'Pune'),
(11, 'Saksham', 21, 'Pune'),
(12, 'Aryan', 21, 'Pune');

INSERT INTO INTEREST (interest_id, interest_name) VALUES
(1, 'Photography'),
(2, 'Coding'),
(3, 'Music'),
(4, 'Gaming'),
(5, 'Travel'),
(6, 'Reading'),
(7, 'Fitness'),
(8, 'Cooking');

INSERT INTO COMMUNITY (community_id, community_name) VALUES
(1, 'Pune Techies'),
(2, 'Photography Club'),
(3, 'Music Lovers'),
(4, 'Gamers Hub'),
(5, 'Book Readers');

INSERT INTO EVENT (event_id, event_name, event_date, location) VALUES
(1, 'Tech Meetup', '2026-10-05', 'Pune'),
(2, 'Music Night', '2026-10-10', 'Mumbai'),
(3, 'Photography Walk', '2026-10-15', 'Pune'),
(4, 'Gaming Tournament', '2026-10-20', 'Delhi'),
(5, 'Book Club Meet', '2026-10-25', 'Bangalore');

INSERT INTO PERSON_INTEREST VALUES
(1,1),(3,1),(1,2),(2,2),(4,2),(8,2),
(3,3),(5,3),(2,4),(6,4),(1,5),(4,5),
(7,5),(12,5),(3,6),(5,6),(12,6),(6,7),
(8,7),(7,8),(12,8),
(9,2),(10,2),(10,3),(11,4),(12,1);

INSERT INTO FRIENDSHIP VALUES
(1,2,'2024-01-10'),
(1,3,'2024-03-15'),
(2,4,'2024-05-20'),
(2,6,'2024-06-12'),
(3,5,'2024-02-18'),
(4,7,'2024-08-10'),
(5,8,'2024-09-05'),
(6,7,'2024-04-22'),
(1,9,'2026-09-21'),
(9,10,'2026-09-21'),
(10,11,'2026-09-21'),
(11,12,'2026-09-21');

INSERT INTO EVENT_ATTENDANCE VALUES
(1,1),(2,1),(4,1),
(3,2),(5,2),(12,2),
(1,3),(3,3),(7,3),
(2,4),(6,4),(8,4),
(3,5),(5,5),(12,5);

INSERT INTO MEMBERSHIP VALUES
(1,1,'2025-01-10'),
(1,2,'2025-01-12'),
(2,1,'2025-02-15'),
(3,2,'2025-02-18'),
(3,3,'2025-01-25'),
(4,1,'2025-03-20'),
(5,3,'2025-03-05'),
(5,5,'2025-01-30'),
(6,4,'2025-02-20'),
(7,2,'2025-04-10'),
(8,4,'2025-03-15'),
(9,1,'2026-09-21'),
(10,1,'2026-09-21'),
(11,4,'2026-09-21'),
(12,1,'2026-09-21');

-- =========================================================
-- 3. VIEWS
-- =========================================================

CREATE OR REPLACE VIEW person_interests_view AS
SELECT p.name AS person, i.interest_name AS interest
FROM PERSON p
JOIN PERSON_INTEREST pi ON p.person_id = pi.person_id
JOIN INTEREST i ON pi.interest_id = i.interest_id;

CREATE OR REPLACE VIEW event_attendance_view AS
SELECT e.event_name AS event,
       COUNT(ea.person_id) AS total_attendees
FROM EVENT e
JOIN EVENT_ATTENDANCE ea ON e.event_id = ea.event_id
GROUP BY e.event_id, e.event_name;

-- =========================================================
-- 4. STORED PROCEDURES WITH CURSORS
-- =========================================================

DROP PROCEDURE IF EXISTS GetPersonFriends;
DROP PROCEDURE IF EXISTS GetPeopleByInterest;

DELIMITER $$

CREATE PROCEDURE GetPersonFriends(IN p_person_id INT)
BEGIN
    DECLARE finished INT DEFAULT 0;
    DECLARE friend_name VARCHAR(100);

    DECLARE friend_cursor CURSOR FOR
        SELECT p.name
        FROM PERSON p
        JOIN (
            SELECT person2_id AS friend_id
            FROM FRIENDSHIP
            WHERE person1_id = p_person_id

            UNION

            SELECT person1_id AS friend_id
            FROM FRIENDSHIP
            WHERE person2_id = p_person_id
        ) f ON p.person_id = f.friend_id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET finished = 1;

    DROP TEMPORARY TABLE IF EXISTS friend_results;
    CREATE TEMPORARY TABLE friend_results (
        friend_name VARCHAR(100)
    );

    OPEN friend_cursor;

    read_friends: LOOP
        FETCH friend_cursor INTO friend_name;

        IF finished = 1 THEN
            LEAVE read_friends;
        END IF;

        INSERT INTO friend_results VALUES (friend_name);
    END LOOP;

    CLOSE friend_cursor;

    SELECT friend_name AS friend
    FROM friend_results;
END$$

CREATE PROCEDURE GetPeopleByInterest(IN p_interest_id INT)
BEGIN
    DECLARE finished INT DEFAULT 0;
    DECLARE person_name VARCHAR(100);

    DECLARE people_cursor CURSOR FOR
        SELECT p.name
        FROM PERSON p
        JOIN PERSON_INTEREST pi ON p.person_id = pi.person_id
        WHERE pi.interest_id = p_interest_id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET finished = 1;

    DROP TEMPORARY TABLE IF EXISTS people_results;
    CREATE TEMPORARY TABLE people_results (
        person_name VARCHAR(100)
    );

    OPEN people_cursor;

    read_people: LOOP
        FETCH people_cursor INTO person_name;

        IF finished = 1 THEN
            LEAVE read_people;
        END IF;

        INSERT INTO people_results VALUES (person_name);
    END LOOP;

    CLOSE people_cursor;

    SELECT person_name AS person
    FROM people_results;
END$$

-- =========================================================
-- 5. FUNCTIONS
-- =========================================================

DROP FUNCTION IF EXISTS CountPersonInterests;
DROP FUNCTION IF EXISTS CountPersonFriends;

CREATE FUNCTION CountPersonInterests(p_person_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE total INT;

    SELECT COUNT(*)
    INTO total
    FROM PERSON_INTEREST
    WHERE person_id = p_person_id;

    RETURN total;
END$$

CREATE FUNCTION CountPersonFriends(p_person_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE total INT;

    SELECT COUNT(*)
    INTO total
    FROM FRIENDSHIP
    WHERE person1_id = p_person_id
       OR person2_id = p_person_id;

    RETURN total;
END$$

-- =========================================================
-- 6. TRIGGERS
-- =========================================================

DROP TRIGGER IF EXISTS PreventSelfFriendship;
DROP TRIGGER IF EXISTS ValidatePersonAge;

CREATE TRIGGER PreventSelfFriendship
BEFORE INSERT ON FRIENDSHIP
FOR EACH ROW
BEGIN
    IF NEW.person1_id = NEW.person2_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A person cannot be friends with themselves';
    END IF;
END$$

CREATE TRIGGER ValidatePersonAge
BEFORE INSERT ON PERSON
FOR EACH ROW
BEGIN
    IF NEW.age IS NOT NULL AND (NEW.age < 0 OR NEW.age > 120) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Age must be between 0 and 120';
    END IF;
END$$

DELIMITER ;

-- =========================================================
-- 7. EXAMPLE QUERIES FOR THE PROJECT
-- =========================================================

-- Display all people
SELECT * FROM PERSON;

-- Find people living in Pune
SELECT * FROM PERSON
WHERE city = 'Pune';

-- Sort people by age
SELECT * FROM PERSON
ORDER BY age DESC;

-- Display people and their interests
SELECT p.name, i.interest_name
FROM PERSON p
JOIN PERSON_INTEREST pi ON p.person_id = pi.person_id
JOIN INTEREST i ON pi.interest_id = i.interest_id;

-- Display friendships using a self-join
SELECT p1.name AS person, p2.name AS friend
FROM FRIENDSHIP f
JOIN PERSON p1 ON f.person1_id = p1.person_id
JOIN PERSON p2 ON f.person2_id = p2.person_id;

-- Count people in each city
SELECT city, COUNT(*) AS total_people
FROM PERSON
GROUP BY city;

-- Count interests per person
SELECT p.name, COUNT(pi.interest_id) AS total_interests
FROM PERSON p
LEFT JOIN PERSON_INTEREST pi ON p.person_id = pi.person_id
GROUP BY p.person_id, p.name;

-- Count members in each community
SELECT c.community_name, COUNT(m.person_id) AS total_members
FROM COMMUNITY c
LEFT JOIN MEMBERSHIP m ON c.community_id = m.community_id
GROUP BY c.community_id, c.community_name;

-- Count attendees per event
SELECT e.event_name, COUNT(ea.person_id) AS attendees
FROM EVENT e
LEFT JOIN EVENT_ATTENDANCE ea ON e.event_id = ea.event_id
GROUP BY e.event_id, e.event_name;

-- People older than the average age
SELECT name, age
FROM PERSON
WHERE age > (SELECT AVG(age) FROM PERSON);

-- People who have at least one interest
SELECT name
FROM PERSON
WHERE person_id IN (
    SELECT person_id FROM PERSON_INTEREST
);

-- Events with more than two attendees
SELECT e.event_name, COUNT(ea.person_id) AS attendees
FROM EVENT e
JOIN EVENT_ATTENDANCE ea ON e.event_id = ea.event_id
GROUP BY e.event_id, e.event_name
HAVING COUNT(ea.person_id) > 2;

-- Retrieve data from views
SELECT * FROM person_interests_view;
SELECT * FROM event_attendance_view;

-- Demonstrate functions
SELECT CountPersonInterests(1) AS interests_for_alice;
SELECT CountPersonFriends(1) AS friends_for_alice;

-- Demonstrate procedures
CALL GetPersonFriends(1);
CALL GetPeopleByInterest(2);

-- Display indexes
SHOW INDEX FROM PERSON;

-- Verify stored procedures, functions and triggers
SHOW PROCEDURE STATUS WHERE Db = 'social_graph';
SHOW FUNCTION STATUS WHERE Db = 'social_graph';
SHOW TRIGGERS FROM social_graph;