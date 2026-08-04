-- Subscriptions
SELECT *
FROM [dbs].[subscriptions];

SELECT churned, COUNT(*) AS Active_customers
FROM [dbs].[subscriptions]
WHERE churn_date IS NULL
GROUP BY churned; -- 287 Active customers


         -- EDA and EDT

SELECT *,
        DATA_TYPE, 
        CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'subscriptions';


    -- tYPE CASTING
ALTER TABLE [dbs].[subscriptions] ALTER COLUMN seats INT;
ALTER TABLE [dbs].[subscriptions] ALTER COLUMN monthly_revenue DECIMAL;
ALTER TABLE [dbs].[subscriptions] ALTER COLUMN signup_date DATE;
ALTER TABLE [dbs].[subscriptions] ALTER COLUMN churn_date DATE;
ALTER TABLE [dbs].[subscriptions] ALTER COLUMN support_tickets_12mo INT;
ALTER TABLE [dbs].[subscriptions] ALTER COLUMN nps_score INT;
ALTER TABLE [dbs].[subscriptions] ALTER COLUMN feature_usage_pct INT;

SELECT customer_id,
        COALESCE(CAST(churn_date AS VARCHAR), 'Active') AS STATUS
FROM [dbs].[subscriptions]
WHERE churn_date IS NULL;


    -- profiling
SELECT AVG(feature_usage_pct) AS feature_usage_average,MAX(feature_usage_pct) AS feature_usage_maximum,MIN(feature_usage_pct) AS feature_usage_minimum
FROM [dbs].[subscriptions];

SELECT AVG(monthly_revenue) AS monthly_revenue_average,MAX(monthly_revenue) AS monthly_revenue_maximum,MIN(monthly_revenue) AS monthly_revenue_minimum
FROM [dbs].[subscriptions];

SELECT AVG(nps_score) AS nps_average,MAX(nps_score) AS nps_maximum,MIN(nps_score) AS nps_minimum
FROM [dbs].[subscriptions];

SELECT AVG(support_tickets_12mo) AS support_ticket_average,MAX(support_tickets_12mo) AS support_ticket_maximum,MIN(support_tickets_12mo) AS support_ticket_minimum
FROM [dbs].[subscriptions];


    --Handling Missing values

UPDATE [dbs].[subscriptions] SET churn_reason = 'N/A' WHERE churn_reason = 'NULL';

    -- Checking for Outliers(Z-score method)

SELECT *
FROM [dbs].[subscriptions] 
WHERE monthly_revenue > (SELECT AVG(monthly_revenue) + (3 * STDEV(monthly_revenue)) FROM [dbs].[subscriptions])
    OR monthly_revenue < (SELECT AVG(monthly_revenue) - (3 * STDEV(monthly_revenue)) FROM [dbs].[subscriptions]) -- Found 18 outliers.

    -- Standardization

SELECT industry, COUNT(*) AS COUNT
FROM [dbs].[subscriptions]
GROUP BY industry
ORDER BY [COUNT] DESC;

SELECT [plan], COUNT(*) AS COUNT
FROM [dbs].[subscriptions]
GROUP BY [plan]
ORDER BY COUNT DESC;

SELECT region, COUNT(*) AS COUNT
FROM [dbs].[subscriptions]
GROUP BY region
ORDER BY COUNT DESC;

SELECT churn_reason, COUNT(*) AS COUNT
FROM [dbs].[subscriptions]
GROUP BY churn_reason
ORDER BY COUNT DESC;

    --Finding duplicates

SELECT customer_id, COUNT(*) AS COUNT
FROM [dbs].[subscriptions]
GROUP BY customer_id
HAVING COUNT(*) > 1; -- no DUPLICATES FOUND

-- monthly_revenue

SELECT * 
FROM dbs.monthly_revenue;

SELECT *,
        DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'monthly_revenue';

        -- EDA and EDT
    -- Type casting
 
