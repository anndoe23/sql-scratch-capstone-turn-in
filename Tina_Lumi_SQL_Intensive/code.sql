-- 1.Take a look at the first 100 rows of data in the subscriptions table. How many different segments do you see?

SELECT *
FROM subscriptions
LIMIT 100;

-- based on the query above there are 2 segments - 87 and 30, to be sure let's white another query

SELECT DISTINCT segment
,COUNT (*) as total
FROM subscriptions
GROUP BY segment;

-- Answer1: two segments - 87 and 30

-- 2.Determine the range of months of data provided. Which months will you be able to calculate churn for?

SELECT MIN(subscription_start) AS 'min_start'
	,MAX(subscription_start) AS 'max_start'
  ,MIN(subscription_end) AS 'min_end'
  ,MAX(subscription_end) AS 'max_end'
FROM subscriptions;

-- Answer2: The range of months provided: December 2016 - March 2017 (4 months). Since the first subscription is 2016-12-01 taking in consideration minimum of 31 days there can be no cancelations in December, hence we can provide churn analysis only for 3 months - January, February and March (crurn = cancelations duting a period of time / active subscribers)

-- 3.You'll be calculating the churn rate for both segments (87 and 30) over the first 3 months of 2017 (you can't calculate it for December, since there are no subscription_end values yet). To get started, create a temporary table of months.

WITH months AS (
  SELECT 
    '2017-01-01' AS first_day, 
    '2017-01-31' AS last_day 
  UNION 
  SELECT 
    '2017-02-01' AS first_day, 
    '2017-02-28' AS last_day 
  UNION 
  SELECT 
    '2017-03-01' AS first_day, 
    '2017-03-31' AS last_day
	FROM subscriptions
),

-- Answer3: Temporary table months created

-- Create a temporary table, cross_join, from subscriptions and your months. Be sure to SELECT every column.

cross_join AS (
	SELECT *
	FROM subscriptions
	CROSS JOIN months),

-- Answer 4: Tempopary table cross_join created.

-- 5.Create a temporary table, status, from the cross_join table you created.
-- 6.Add an is_canceled_87 and an is_canceled_30 column to the status temporary table. This should be 1 if the subscription is canceled during the month and 0 otherwise.

status AS (
  SELECT id
  ,first_day as month
  ,CASE
      WHEN (subscription_start < first_day) 
        AND (
          subscription_end > first_day 
          OR subscription_end IS NULL
        ) 
  			AND segment = 87
  		THEN 1
      ELSE 0
  	END AS is_active_87
  ,CASE
      WHEN subscription_end BETWEEN first_day AND last_day
  		AND segment = 87
  		THEN 1
      ELSE 0
    END AS is_canceled_87
  ,CASE
      WHEN (subscription_start < first_day) 
        AND (
          subscription_end > first_day 
          OR subscription_end IS NULL
        )
  			AND segment = 30
  		THEN 1
      ELSE 0
 	 END AS is_active_30
   ,CASE
  		WHEN subscription_end BETWEEN first_day AND last_day
  		AND segment = 30
  		THEN 1
      ELSE 0
    END AS is_canceled_30
	FROM cross_join),
  
-- Answer 5&6: Temporary table status created. Necessary columns added.
  
-- 7. Create a status_aggregate temporary table that is a SUM of the active and canceled subscriptions for each segment, for each month.

status_aggregate AS (
SELECT month
  ,SUM(is_active_87) AS sum_active_87
  ,SUM(is_canceled_87) AS sum_canceled_87
  ,SUM(is_active_30) AS sum_active_30
  ,SUM(is_canceled_30) AS sum_canceled_30
FROM status
GROUP BY month
)

-- Answer 7: Temporary table status_aggregate created.

-- 8.Calculate the churn rates for the two segments over the three month period. Which segment has a lower churn rate?

SELECT month
	,1.0 * sum_canceled_87/sum_active_87 as churn_87
  ,1.0 * sum_canceled_30/sum_active_30 as churn_30
FROM status_aggregate
GROUP BY month;

-- Answer 8: Churn rates calculated. Segment 30 has lower churn rate.

-- 9.How would you modify this code to support a large number of segments?

-- Answer 9: I would avoid manually entering segment numbers and manually creating sum_active and sum_cancelled columns for each segment because the same data can be stored in just 2 colums and not 2*number_of_segments columns