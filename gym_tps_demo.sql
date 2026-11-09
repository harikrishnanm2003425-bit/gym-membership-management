-- =====================================================================
-- TPS (Transaction Processing) add-on for gym_db
-- Run AFTER gym_management_mysql57.sql
-- Step A: run this whole file once (creates 2 new procedures).
-- Step B: run the DEMO lines at the bottom ONE BY ONE in the same tab.
-- =====================================================================
USE gym_db;

DROP PROCEDURE IF EXISTS sp_register_member;
DROP PROCEDURE IF EXISTS sp_add_subscription;

DELIMITER //

-- TRANSACTION 1: Register a new member (starts as Inactive until they pay)
CREATE PROCEDURE sp_register_member(
    IN  p_name   VARCHAR(100),
    IN  p_gender VARCHAR(10),
    IN  p_dob    DATE,
    IN  p_phone  VARCHAR(15),
    IN  p_email  VARCHAR(100),
    OUT p_new_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    INSERT INTO Gym_Members (full_name, gender, dob, phone, email, join_date, status)
    VALUES (p_name, p_gender, p_dob, p_phone, p_email, CURDATE(), 'Inactive');
    SET p_new_id = LAST_INSERT_ID();
    COMMIT;
END //

-- TRANSACTION 2: Take payment + create subscription + activate member
-- Either ALL three steps succeed, or NOTHING is saved (rollback).
CREATE PROCEDURE sp_add_subscription(
    IN p_member_id  INT,
    IN p_trainer_id INT,
    IN p_plan       VARCHAR(20),
    IN p_amount     DECIMAL(10,2)
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    DECLARE v_days   INT DEFAULT 30;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_exists FROM Gym_Members WHERE member_id = p_member_id;
    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Transaction failed: member not found';
    END IF;

    IF p_plan = 'Quarterly' THEN SET v_days = 90;
    ELSEIF p_plan = 'Yearly' THEN SET v_days = 365;
    ELSE SET v_days = 30;
    END IF;

    -- Step 1: save the subscription and payment
    INSERT INTO Subscriptions (member_id, trainer_id, plan_name, start_date, end_date, amount, payment_status)
    VALUES (p_member_id, p_trainer_id, p_plan, CURDATE(), DATE_ADD(CURDATE(), INTERVAL v_days DAY), p_amount, 'Paid');

    -- Step 2: mark the member Active
    UPDATE Gym_Members SET status = 'Active' WHERE member_id = p_member_id;

    COMMIT;
END //

DELIMITER ;

-- =====================================================================
-- DEMO: run these one by one, in the SAME query tab. Screenshot each result.
-- =====================================================================

-- 1) Register a new member
-- CALL sp_register_member('Test User', 'Male', '2000-01-01', '9911111111', 'test@mail.com', @new_id);
-- SELECT @new_id AS new_member_id;
-- SELECT member_id, full_name, status FROM Gym_Members WHERE member_id = @new_id;      -- Inactive

-- 2) Pay for a plan (transaction commits)
-- CALL sp_add_subscription(@new_id, 1, 'Monthly', 1800);
-- SELECT member_id, full_name, status FROM Gym_Members WHERE member_id = @new_id;      -- Active now
-- SELECT * FROM Subscriptions WHERE member_id = @new_id;

-- 3) Check-in works for the new paid member
-- CALL sp_check_in(@new_id, NULL, 'Gym Floor');
-- SELECT * FROM Access_Logs ORDER BY log_id DESC LIMIT 3;

-- 4) Check-in is REJECTED for an expired member
-- CALL sp_check_in(5, NULL, 'Gym Floor');                                               -- Access denied

-- 5) Failed transaction: nothing is saved (rollback)
-- CALL sp_add_subscription(999, NULL, 'Monthly', 1500);                                 -- member not found
-- SELECT COUNT(*) AS subs_for_member_999 FROM Subscriptions WHERE member_id = 999;      -- 0