ALTER TABLE dbs.monthly_revenue ALTER COLUMN [month] DATE;
ALTER TABLE dbs.monthly_revenue ALTER COLUMN total_active_customers INT;
ALTER TABLE dbs.monthly_revenue ALTER COLUMN new_customers INT;
ALTER TABLE dbs.monthly_revenue ALTER COLUMN churned_customers INT;
ALTER TABLE dbs.monthly_revenue ALTER COLUMN monthly_churn_rate_pct DECIMAL;
ALTER TABLE dbs.monthly_revenue ALTER COLUMN total_mrr DECIMAL;
ALTER TABLE dbs.monthly_revenue ALTER COLUMN avg_revenue_per_customer DECIMAL;
ALTER TABLE dbs.monthly_revenue ALTER COLUMN customer_acquisition_cost DECIMAL; 

    -- profiling

SELECT YEAR(month) AS [year], AVG(total_mrr) AS avg_mrr
FROM dbs.monthly_revenue
GROUP BY YEAR(month)
ORDER BY [year] ASC; --Avg mrr by year

SELECT YEAR(month) AS [YEAR], SUM(total_active_customers) AS total_customers_per_year
FROM dbs.monthly_revenue
GROUP BY YEAR(month)
ORDER BY [YEAR] DESC; --Total active customers per year

SELECT YEAR(month) AS [year], SUM(new_customers) AS new_customers
FROM dbs.monthly_revenue
GROUP BY YEAR(month)
ORDER BY [year] DESC; -- Total customers added per year

SELECT YEAR(month) AS [year], SUM(customer_acquisition_cost) AS cost_of_customer_acquisition
FROM dbs.monthly_revenue
GROUP BY YEAR(month) 
ORDER BY [year]; -- Customer acquisition cost per year
 
SELECT YEAR(month) AS [year], SUM(churned_customers) AS customers_churned_per_year
FROM dbs.monthly_revenue
GROUP BY YEAR(month) 
ORDER BY [year];  --CUstomers churned per year

        -- Churn Analysis

SELECT COUNT(customer_id)
FROM dbs.subscriptions; -- Total customers = 600

SELECT COUNT(churned)
FROM dbs.subscriptions
WHERE churned = 'YES'; -- Total churned = 313. ie; more than 50% of customers churned.




SELECT [plan], 
       COUNT(*) AS total_customers,
       SUM(CASE WHEN churned = 'YES' then 1 else 0 END) AS churned_customers,
       ROUND(
            (CAST(SUM(CASE WHEN churned = 'YES' THEN 1 ELSE 0 END)AS FLOAT) / COUNT(*)) * 100,
            2
            ) AS churn_rate_pct      
FROM [dbs].[subscriptions]
GROUP BY [plan]
ORDER BY churn_rate_pct DESC; 

