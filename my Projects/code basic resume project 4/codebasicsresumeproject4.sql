/*1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.*/

SELECT distinct market 
FROM dim_customer
where customer="Atliq Exclusive" and region like'%APAC%';


----------------------------------------------------------------------------------------------------------------------------------------------


/*2.What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg*/


WITH  unique_2020 AS (
	SELECT count(DISTINCT product_code) AS unique_product_2020
    from fact_sales_monthly
    WHERE fiscal_year = 2020),
unique_2021 AS(
	SELECT count(DISTINCT product_code) AS unique_product_2021
    from fact_sales_monthly
    WHERE fiscal_year = 2021 )
SELECT 
       a.unique_product_2020, 
       b.unique_product_2021,
      round(((b.unique_product_2021-a.unique_product_2020)/a.unique_product_2020 * 100),2) as percentage_chg
FROM unique_2020 AS a
JOIN unique_2021 AS b;


---------------------------------------------------------------------------------------------------------------------------------------------
/*3.Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count*/


SELECT segment,count(distinct product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count desc;

-----------------------------------------------------------------------------------------------------------------------------------------------------


/*4.Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference
*/

WITH  product_2020 AS (
    SELECT p.segment,count(DISTINCT p.product_code) AS product_count_2020
	FROM dim_product AS p
	JOIN fact_sales_monthly AS s
	ON p.product_code = s.product_code
    WHERE fiscal_year = 2020 
    GROUP BY segment
    ORDER BY product_count_2020 desc),
product_2021 AS(
       SELECT p.segment,
	   count(DISTINCT p.product_code) AS product_count_2021
       FROM dim_product AS p
       JOIN fact_sales_monthly AS y
       ON p.product_code = y.product_code
       WHERE fiscal_year = 2021 
       GROUP BY segment
       ORDER BY product_count_2021 desc)
SELECT a.segment,
       a.product_count_2020, 
       b.product_count_2021, 
       (b.product_count_2021 - a.product_count_2020 ) AS differnce,
       
round(((b.product_count_2021 - a.product_count_2020 )/a.product_count_2020)*100,2) as percentage_difference_segment
FROM product_2020 AS a
JOIN product_2021 AS b
ON a.segment = b.segment;


-----------------------------------------------------------------------------------------------------------------------------------------------------



/*5.Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost
*/

SELECT p.product,
       p.product_code,
       m.manufacturing_cost
FROM dim_product AS p
INNER JOIN fact_manufacturing_cost AS m
ON p.product_code = m.product_code
WHERE manufacturing_cost = (SELECT max(manufacturing_cost) FROM fact_manufacturing_cost)
UNION
SELECT p.product,
       p.product_code,
       m.manufacturing_cost
FROM dim_product AS p
INNER JOIN fact_manufacturing_cost AS m
ON p.product_code = m.product_code
WHERE manufacturing_cost = (SELECT min(manufacturing_cost) FROM fact_manufacturing_cost);


--------------------------------------------------------------------------------------------------------------------------------------------------



/*6.Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage
*/


SELECT C.customer_code,
       customer,
       round(avg(pre_invoice_discount_pct)*100,2) as average_discount_percantage
FROM dim_customer AS C
INNER JOIN fact_pre_invoice_deductions AS F
ON C.customer_code = F.customer_code 
WHERE fiscal_year = 2021 AND market = 'India'
group by customer_code,customer
ORDER BY average_discount_percantage desc
LIMIT 5;



-------------------------------------------------------------------------------------------------------------------------------------------------------

/*7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount
*/


SELECT month(date) as month, 
       year(date) as year,
       sum(f.gross_price * m.sold_quantity) AS Gross_sales_Amount
FROM fact_sales_monthly AS m
INNER JOIN fact_gross_price AS f
ON f.product_code = m.product_code
INNER JOIN dim_customer AS c
ON c.customer_code = m.customer_code
WHERE customer = 'Atliq Exclusive'
GROUP BY month,year
ORDER BY year;



-----------------------------------------------------------------------------------------------------------------------------------------------------------

/*8.. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity*/


SELECT 
CASE
    WHEN month(date)  in (9,10,11) then 'qtr1' 
    WHEN month(date)  in (12,1,2) then 'qtr2' 
    WHEN month(date)  in (3,4,5) then 'qtr3' 
    WHEN month(date)  in (6,7,8) then 'qtr4' 
    END AS Quarter,
    sum(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarter
ORDER BY total_sold_quantity desc;


-----------------------------------------------------------------------------------------------------------------------------------------------------------
/*9..Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage
*/



WITH gross_sale AS(
SELECT c.channel,
       round(sum(g.gross_price * m.sold_quantity)/1000000,2) AS gross_sales_mln
FROM dim_customer AS c
JOIN fact_sales_monthly AS m
ON c.customer_code = m.customer_code
JOIN fact_gross_price AS g
ON g.product_code = m.product_code
WHERE m.fiscal_year = 2021
GROUP BY channel
ORDER BY gross_sales_mln desc)
SELECT *,
       gross_sales_mln*100/sum(gross_sales_mln ) over() as Percentage
from gross_sale;



--------------------------------------------------------------------------------------------------------------------------------------------------------------

/10.Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
product
total_sold_quantity
rank_order
*/

with total_sold as (
select p.division,s.product_code,p.product,sum(sold_quantity) as total_quantity 
from dim_product p join fact_sales_monthly s 
using(product_code)
where fiscal_year=2021
group by p.division,s.product_code,p.product),
rank_top as
(select *,rank()over(partition by division order by total_quantity desc) as rnk
from total_sold)
select *
from rank_top
where rnk<=3;























