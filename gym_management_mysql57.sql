-- =====================================================================
-- Fitness Center & Gym Membership Management  (CRM / TPS + DSS)
-- Tables: Gym_Members, Trainers, Subscriptions, Access_Logs
-- DSS outputs: Active vs Inactive ratio, Trainer Utilization
-- Run in MySQL 8.x (Workbench or CLI):  SOURCE gym_management.sql;
-- =====================================================================

DROP DATABASE IF EXISTS gym_db;
CREATE DATABASE gym_db;
USE gym_db;
SET SQL_SAFE_UPDATES = 0;

-- ---------------------------------------------------------------------
-- 1. TABLES
-- ---------------------------------------------------------------------
CREATE TABLE Gym_Members (
    member_id   INT AUTO_INCREMENT PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    gender      ENUM('Male','Female','Other') NOT NULL,
    dob         DATE NOT NULL,
    phone       VARCHAR(15)  NOT NULL,
    email       VARCHAR(100) UNIQUE,
    join_date   DATE NOT NULL ,
    status      ENUM('Active','Inactive') NOT NULL DEFAULT 'Inactive'
);

CREATE TABLE Trainers (
    trainer_id          INT AUTO_INCREMENT PRIMARY KEY,
    full_name           VARCHAR(100) NOT NULL,
    specialization      VARCHAR(60),
    phone               VARCHAR(15),
    hire_date           DATE NOT NULL,
    max_weekly_sessions INT NOT NULL DEFAULT 20 CHECK (max_weekly_sessions > 0)
);

CREATE TABLE Subscriptions (
    subscription_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id       INT NOT NULL,
    trainer_id      INT NULL,                 -- optional personal trainer
    plan_name       ENUM('Monthly','Quarterly','Yearly') NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    amount          DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    payment_status  ENUM('Paid','Pending','Failed') NOT NULL DEFAULT 'Pending',
    CONSTRAINT fk_sub_member  FOREIGN KEY (member_id)  REFERENCES Gym_Members(member_id) ON DELETE CASCADE,
    CONSTRAINT fk_sub_trainer FOREIGN KEY (trainer_id) REFERENCES Trainers(trainer_id)   ON DELETE SET NULL,
    CONSTRAINT chk_dates CHECK (end_date > start_date)
);

CREATE TABLE Access_Logs (
    log_id       INT AUTO_INCREMENT PRIMARY KEY,
    member_id    INT NOT NULL,
    trainer_id   INT NULL,                    -- filled for Personal Training
    check_in     DATETIME NOT NULL,
    check_out    DATETIME NULL,
    session_type ENUM('Gym Floor','Personal Training','Class') NOT NULL DEFAULT 'Gym Floor',
    CONSTRAINT fk_log_member  FOREIGN KEY (member_id)  REFERENCES Gym_Members(member_id) ON DELETE CASCADE,
    CONSTRAINT fk_log_trainer FOREIGN KEY (trainer_id) REFERENCES Trainers(trainer_id)   ON DELETE SET NULL
);

CREATE INDEX idx_log_checkin  ON Access_Logs (check_in);
CREATE INDEX idx_sub_enddate  ON Subscriptions (end_date);

-- ---------------------------------------------------------------------
-- 2. SAMPLE DATA (dates are relative to today so DSS output always works)
-- ---------------------------------------------------------------------
INSERT INTO Trainers (full_name, specialization, phone, hire_date, max_weekly_sessions) VALUES
('Arjun Rao',   'Strength & Conditioning', '9800000001', '2022-03-01', 2),
('Meera Nair',  'Yoga & Flexibility',      '9800000002', '2023-01-15', 2),
('Kiran Shetty','Weight Loss / Cardio',    '9800000003', '2024-06-10', 2);