SELECT billing_cycle,
        COUNT(*) AS total_customers,
        SUM(CASE WHEN churned = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
        ROUND(
            (CAST(SUM(CASE WHEN churned = 'Yes' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*)) * 100,
            2
            )AS churn_rate_pct
FROM [dbs].[subscriptions]
GROUP BY billing_cycle
ORDER BY churn_rate_pct DESC;

SELECT acquisition_channel,
        COUNT(*) AS total_customers,
        SUM(CASE WHEN churned = 'Yes' THEN 1 ELSE 0 END) AS  churned_customers,
        ROUND(
            (CAST(SUM(CASE WHEN churned = 'Yes' THEN 1 ELSE 0 END)AS FLOAT) / COUNT(*)) * 100,
            2
        )AS churn_rate_pct
FROM dbs.subscriptions
GROUP BY acquisition_channel
ORDER BY churn_rate_pct DESC;

SELECT company_size,
        COUNT(*) AS total_customers,
        SUM(CASE WHEN churned = 'Yes' THEN 1 ELSE 0 END) AS  churned_customers,
        ROUND(
            (CAST(SUM(CASE WHEN churned = 'Yes' THEN 1 ELSE 0 END)AS FLOAT) / COUNT(*)) * 100,
            2
        )AS churn_rate_pct
FROM dbs.subscriptions
GROUP BY company_size
ORDER BY churn_rate_pct DESC;

    -- High-risk segments
SELECT s.[plan],
        s.billing_cycle,
        s.company_size,
        COUNT(*) AS total_customers,
        SUM(CASE WHEN s.churned='Yes' THEN 1 ELSE 0 END) AS churned_count,
        ROUND((CAST(SUM(CASE WHEN s.churned = 'Yes' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*)) * 100,
        2
        )AS segment_churn_rate,
        ROUND(AVG(m.customer_acquisition_cost),2) AS avg_acquisition_cost,
        ROUND(SUM(CASE WHEN churned = 'Yes' THEN m.customer_acquisition_cost ELSE 0 END),2) AS total_wasted_cac
FROM dbs.subscriptions s
LEFT JOIN dbs.monthly_revenue m 
    ON DATEFROMPARTS(YEAR(s.signup_date),MONTH(s.signup_date),1) = m.[month]
GROUP BY s.[plan],s.billing_cycle,s.company_size 
HAVING COUNT(*) >= 5
ORDER BY total_wasted_cac DESC, segment_churn_rate DESC;


        -- Revenue Trends

WITH monthly_newmrr AS (
    SELECT  DATEFROMPARTS(YEAR(signup_date),MONTH(signup_date),1) AS [month_date],
            SUM(monthly_revenue) AS new_mrr
    FROM dbs.subscriptions
    GROUP BY DATEFROMPARTS(YEAR(signup_date),MONTH(signup_date), 1)
),
churned_mrr AS(
    SELECT DATEFROMPARTS(YEAR(churn_date),MONTH(churn_date),1) AS churned_date,
        SUM(monthly_revenue) AS churned_mrr
    FROM dbs.subscriptions
    WHERE churned = 'yes'
    GROUP BY DATEFROMPARTS(YEAR(churn_date),MONTH(churn_date),1)

)
SELECT FORMAT([month], 'yyyy-MM') AS [month],
        total_mrr AS beginning_mrr,
        ISNULL(n.new_mrr,0) AS new_mrr,
        ISNULL(m.churned_mrr,0) AS churned_mrr,
        ROUND(ISNULL(n.new_mrr,0),0) - ROUND(ISNULL(m.churned_mrr,0),0) AS net_mrr
FROM dbs.monthly_revenue r
LEFT JOIN monthly_newmrr n 
    ON DATEFROMPARTS(YEAR(r.[month]), MONTH(r.[month]),1) = n.[month_date]
LEFT JOIN churned_mrr m 
    ON DATEFROMPARTS(YEAR(r.[month]),MONTH(r.[month]),1) = m.churned_date
ORDER BY r.[month] ASC; -- new_mrr,churned_mrr,net_mrr


        -- Unit Economics

SELECT [plan],
        ROUND(AVG(monthly_revenue),2) AS avg_monthly_revenue,
        ROUND(AVG(DATEDIFF(month,signup_date,churn_date) * 1.0),2) AS avg_months_active,
        ROUND(AVG(monthly_revenue) * AVG(DATEDIFF(month,signup_date,churn_date) * 1.0),2) AS CLV,
        ROUND(AVG(monthly_revenue)* AVG(DATEDIFF(month,signup_date,churn_date) * 1.0)
         / AVG(r.customer_acquisition_cost),2) AS clv_cac_ratio
FROM dbs.subscriptions s
LEFT JOIN dbs.monthly_revenue r 
    ON DATEFROMPARTS(YEAR(s.signup_date),MONTH(s.signup_date),1) = r.[month]
WHERE churned = 'Yes'
GROUP BY [plan];


            -- At risk-indicator

SELECT DISTINCT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY feature_usage_pct ASC) OVER() AS usage_threshold,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY nps_score ASC) OVER() AS nps_threshold
FROM dbs.subscriptions
WHERE churned = 'Yes';  -- usage_threshold = 36, nps_threshold = 4

    -- Customers at-risk

SELECT customer_id,
        feature_usage_pct,
        nps_score
FROM dbs.subscriptions
WHERE churned = 'No' AND feature_usage_pct <= 36
    AND nps_score <= 4;  --27 customers are at-risk right now.
