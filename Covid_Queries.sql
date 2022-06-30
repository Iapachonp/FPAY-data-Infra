-- Query 1

CREATE VIEW ipachon-test.dt_test.Query_1 AS(
SELECT a.date, a.state, a.deaths FROM `ipachon-test.dt_test.covid` a 
JOIN(
SELECT date, MAX(deaths) deaths FROM `ipachon-test.dt_test.covid`
GROUP BY date) b ON a.deaths=b.deaths and a.date = b.date
ORDER BY date); 

-- Query 2

CREATE VIEW ipachon-test.dt_test.Query_2 AS (
SELECT *,
CASE 
WHEN RIGHT(state,1) <> 'e' then  concat('000', state , '999') 
ELSE state
END
as custom_code FROM `ipachon-test.dt_test.covid`) ;