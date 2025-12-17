
/******Bank Marketing Campaign Analysis*******/


CREATE DATABASE BankMarketingDB;
GO

-- Use the database you created (or the one you already use)
USE BankMarketingDB;
GO
select top 10 * from bank_full

SELECT COUNT(*) AS total_rows FROM bank_full;


*******************************************************************


-------TOP 5 JOB TYPES WITH HIGHEST AVERAGE BALANCE-------

SELECT TOP 5
    job,
    AVG(CAST(balance AS FLOAT)) AS avg_balance
FROM bank_full
WHERE job IS NOT NULL
GROUP BY job
ORDER BY avg_balance DESC;

-------CAMPAIGN SUCCESS RATE BY EDUCATION (USING JOINS)------

---CREATE EDUCATION LOOKUP TABLE (For Proper JOIN)
CREATE TABLE dim_education (
    education VARCHAR(50) PRIMARY KEY
);

----INSERT DISTINCT EDUCATION VALUES 
INSERT INTO dim_education (education)
SELECT DISTINCT education
FROM bank_full
WHERE education IS NOT NULL;

-----CALCULATE SUCCESS RATE USING JOIN

SELECT
    e.education,
    COUNT(*) AS total_contacts,
    SUM(CASE WHEN b.y = 'yes' THEN 1 ELSE 0 END) AS successful_contacts,
    CAST(SUM(CASE WHEN b.y = 'yes' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) AS success_rate
FROM bank_full b
JOIN dim_education e
    ON b.education = e.education
GROUP BY e.education
ORDER BY success_rate DESC;

*************************************************

--------- CREATE VIEW -----------

CREATE VIEW vw_ClientSummary AS
SELECT
    job,
    education,
    COUNT(*) AS total_clients,
    AVG(CAST(balance AS FLOAT)) AS avg_balance,
    SUM(CASE WHEN loan = 'yes' THEN 1 ELSE 0 END) AS total_loans,
    COUNT(DISTINCT contact) AS contact_types,
    CAST(SUM(CASE WHEN y = 'yes' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) AS success_rate
FROM bank_full
GROUP BY job, education;

SELECT * FROM vw_ClientSummary;

---------CAMPAIGN PERFORMANCE VIEW BY MONTH

CREATE VIEW vw_CampaignPerformanceByMonth AS
SELECT
    month,
    COUNT(*) AS total_contacts,
    SUM(CASE WHEN y = 'yes' THEN 1 ELSE 0 END) AS successful_contacts,
    CAST(SUM(CASE WHEN y = 'yes' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) AS success_rate
FROM bank_full
GROUP BY month;

SELECT * FROM vw_CampaignPerformanceByMonth;


***********************************************************

------------------ INDEXES ------------------

--------CREATE INDEXES

CREATE NONCLUSTERED INDEX idx_age ON bank_full(age);
CREATE NONCLUSTERED INDEX idx_job ON bank_full(job);
CREATE NONCLUSTERED INDEX idx_marital ON bank_full(marital);



******************************************************

--------------- STORED PROCEDURE (UPDATE BALANCE) ------------

--------CREATE TRANSACTIONS TABLE

CREATE TABLE Transactions (
    transaction_id INT IDENTITY(1,1) PRIMARY KEY,
    client_id INT,
    transaction_date DATE,
    amount DECIMAL(10,2)
);


-------------STORED PROCEDURE TO UPDATE BALANCE

CREATE PROCEDURE usp_UpdateBalance
AS
BEGIN
    UPDATE bank_full
    SET balance = balance + ISNULL(t.total_amount, 0)
    FROM bank_full b
    JOIN (
        SELECT client_id, SUM(amount) AS total_amount
        FROM Transactions
        GROUP BY client_id
    ) t ON b.age = t.client_id;  -- Using age as dummy client id (for practice)
END;


EXEC usp_UpdateBalance;
