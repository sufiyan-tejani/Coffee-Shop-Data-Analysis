CREATE DATABASE coffee_shop_sales_db;
SELECT * FROM coffee_shop_sales;
DESCRIBE coffee_shop_sales;
#Data Cleaning:

UPDATE coffee_shop_sales SET transaction_date=STR_TO_DATE(transaction_date,'%d-%m-%Y');   #converting it to dd-mm-yyyy format as some might be in not that form
SET SQL_SAFE_UPDATES=0;

ALTER TABLE coffee_shop_sales MODIFY COLUMN transaction_date DATE;   #we are changing this table text datatype to date datatype

DESCRIBE coffee_shop_sales;
UPDATE coffee_shop_sales SET transaction_time=STR_TO_DATE(transaction_time,'%H:%i:%s');   #converting it to H:M:S format as some might be in not that form

ALTER TABLE coffee_shop_sales MODIFY COLUMN transaction_time TIME;   #we are changing this table text datatype to time datatype
DESCRIBE coffee_shop_sales;

ALTER TABLE coffee_shop_sales CHANGE COLUMN ï»¿transaction_id transaction_id INT; 

#Buisness Requirements Queries:

#KPI's Requirements:
#1: Total Sale Analysis:
#a) Calculate the total sales for each respective month.
SELECT ROUND(SUM(unit_price*transaction_qty)) AS Total_Sales FROM coffee_shop_sales WHERE MONTH(transaction_date)=5;   -- May Month 
#We can see other months also by changing 5 to any month number

#b) Determine the month-on-month increase or decrease in sales.
SELECT 
    MONTH(transaction_date) AS month,   -- Number of Month
    ROUND(SUM(unit_price * transaction_qty)) AS total_sales,   -- Total Sales
    (SUM(unit_price * transaction_qty) - LAG(SUM(unit_price * transaction_qty), 1)  -- Month Sale Difference
    OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(unit_price * transaction_qty), 1)   -- Division by previous month sales
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage   -- Percentage
FROM coffee_shop_sales
WHERE MONTH(transaction_date) IN (4, 5) -- for months of April(Previous Month) and May(Current Month)
GROUP BY MONTH(transaction_date) ORDER BY MONTH(transaction_date);

#2: Total Orders Analysis:
#a) Calculate the total number of orders for each respective month.
SELECT COUNT(transaction_id) as Total_Orders FROM coffee_shop_sales WHERE MONTH (transaction_date)= 5 -- for month of (CM-May)

#b) Determine the month-on-month increase or decrease in the number of orders.
SELECT 
    MONTH(transaction_date) AS month,
    ROUND(COUNT(transaction_id)) AS total_orders,
    (COUNT(transaction_id) - LAG(COUNT(transaction_id), 1) 
    OVER (ORDER BY MONTH(transaction_date))) / LAG(COUNT(transaction_id), 1) 
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage
FROM coffee_shop_sales WHERE MONTH(transaction_date) IN (4, 5) -- for April and May
GROUP BY MONTH(transaction_date) ORDER BY MONTH(transaction_date);

#3: Total Quantity Sold Analysis:
#a) Calculate the total quantity sold for each respective month.
SELECT SUM(transaction_qty) as Total_Quantity_Sold FROM coffee_shop_sales WHERE MONTH(transaction_date) = 5 -- for month of (CM-May);

#b) Determine the month-on-month increase or decrease in the total quantity sold.
SELECT 
    MONTH(transaction_date) AS month,
    ROUND(SUM(transaction_qty)) AS total_quantity_sold,
    (SUM(transaction_qty) - LAG(SUM(transaction_qty), 1) 
    OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(transaction_qty), 1) 
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage
FROM coffee_shop_sales WHERE MONTH(transaction_date) IN (4, 5)   -- for April and May
GROUP BY MONTH(transaction_date) ORDER BY MONTH(transaction_date);

#CHARTS REQUIREMENTS:
#1: Calendar Heat Map:
#a) Implement tooltips to display detailed metrics (Sales, Orders, Quantity) when hovering over a specific day.
SELECT
    SUM(unit_price * transaction_qty) AS total_sales,
    SUM(transaction_qty) AS total_quantity_sold,
    COUNT(transaction_id) AS total_orders
FROM coffee_shop_sales WHERE transaction_date = '2023-05-18'; -- For 18 May 2023

#If you want to get exact Rounded off values then use below query to get the result:
SELECT 
    CONCAT(ROUND(SUM(unit_price * transaction_qty) / 1000, 1),'K') AS total_sales,
    CONCAT(ROUND(COUNT(transaction_id) / 1000, 1),'K') AS total_orders,
    CONCAT(ROUND(SUM(transaction_qty) / 1000, 1),'K') AS total_quantity_sold