INSERT INTO Gym_Members (full_name, gender, dob, phone, email, join_date) VALUES
('Rahul Sharma',  'Male',   '1995-04-12', '9900000001', 'rahul@mail.com',  DATE_SUB(CURDATE(), INTERVAL 200 DAY)),
('Priya Menon',   'Female', '1998-09-23', '9900000002', 'priya@mail.com',  DATE_SUB(CURDATE(), INTERVAL 150 DAY)),
('Ankit Verma',   'Male',   '1992-01-30', '9900000003', 'ankit@mail.com',  DATE_SUB(CURDATE(), INTERVAL 120 DAY)),
('Sneha Reddy',   'Female', '2000-07-18', '9900000004', 'sneha@mail.com',  DATE_SUB(CURDATE(), INTERVAL 90 DAY)),
('Vikram Singh',  'Male',   '1989-11-05', '9900000005', 'vikram@mail.com', DATE_SUB(CURDATE(), INTERVAL 400 DAY)),
('Divya Iyer',    'Female', '1996-03-09', '9900000006', 'divya@mail.com',  DATE_SUB(CURDATE(), INTERVAL 300 DAY)),
('Manoj Kumar',   'Male',   '1991-12-21', '9900000007', 'manoj@mail.com',  DATE_SUB(CURDATE(), INTERVAL 60 DAY)),
('Asha Patel',    'Female', '1999-06-14', '9900000008', 'asha@mail.com',   DATE_SUB(CURDATE(), INTERVAL 250 DAY));

INSERT INTO Subscriptions (member_id, trainer_id, plan_name, start_date, end_date, amount, payment_status) VALUES
(1, 1,    'Quarterly', DATE_SUB(CURDATE(), INTERVAL 30 DAY),  DATE_ADD(CURDATE(), INTERVAL 60 DAY),  4500.00, 'Paid'),
(2, 1,    'Monthly',   DATE_SUB(CURDATE(), INTERVAL 10 DAY),  DATE_ADD(CURDATE(), INTERVAL 20 DAY),  1800.00, 'Paid'),
(3, 2,    'Yearly',    DATE_SUB(CURDATE(), INTERVAL 100 DAY), DATE_ADD(CURDATE(), INTERVAL 265 DAY), 14000.00,'Paid'),
(4, NULL, 'Monthly',   DATE_SUB(CURDATE(), INTERVAL 5 DAY),   DATE_ADD(CURDATE(), INTERVAL 25 DAY),  1500.00, 'Paid'),
(5, NULL, 'Monthly',   DATE_SUB(CURDATE(), INTERVAL 120 DAY), DATE_SUB(CURDATE(), INTERVAL 90 DAY),  1500.00, 'Paid'),
(6, 3,    'Quarterly', DATE_SUB(CURDATE(), INTERVAL 150 DAY), DATE_SUB(CURDATE(), INTERVAL 60 DAY),  4500.00, 'Paid'),
(7, 2,    'Monthly',   DATE_SUB(CURDATE(), INTERVAL 15 DAY),  DATE_ADD(CURDATE(), INTERVAL 15 DAY),  1800.00, 'Paid'),
(8, NULL, 'Monthly',   DATE_SUB(CURDATE(), INTERVAL 200 DAY), DATE_SUB(CURDATE(), INTERVAL 170 DAY), 1500.00, 'Paid');

-- Personal training sessions in last 30 days (trainer utilisation)
INSERT INTO Access_Logs (member_id, trainer_id, check_in, check_out, session_type) VALUES
(1, 1, DATE_SUB(NOW(), INTERVAL 2  DAY), DATE_SUB(NOW(), INTERVAL 2  DAY) + INTERVAL 1 HOUR, 'Personal Training'),
(1, 1, DATE_SUB(NOW(), INTERVAL 5  DAY), DATE_SUB(NOW(), INTERVAL 5  DAY) + INTERVAL 1 HOUR, 'Personal Training'),
(1, 1, DATE_SUB(NOW(), INTERVAL 9  DAY), DATE_SUB(NOW(), INTERVAL 9  DAY) + INTERVAL 1 HOUR, 'Personal Training'),
(2, 1, DATE_SUB(NOW(), INTERVAL 3  DAY), DATE_SUB(NOW(), INTERVAL 3  DAY) + INTERVAL 1 HOUR, 'Personal Training'),
(2, 1, DATE_SUB(NOW(), INTERVAL 7  DAY), DATE_SUB(NOW(), INTERVAL 7  DAY) + INTERVAL 1 HOUR, 'Personal Training'),
(2, 1, DATE_SUB(NOW(), INTERVAL 8  DAY), DATE_SUB(NOW(), INTERVAL 8  DAY) + INTERVAL 1 HOUR, 'Personal Training'),
(3, 2, DATE_SUB(NOW(), INTERVAL 4  DAY), DATE_SUB(NOW(), INTERVAL 4  DAY) + INTERVAL 1 HOUR, 'Personal Training'),
(3, 2, DATE_SUB(NOW(), INTERVAL 12 DAY), DATE_SUB(NOW(), INTERVAL 12 DAY) + INTERVAL 1 HOUR, 'Personal Training'),
(7, 2, DATE_SUB(NOW(), INTERVAL 6  DAY), DATE_SUB(NOW(), INTERVAL 6  DAY) + INTERVAL 1 HOUR, 'Personal Training'),
(6, 3, DATE_SUB(NOW(), INTERVAL 70 DAY), DATE_SUB(NOW(), INTERVAL 70 DAY) + INTERVAL 1 HOUR, 'Personal Training');

