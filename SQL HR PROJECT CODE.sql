
SELECT * FROM hr_project.hr;
USE hr_project;
SELECT * FROM hr;

-- CHANGE NAME OF COLUMN TO USEABLE FORMAT
ALTER TABLE hr
CHANGE COLUMN ï»¿id emp_id VARCHAR(20) NULL

-- CHECK DATATYPES FOR ALL COLUMNS
DESCRIBE hr;

SELECT birthdate FROM hr;
-- OBSERVED BIRTHDATES ARE IRREGULAR

SET sql_safe_updates=0

-- CHANGE DATES TO REGULAR FORMAT
UPDATE hr
SET birthdate = CASE
WHEN birthdate LIKE '%/%' THEN date_format(str_to_date(birthdate, '%m/%d/%Y'), '%Y-%m-%d')
WHEN birthdate LIKE '%-%' THEN date_format(str_to_date(birthdate, '%m-%d-%Y'), '%Y-%m-%d')
ELSE NULL
END;

-- CHECK CORRECTED BIRTHDATES
SELECT birthdate FROM hr;

DESCRIBE hr; -- OBSERVED birthdate still in text format

-- CONVERT TO DATE DATATYPE
ALTER TABLE hr
MODIFY COLUMN birthdate DATE;

-- SIMILARLY DO IT FOR HIRE_DATE AND TERMDATE
UPDATE hr
SET hire_date = CASE
WHEN hire_date LIKE '%/%' THEN date_format(str_to_date(hire_date, '%m/%d/%Y'), '%Y-%m-%d')
WHEN hire_date LIKE '%-%' THEN date_format(str_to_date(hire_date, '%m-%d-%Y'), '%Y-%m-%d')
ELSE NULL
END;

ALTER TABLE hr
MODIFY COLUMN hire_date DATE; -- SETS DATATYPE TO DATE.


-- TERM DATE HAS TIME WITH DATES
SELECT termdate FROM hr;

-- TERMDATE CORRECTION
UPDATE hr
SET termdate = IF(termdate IS NOT NULL AND termdate != '', date(str_to_date(termdate, '%Y-%m-%d %H:%i:%s UTC')), '0000-00-00')
WHERE true;

SELECT termdate from hr;

SET sql_mode = 'ALLOW_INVALID_DATES';

ALTER TABLE hr
MODIFY COLUMN termdate DATE;


-- Add AGE Column
ALTER TABLE hr
ADD COLUMN age INT;

UPDATE hr
SET age = timestampdiff(YEAR, birthdate, curdate())

SELECT age FROM hr;

-- CHECK MAX & MIN age
SELECT MIN(age) AS YOUNGEST, MAX(age) AS OLDEST FROM hr;

-- ANALYSIS

-- WHAT IS GENDER BREAKDOWN OF THE COMPANY?
SELECT gender, COUNT(*) AS count
FROM hr
WHERE termdate = 0000-00-00
GROUP BY gender

-- WHAT IS RACE BREAKDOWN?
SELECT race, COUNT(*) AS count 
FROM hr
WHERE termdate= 0000-00-00
GROUP BY race 
ORDER BY count DESC

-- WHAT IS AGE DISTRIBUTION?
SELECT MIN(age) AS youngest, MAX(age) AS oldest 
FROM hr
WHERE termdate = 0000-00-00

SELECT 
(CASE 
WHEN (age>=18 AND age<=24) THEN '18-24'
WHEN (age>=25 AND age<=34) THEN '25-34'
WHEN (age>=35 AND age<=44) THEN '35-44'
WHEN (age>=45 AND age<=54) THEN '45-54'
WHEN (age>=55 AND age<=64) THEN '55-64'
ELSE '65+'
END )AS age_group, 
COUNT(*) AS count
FROM hr
WHERE termdate= 0000-00-00
GROUP BY age_group
ORDER BY age_group ASC

-- HOW MANY EMPLOYEES @ HQ VS REMOTE LOCATIONS?

SELECT location, COUNT(*) AS count
FROM hr
WHERE termdate = 0000-00-00
GROUP BY location

-- WHAT IS AVERAGE LENGTH OF EMPLOYEMENT FOR TERMINATED EMPLOYEES?
SELECT AVG(datediff(termdate, hire_date))/365 AS avg_length_employment
FROM hr
WHERE termdate <= curdate() AND termdate != 0000-00-00 AND age>=18 

-- HOW DOES GENDER VARY ACROSS DEPARTMENTS AND JOB TITLES?
SELECT department, gender, COUNT(*) AS count
FROM hr
WHERE termdate = 0000-00-00
GROUP BY department, gender
ORDER BY department

-- WHAT IS THE DISTRIBUTION OF JOB TITLES ACROSS THE COMPANY?
SELECT jobtitle, COUNT(*) AS count
FROM hr
WHERE termdate = 0000-00-00
GROUP BY jobtitle
ORDER BY jobtitle 

-- WHAT DEPARTMENT HAS HIGHEST TURNOVER RATE? (TURNOVER RATE MEANS HOW MANY EMPLOYEES LEAVE A FIRM IN A TIME FRAME)
SELECT department, total_count, terminated_count, terminated_count/total_count AS termination_rate
FROM (SELECT department, COUNT(*) AS total_count, SUM( CASE WHEN termdate != 0000-00-00 AND termdate<=curdate() THEN 1 ELSE 0 END) AS terminated_count
FROM hr
GROUP BY department
) AS subquery 
ORDER BY termination_rate DESC

-- WHAT IS DISTRIBUTION OF EMPLOYEES ACROSS LOCATIONS BY CITY & STATE?
SELECT location_state, COUNT(*) AS count
FROM hr
WHERE termdate=0000-00-00
GROUP BY location_state 
ORDER BY count DESC

-- HOW HAS COMPANY'S EMPLOYEE COUNT CHANGED OVER TIME BASED ON HIRE AND TERM DATES?
SELECT year, hires, terminations, hires - terminations AS net_change , ((hires - terminations)/hires)*100 AS net_change_percent
FROM ( SELECT YEAR(hire_date) AS year, COUNT(*) AS hires, SUM(CASE WHEN termdate!=0 AND termdate<= curdate() THEN 1 ELSE 0 END) AS terminations 
FROM hr
GROUP BY YEAR(hire_date)) AS subquery
ORDER BY year ASC

-- WHAT IS TENURE DISTRIBUTION FOR EACH DEPT?
SELECT department, AVG(datediff(termdate, hire_date)/365) AS avg_tenure       -- round(_______,0) can be used to round off
FROM hr
WHERE termdate<=curdate() AND termdate != 0000-00-00 
GROUP BY department 