FROM coffee_shop_sales WHERE transaction_date = '2023-05-18'; -- For 18 May 2023
    
#Sales Analysis by Weekdays and Weekends:
#a) Segment sales data into weekdays and weekends to analyze performance variations.
#Weekends: Sat and Sun
#Weekdays: Mon to Fri
#Sun=1, Mon=2,....,Sat=7
SELECT 
    CASE 
        WHEN DAYOFWEEK(transaction_date) IN (1, 7) THEN 'Weekends' ELSE 'Weekdays' 
	END AS day_type,
    ROUND(SUM(unit_price * transaction_qty),2) AS total_sales
FROM coffee_shop_sales WHERE MONTH(transaction_date) = 5  -- Filter for May
GROUP BY 
    CASE 
        WHEN DAYOFWEEK(transaction_date) IN (1, 7) THEN 'Weekends'
        ELSE 'Weekdays'
    END;
    
#Sales Analysis by Store Location:
#a) Visualize sales data by different store locations.
SELECT store_location, SUM(unit_price * transaction_qty) as Total_Sales
FROM coffee_shop_sales WHERE MONTH(transaction_date) =5 
GROUP BY store_location ORDER BY SUM(unit_price * transaction_qty) DESC;

# Daily Sales Analysis with Average Line:
#a) Display daily sales for the selected month. Incorporate an average line to represent the average daily sales.
#Finding Average First:
SELECT AVG(total_sales) AS average_sales
FROM (
    SELECT SUM(unit_price * transaction_qty) AS total_sales FROM coffee_shop_sales WHERE MONTH(transaction_date) = 5  -- Filter for May
    GROUP BY transaction_date) AS internal_query;

#Daily Sales for Month Selected:
SELECT DAY(transaction_date) AS day_of_month, ROUND(SUM(unit_price * transaction_qty),1) AS total_sales
FROM coffee_shop_sales WHERE MONTH(transaction_date) = 5  -- Filter for May
GROUP BY DAY(transaction_date) ORDER BY DAY(transaction_date);

#COMPARING DAILY SALES WITH AVERAGE SALES – IF GREATER THAN “ABOVE AVERAGE” and LESSER THAN “BELOW AVERAGE”:
SELECT day_of_month,
    CASE 
        WHEN total_sales > avg_sales THEN 'Above Average'
        WHEN total_sales < avg_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_status, total_sales
FROM (
    SELECT 
        DAY(transaction_date) AS day_of_month,
        SUM(unit_price * transaction_qty) AS total_sales,
        AVG(SUM(unit_price * transaction_qty)) OVER () AS avg_sales
    FROM coffee_shop_sales WHERE MONTH(transaction_date) = 5  -- Filter for May
    GROUP BY DAY(transaction_date)) AS sales_data
ORDER BY day_of_month;

#Sales Analysis by Product Category:
#a) Analyze sales performance across different product categories.
SELECT product_category, ROUND(SUM(unit_price * transaction_qty),1) as Total_Sales
FROM coffee_shop_sales WHERE MONTH(transaction_date) = 5 
GROUP BY product_category ORDER BY SUM(unit_price * transaction_qty) DESC;

#Top 10 Products by Sales:
#a) Identify and display the top 10 products based on sales volume.
SELECT product_type, ROUND(SUM(unit_price * transaction_qty),1) as Total_Sales
FROM coffee_shop_sales WHERE MONTH(transaction_date) = 5 
GROUP BY product_type ORDER BY SUM(unit_price * transaction_qty) DESC LIMIT 10;

#Sales Analysis by Days and Hours:
#a)Visualize sales patterns by days and hours.
#SALES by DAY | HOUR
SELECT ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales, SUM(transaction_qty) AS Total_Quantity, COUNT(*) AS Total_Orders
FROM coffee_shop_sales
WHERE 
    DAYOFWEEK(transaction_date) = 3 -- Filter for Tuesday (1 is Sunday, 2 is Monday, ..., 7 is Saturday)
    AND HOUR(transaction_time) = 8 -- Filter for hour number 8
    AND MONTH(transaction_date) = 5; -- Filter for May (month number 5);

#TO GET SALES FROM MONDAY TO SUNDAY FOR MONTH OF MAY:
SELECT 
    CASE 
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
        ELSE 'Sunday'
    END AS Day_of_Week,
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM coffee_shop_sales WHERE MONTH(transaction_date) = 5 -- Filter for May (month number 5)
GROUP BY 
    CASE 
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
        ELSE 'Sunday'
    END;

#TO GET SALES FOR ALL HOURS FOR MONTH OF MAY
SELECT HOUR(transaction_time) AS Hour_of_Day, ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM coffee_shop_sales WHERE MONTH(transaction_date) = 5 -- Filter for May (month number 5)
GROUP BY HOUR(transaction_time) ORDER BY HOUR(transaction_time);









