-- Whole data
SELECT *
FROM [BRAINLOADING].[dbo].[sales] s
	LEFT JOIN [BRAINLOADING].[dbo].[client] c on c.client_id = s.client_id
	LEFT JOIN [BRAINLOADING].[dbo].[product] p on p.product_id = s.product_id
	LEFT JOIN [BRAINLOADING].[dbo].[calendar] cal on cal.date = s.date


-- Sales by month
SELECT
	cal.year,
	cal.month_name,
	COUNT(s.item_id) quantity_items_sold,
	COUNT(DISTINCT s.sale_id) as quantity_individual_sales,
	SUM(p.price) sales_value
FROM [BRAINLOADING].[dbo].[sales] s
	LEFT JOIN [BRAINLOADING].[dbo].[product] p on p.product_id = s.product_id
	LEFT JOIN [BRAINLOADING].[dbo].[calendar] cal on cal.date = s.date
GROUP BY
	cal.year,
	cal.month_number,
	cal.month_name
ORDER BY
	cal.year,
	cal.month_number


-- Sales by month for Portuguese clients
SELECT
	cal.year,
	cal.month_name,
	COUNT(s.item_id) quantity_items_sold,
	COUNT(DISTINCT s.sale_id) as quantity_individual_sales,
	SUM(p.price) sales_value
FROM [BRAINLOADING].[dbo].[sales] s
	LEFT JOIN [BRAINLOADING].[dbo].[product] p on p.product_id = s.product_id
	LEFT JOIN [BRAINLOADING].[dbo].[calendar] cal on cal.date = s.date
	LEFT JOIN [BRAINLOADING].[dbo].[client] c on c.client_id = s.client_id
WHERE 
	c.country = 'Portugal'
GROUP BY
	cal.year,
	cal.month_number,
	cal.month_name
ORDER BY
	cal.year,
	cal.month_number


-- Sales by product and category (partitions)
SELECT 
	p.product_category,
	p.product_name,
	COUNT(*) quantity_sold,
	SUM(p.price) sales_value,
	SUM(COUNT(*)) OVER (PARTITION BY p.product_category) quantity_sold_category,
	SUM(SUM(p.price)) OVER (PARTITION BY p.product_category) sales_value_category
FROM [BRAINLOADING].[dbo].[sales] s
	LEFT JOIN [BRAINLOADING].[dbo].[product] p on p.product_id = s.product_id
GROUP BY
	p.product_category,
	p.product_name
ORDER BY
	p.product_category,
	p.product_name


-- Average quantity and value per sale (temp table)
DROP TABLE IF EXISTS #IndividualSales
CREATE TABLE #IndividualSales (
	sale_id INT, 
	total_value FLOAT,
	items_quantity FLOAT
)

INSERT INTO #IndividualSales
	SELECT 
		s.sale_id, 
		SUM(p.price) total_value,
		COUNT(s.item_id) items_quantity
	FROM [BRAINLOADING].[dbo].[sales] s
		LEFT JOIN [BRAINLOADING].[dbo].[product] p on p.product_id = s.product_id
	GROUP BY 
		s.sale_id



SELECT 
	ROUND(AVG(total_value), 2) average_sale_value,
	ROUND(AVG(items_quantity), 2) average_sale_items
FROM #IndividualSales

-- Average quantity and value per sale by gender
SELECT 
	CASE 
		WHEN c.gender = 0 THEN 'Female'
		WHEN c.gender = 1 THEN 'Male'
		ELSE ''
		END AS gender,
	ROUND(AVG(total_value), 2) average_sale_value,
	ROUND(AVG(items_quantity), 2) average_sale_items
FROM #IndividualSales
	LEFT JOIN [BRAINLOADING].[dbo].[sales] s on s.sale_id = #IndividualSales.sale_id
	LEFT JOIN [BRAINLOADING].[dbo].[client] c on c.client_id = s.client_id
GROUP BY
	c.gender


-- Average quantity and value per sale by country
SELECT 
	c.country,
	ROUND(AVG(total_value), 2) average_sale_value,
	ROUND(AVG(items_quantity), 2) average_sale_items
FROM #IndividualSales
	LEFT JOIN [BRAINLOADING].[dbo].[sales] s on s.sale_id = #IndividualSales.sale_id
	LEFT JOIN [BRAINLOADING].[dbo].[client] c on c.client_id = s.client_id
GROUP BY
	c.country
ORDER BY 2 desc


-- Comparing the average quantity and value per sale in Portugal, Spain and Italy 
SELECT 
	c.country,
	ROUND(AVG(total_value), 2) average_sale_value,
	ROUND(AVG(items_quantity), 2) average_sale_items
FROM #IndividualSales
	LEFT JOIN [BRAINLOADING].[dbo].[sales] s on s.sale_id = #IndividualSales.sale_id
	LEFT JOIN [BRAINLOADING].[dbo].[client] c on c.client_id = s.client_id