-- Regular gym-floor visits
INSERT INTO Access_Logs (member_id, trainer_id, check_in, check_out, session_type) VALUES
(1, NULL, DATE_SUB(NOW(), INTERVAL 1  DAY), DATE_SUB(NOW(), INTERVAL 1  DAY) + INTERVAL 90 MINUTE, 'Gym Floor'),
(4, NULL, DATE_SUB(NOW(), INTERVAL 2  DAY), DATE_SUB(NOW(), INTERVAL 2  DAY) + INTERVAL 60 MINUTE, 'Gym Floor'),
(4, NULL, DATE_SUB(NOW(), INTERVAL 4  DAY), DATE_SUB(NOW(), INTERVAL 4  DAY) + INTERVAL 75 MINUTE, 'Gym Floor'),
(2, NULL, DATE_SUB(NOW(), INTERVAL 1  DAY), DATE_SUB(NOW(), INTERVAL 1  DAY) + INTERVAL 60 MINUTE, 'Class'),
(5, NULL, DATE_SUB(NOW(), INTERVAL 95 DAY), DATE_SUB(NOW(), INTERVAL 95 DAY) + INTERVAL 60 MINUTE, 'Gym Floor');

-- ---------------------------------------------------------------------
-- 3. TPS LAYER: stored procedures (transactions)
-- ---------------------------------------------------------------------
DELIMITER //

-- 3a. Recalculate Active/Inactive status for every member.
--     Active = has a PAID subscription covering today.
CREATE PROCEDURE sp_sync_member_status()
BEGIN
    UPDATE Gym_Members m
    SET m.status = IF(EXISTS (
            SELECT 1 FROM Subscriptions s
            WHERE s.member_id = m.member_id
              AND s.payment_status = 'Paid'
              AND CURDATE() BETWEEN s.start_date AND s.end_date
        ), 'Active', 'Inactive');
END //

-- 3b. Check-in transaction: only members with a valid subscription may enter.
CREATE PROCEDURE sp_check_in(
    IN p_member_id  INT,
    IN p_trainer_id INT,
    IN p_type       VARCHAR(20)
)
BEGIN
    DECLARE v_valid INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_valid
    FROM Subscriptions
    WHERE member_id = p_member_id
      AND payment_status = 'Paid'
      AND CURDATE() BETWEEN start_date AND end_date;

    IF v_valid = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Access denied: no active paid subscription';
    END IF;

    INSERT INTO Access_Logs (member_id, trainer_id, check_in, session_type)
    VALUES (p_member_id, p_trainer_id, NOW(), p_type);

    COMMIT;
END //

-- 3c. Check-out
CREATE PROCEDURE sp_check_out(IN p_member_id INT)
BEGIN
    UPDATE Access_Logs
    SET check_out = NOW()
    WHERE member_id = p_member_id AND check_out IS NULL
    ORDER BY check_in DESC
    LIMIT 1;
END //

DELIMITER ;

-- Sync statuses now
CALL sp_sync_member_status();

