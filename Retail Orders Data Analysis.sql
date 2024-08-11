USE retail_orders;

-- Creating the table to load the data extracted and cleaned in Python
CREATE TABLE orders
(
order_id INT PRIMARY KEY,
order_date DATE,
ship_mode VARCHAR(20),
segment  VARCHAR(20),
country  VARCHAR(20),
city  VARCHAR(20),
state  VARCHAR(20),
postal_code  VARCHAR(20),
region  VARCHAR(20),
category  VARCHAR(20),
sub_category  VARCHAR(20),
product_id  VARCHAR(50),
quantity  INT,
discount  DECIMAL(7,2),
sale_price  DECIMAL(7,2),
profit  DECIMAL(7,2)

);

SELECT * FROM orders;

-- Conducting Data Analysis:

-- finding the top 10 highest revenue generating prooducts:
SELECT product_id, SUM(sale_price) AS Total_Revenue
FROM orders
GROUP BY product_id
ORDER BY Total_Revenue DESC
LIMIT 10;

-- finding the top 5 highest revenue generating products in each region
WITH Rev_by_Prod_in_each_Region AS(
SELECT region, product_id, SUM(sale_price*quantity) AS Total_Revenue,
RANK() OVER (PARTITION BY region ORDER BY SUM(sale_price) DESC) AS Rev_Rank
FROM orders
GROUP BY region, product_id
ORDER BY region, Total_Revenue DESC)
SELECT region, product_id, Total_Revenue
FROM Rev_by_Prod_in_each_Region 
WHERE Rev_RANK BETWEEN 1 AND 5;

-- Month over Month(MOM) growth comparison in sales between 2022 and 2023:
WITH Monthly_Revenue AS(
SELECT YEAR(order_date) AS Order_Year ,
MONTH(order_date) as Month_No,MONTHNAME(order_date) AS Order_Month, 
SUM(sale_price*quantity) as Total_Revenue
FROM orders
GROUP BY Month_No, Order_Year, Order_Month)
, MOM_Revenue AS(SELECT  Month_No, Order_Month,
SUM(CASE WHEN Order_Year = 2022 THEN Total_Revenue ELSE 0 END) AS Revenue_2022,
SUM(CASE WHEN Order_Year = 2023 THEN Total_Revenue ELSE 0 END) AS Revenue_2023
FROM Monthly_Revenue
GROUP BY Month_No, Order_Month
ORDER BY Month_No)
SELECT Order_Month, Revenue_2022, Revenue_2023,
ROUND(((Revenue_2023-Revenue_2022)*100/Revenue_2022),2) AS Percentage_Change
FROM MOM_Revenue;

-- Finding the month with highest sales for each category:
WITH CTE AS
(SELECT category, DATE_FORMAT(order_date, '%Y-%m') AS Order_Year_Month, 
SUM(sale_price*quantity) AS Total_Revenue
FROM orders
GROUP BY category, Order_Year_Month
ORDER BY category, Order_Year_Month)
, A AS(SELECT category, Order_Year_Month, Total_Revenue,
ROW_NUMBER() OVER (PARTITION BY category ORDER BY Total_Revenue DESC) AS Revenue_Rank
FROM CTE
GROUP BY category, Order_Year_Month)
SELECT category, Order_Year_Month AS Month_with_Highest_Revenue, Total_Revenue 
FROM A WHERE Revenue_Rank=1
;

-- Finding the subcategory which saw the highest growth by profit in 2023 as compared to 2022:
WITH Monthly_Revenue AS(
SELECT sub_category,YEAR(order_date) AS Order_Year ,
SUM(profit*quantity) as Total_Profit
FROM orders
GROUP BY sub_category, Order_Year)
, Profit_by_Sub_Cat AS(SELECT sub_category,
SUM(CASE WHEN Order_Year = 2022 THEN Total_Profit ELSE 0 END) AS Profit_2022,
SUM(CASE WHEN Order_Year = 2023 THEN Total_Profit ELSE 0 END) AS Profit_2023
FROM Monthly_Revenue
GROUP BY sub_category
ORDER BY sub_category)
SELECT sub_category, Profit_2022, Profit_2023,
ROUND(((Profit_2023-Profit_2022)*100/Profit_2022),2) AS Percentage_Change_Profit
FROM Profit_by_Sub_Cat
ORDER BY Percentage_Change_Profit DESC
LIMIT 1
;

-- Finding the cities driving the most revenue
WITH CTE AS(
SELECT city, 
SUM(CASE WHEN YEAR(order_date)=2022 THEN sale_price*quantity ELSE 0 END) AS Revenue_2022,
SUM(CASE WHEN YEAR(order_date)=2023 THEN sale_price*quantity ELSE 0 END) AS Revenue_2023
FROM orders
GROUP BY city
ORDER BY Revenue_2022 DESC, Revenue_2023 DESC
LIMIT 10)
SELECT *, 
ROUND(((Revenue_2023-Revenue_2022)*100/ Revenue_2022),2) AS Perc_Change
FROM CTE