GROUP BY
	c.country
HAVING c.country in ('Portugal', 'Spain', 'Italy')
ORDER BY 2 desc


-- Ranking of category by sales (CTE, rank)
WITH CTE_category_sales as
(
	SELECT 
		p.product_category,
		p.product_name,
		SUM(p.price) sales_value,
		SUM(SUM(p.price)) OVER (PARTITION BY p.product_category) sales_value_category
	FROM [BRAINLOADING].[dbo].[sales] s
		LEFT JOIN [BRAINLOADING].[dbo].[product] p on p.product_id = s.product_id
	GROUP BY
		p.product_category,
		p.product_name
)

SELECT
	*,
	DENSE_RANK() OVER (ORDER BY sales_value_category DESC) category_sales_rank
FROM CTE_category_sales


-- Variation of sales over months (CTE, lag)
WITH CTE_monthly_sales as
(
	SELECT
		cal.year,
		cal.month_name,
		SUM(p.price) sales_value,
		LAG( SUM(p.price) , 1) OVER (ORDER BY cal.year, cal.month_number) previous_month_sales
	FROM [BRAINLOADING].[dbo].[sales] s
		LEFT JOIN [BRAINLOADING].[dbo].[product] p on p.product_id = s.product_id
		LEFT JOIN [BRAINLOADING].[dbo].[calendar] cal on cal.date = s.date
	GROUP BY
		cal.year,
		cal.month_number,
		cal.month_name
)

SELECT 
	year,
	month_name,
	sales_value,
	ROUND( ( sales_value - previous_month_sales) / previous_month_sales , 2) sales_growth
FROM CTE_monthly_sales


-- Client demografics (sub query)
SELECT
	MIN(c.age) minimum_age,
	MAX(c.age) maximum_age
FROM [BRAINLOADING].[dbo].[client] c


SELECT 
	ag.age_group,
	SUM(p.price) sales_value
FROM [BRAINLOADING].[dbo].[sales] s
	LEFT JOIN [BRAINLOADING].[dbo].[product] p on p.product_id = s.product_id
	LEFT JOIN [BRAINLOADING].[dbo].[client] c on c.client_id = s.client_id
	LEFT JOIN (
	-- The SELECT bellow is a subquery that gets the ages from the client table and attributes them an age group. this could be a temp table.
		SELECT 
			cli.age,
			CASE 
				WHEN cli.age < 15 THEN '<15'
				WHEN cli.age BETWEEN 15 AND 19 THEN '15 - 19'
				WHEN cli.age BETWEEN 20 AND 24 THEN '20 - 24'
				WHEN cli.age BETWEEN 25 AND 29 THEN '25 - 29'
				WHEN cli.age > 29 THEN '30+'
				END AS age_group
		FROM [BRAINLOADING].[dbo].[client] cli
		) ag on ag.age = c.age
GROUP BY 
	ag.age_group


-- Daily sales (view) 
IF OBJECT_ID('v_daily_sales', 'V') IS NOT NULL
    DROP VIEW v_daily_sales
GO
CREATE VIEW v_daily_sales
AS
	SELECT
		s.date,
		COUNT(s.item_id) quantity,
		SUM(p.price) revenue
	FROM [BRAINLOADING].[dbo].[sales] s 
		LEFT JOIN [BRAINLOADING].[dbo].[product] p on p.product_id = s.product_id
	GROUP BY s.date


-- Monthly sales by country
IF OBJECT_ID('v_monthly_sales_country', 'V') IS NOT NULL
    DROP VIEW v_monthly_sales_country
GO
CREATE VIEW v_monthly_sales_country
AS
	SELECT 
		c.country,
		cal.year,
		cal.month_name,
		COUNT(s.item_id) quantity,
		SUM(p.price) revenue
	FROM [BRAINLOADING].[dbo].[sales] s
		LEFT JOIN [BRAINLOADING].[dbo].[client] c on c.client_id = s.client_id
		LEFT JOIN [BRAINLOADING].[dbo].[product] p on p.product_id = s.product_id
		LEFT JOIN [BRAINLOADING].[dbo].[calendar] cal on cal.date = s.date
	GROUP BY
		c.country,
		cal.year,
		cal.month_name


-- Client view
IF OBJECT_ID('v_client_view', 'V') IS NOT NULL
    DROP VIEW v_client_view
GO
CREATE VIEW v_client_view
AS
	SELECT 
		s.client_id,
		COUNT(s.item_id) quantity,
		SUM(p.price) revenue,
		COUNT(DISTINCT s.sale_id) unique_sales
	FROM [BRAINLOADING].[dbo].[sales] s
		LEFT JOIN [BRAINLOADING].[dbo].[product] p on p.product_id = s.product_id
	GROUP BY 
		s.client_id