-- ---------------------------------------------------------------------
-- 4. DSS LAYER: views for decision makers
-- ---------------------------------------------------------------------

-- 4a. Active vs Inactive ratio
CREATE OR REPLACE VIEW vw_active_inactive_ratio AS
SELECT
    status,
    COUNT(*) AS total_members,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Gym_Members), 2) AS percentage
FROM Gym_Members
GROUP BY status;

-- 4b. One-row summary (Active : Inactive)
CREATE OR REPLACE VIEW vw_membership_summary AS
SELECT
    SUM(status = 'Active')   AS active_members,
    SUM(status = 'Inactive') AS inactive_members,
    COUNT(*)                 AS total_members,
    ROUND(SUM(status = 'Active') / NULLIF(SUM(status = 'Inactive'), 0), 2) AS active_to_inactive_ratio,
    ROUND(SUM(status = 'Active') * 100.0 / COUNT(*), 2) AS retention_pct
FROM Gym_Members;

-- 4c. Trainer utilisation (last 30 days vs capacity = weekly slots x 4)
CREATE OR REPLACE VIEW vw_trainer_utilization AS
SELECT
    t.trainer_id,
    t.full_name AS trainer,
    t.specialization,
    COUNT(a.log_id)                                        AS sessions_last_30d,
    t.max_weekly_sessions * 4                              AS capacity_30d,
    ROUND(COUNT(a.log_id) * 100.0 / (t.max_weekly_sessions * 4), 1) AS utilization_pct,
    CASE
        WHEN COUNT(a.log_id) * 100.0 / (t.max_weekly_sessions * 4) >= 80 THEN 'Overloaded'
        WHEN COUNT(a.log_id) * 100.0 / (t.max_weekly_sessions * 4) >= 40 THEN 'Optimal'
        ELSE 'Under-utilised'
    END AS utilization_band
FROM Trainers t
LEFT JOIN Access_Logs a
       ON a.trainer_id = t.trainer_id
      AND a.session_type = 'Personal Training'
      AND a.check_in >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY t.trainer_id, t.full_name, t.specialization, t.max_weekly_sessions;

-- 4d. Extra DSS: members with expired plan who still visited (renewal leads - CRM)
CREATE OR REPLACE VIEW vw_renewal_leads AS
SELECT m.member_id, m.full_name, m.phone, MAX(s.end_date) AS last_plan_end
FROM Gym_Members m
JOIN Subscriptions s ON s.member_id = m.member_id
WHERE m.status = 'Inactive'
GROUP BY m.member_id, m.full_name, m.phone;

-- 4e. Extra DSS: plans expiring in next 7 days (CRM reminders)
CREATE OR REPLACE VIEW vw_expiring_soon AS
SELECT m.full_name, m.phone, s.plan_name, s.end_date,
       DATEDIFF(s.end_date, CURDATE()) AS days_left
FROM Subscriptions s
JOIN Gym_Members m ON m.member_id = s.member_id
WHERE s.end_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY);

-- ---------------------------------------------------------------------
-- 5. DEMO QUERIES (run these for your screenshots / report)
-- ---------------------------------------------------------------------
SELECT * FROM vw_active_inactive_ratio;
SELECT * FROM vw_membership_summary;
SELECT * FROM vw_trainer_utilization ORDER BY utilization_pct DESC;
SELECT * FROM vw_renewal_leads;
SELECT * FROM vw_expiring_soon;

-- TPS demo: valid check-in works, expired member is rejected
CALL sp_check_in(4, NULL, 'Gym Floor');   -- OK
-- CALL sp_check_in(5, NULL, 'Gym Floor'); -- ERROR 1644: Access denied
CALL sp_check_out(4);

-- Daily peak-hour analysis (bonus DSS)
SELECT HOUR(check_in) AS hour_of_day, COUNT(*) AS visits
FROM Access_Logs
GROUP BY HOUR(check_in)
ORDER BY visits DESC;

-- Revenue per plan (bonus DSS)
SELECT plan_name, COUNT(*) AS subs, SUM(amount) AS revenue
FROM Subscriptions
WHERE payment_status = 'Paid'
GROUP BY plan_name;
