-- Creating Monthly Sales/Revenue Table
CREATE TABLE Revenue AS (
SELECT OrderDate,
YEAR(OrderDate) AS YEAR,
MONTH(OrderDate) AS MONTH,
SUM(od.UnitPrice*od.Quantity) AS Revenue
FROM orders o
LEFT JOIN northwind.`order details` od
USING (OrderID)
GROUP BY YEAR(OrderDate), MONTH(OrderDate) 
ORDER BY YEAR(OrderDate), MONTH(OrderDate) )

#Yearly Revenue
SELECT  EXTRACT(YEAR FROM OrderDate) AS year,
        SUM(Revenue) AS TotalRevenue
FROM revenue
GROUP BY EXTRACT(YEAR FROM OrderDate);

#Monthly Revenue
SELECT  EXTRACT(YEAR FROM OrderDate) AS year,
        EXTRACT(MONTH FROM OrderDate) AS month,
        SUM(Revenue) AS TotalRevenue
FROM revenue
GROUP BY EXTRACT(YEAR FROM OrderDate), EXTRACT(MONTH FROM OrderDate)
ORDER BY EXTRACT(YEAR FROM OrderDate) ASC, EXTRACT(MONTH FROM OrderDate);

#Quarterly Revenue
SELECT  EXTRACT(YEAR FROM OrderDate) AS year,
        EXTRACT(QUARTER FROM OrderDate) AS quarter,
        SUM(Revenue) AS TotalRevenue
FROM revenue
GROUP BY EXTRACT(YEAR FROM OrderDate), EXTRACT(QUARTER FROM OrderDate)
ORDER BY EXTRACT(YEAR FROM OrderDate) ASC, EXTRACT(QUARTER FROM OrderDate);
 
#Revenue Growth
SELECT  DATE(OrderDate),
        Revenue,
        Revenue - LAG (Revenue,1) OVER (ORDER BY Year ASC) AS revenue_growth,
        LEAD (Revenue, 12) OVER (ORDER BY Year ASC) AS next_year_revenue,
        (Revenue - LAG (Revenue) OVER (ORDER BY Year ASC))/LAG (Revenue) OVER (ORDER BY Year ASC)*100 AS revenue_percentage_growth
FROM revenue

#Sales by Category 
SELECT c.CategoryID, c.CategoryName, date_format(OrderDate,'%Y') AS YEAR,date_format(OrderDate,'%M') AS MONTH,SUM(od.UnitPrice*od.Quantity) AS TotalSales
FROM orders o
LEFT JOIN northwind.`order details` od
USING (OrderID)
LEFT JOIN products p
USING (ProductID)
LEFT JOIN categories c
USING (CategoryID)
GROUP BY c.CategoryID, c.CategoryName, YEAR(OrderDate),MONTH(OrderDate)
ORDER BY c.CategoryID, c.CategoryName,YEAR(OrderDate),MONTH(OrderDate)

#Total Sales for each product
SELECT p.ProductID,  p.ProductName, SUM(od.UnitPrice*od.Quantity) AS TotalSales
FROM orders o
LEFT JOIN northwind.`order details` od
USING (OrderID)
LEFT JOIN products p
USING (ProductID)
GROUP BY p.ProductID, p.ProductName

#FAIZA
#EMPLOYEE'S PERFORMANCE IN 1997
WITH topsales AS (
    SELECT 
        o.EmployeeID ,
        SUM(quantity * UnitPrice)  AS sales
FROM orders o
LEFT JOIN northwind.`order details` od
USING (OrderID)
LEFT JOIN customers c
USING (CustomerID)
WHERE
YEAR(shippedDate) = 1997 AND o.ShippedDate IS NOT NULL 
GROUP BY EmployeeID
ORDER BY sales DESC
)
SELECT 
EmployeeID, 
CONCAT(FirstName,' ', LastName) AS EmployeeName,
sales,
DENSE_RANK() OVER (ORDER BY sales DESC) AS EmployeePerformanceRank
FROM employees
JOIN topsales USING (EmployeeID);

#Top 3 employees in last 3 months of 1997
WITH topsales AS (
    SELECT 
        o.EmployeeID , 
        SUM(quantity * UnitPrice)  AS sales
FROM orders o
LEFT JOIN northwind.`order details` od
USING (OrderID)
LEFT JOIN customers c
USING (CustomerID)
WHERE
YEAR(OrderDate) = 1997 AND (MONTH(OrderDate) BETWEEN 10 AND 12 ) AND o.ShippedDate IS NOT NULL 
GROUP BY EmployeeID
ORDER BY sales DESC
)
SELECT 
EmployeeID, 
CONCAT(FirstName,' ', LastName) AS EmployeeName,
sales,
DENSE_RANK() OVER (ORDER BY sales DESC) AS EmployeePerformanceRank
FROM employees
JOIN topsales USING (EmployeeID)
LIMIT 3;

#TOP 3 Categories 
WITH topcat AS (
SELECT c.CategoryName, SUM(od.UnitPrice*od.Quantity) AS TotalSales
FROM orders o
LEFT JOIN northwind.`order details` od
USING (OrderID)
LEFT JOIN products p
USING (ProductID)
LEFT JOIN categories c
USING (CategoryID)
GROUP BY c.CategoryName
ORDER BY TotalSales DESC)
SELECT 
CategoryName, 
TotalSales,
DENSE_RANK() OVER (ORDER BY TotalSales DESC) AS CategoryRank
FROM topcat #Categories c
LIMIT 3

#TOP 3 Products in each category
WITH sales AS (
SELECT c.CategoryName, p.ProductName, od.UnitPrice*od.Quantity AS Sales
FROM orders o
LEFT JOIN northwind.`order details` od
USING (OrderID)
LEFT JOIN products p
USING (ProductID)
LEFT JOIN categories c
USING (CategoryID)
),
ProductRank AS(
SELECT 
CategoryName,
ProductName, 
SUM(Sales),
DENSE_RANK() OVER (PARTITION BY CategoryName ORDER BY SUM(Sales) DESC) AS ProductRank
FROM sales
GROUP BY CategoryName,ProductName)
SELECT * FROM ProductRank
WHERE ProductRank <= 3

#TOP REVENUE GENERATING PRODUCTS
WITH topsales AS (
SELECT p.ProductID,  p.ProductName, SUM(od.UnitPrice*od.Quantity) AS TotalSales
FROM orders o
LEFT JOIN northwind.`order details` od
USING (OrderID)
LEFT JOIN products p
USING (ProductID)
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalSales DESC
)
SELECT 
tp.ProductID,
tp.ProductName, 
tp.TotalSales,
DENSE_RANK() OVER (ORDER BY TotalSales DESC) AS ProductRank
FROM products p
JOIN topsales tp
USING (ProductID)
LIMIT 5

#MARWA
-- MAC  
select year(orderdate), monthname(orderdate), count(distinct customerid)
from orders group by year(orderdate), month(orderdate);

-- Retained Customers
WITH order_rank AS (
SELECT 
CustomerID,
OrderID,
OrderDate,
RANK() OVER (PARTITION BY CustomerID ORDER BY OrderID ASC ) as rank_of_orders
FROM orders),
monthly_customers AS (   
SELECT*,  monthname(OrderDate), year(OrderDate), count(distinct CustomerID) AS total_customers,
SUM(CASE WHEN rank_of_orders = 1 THEN 1 ELSE 0 END) AS NewCustomers
FROM order_rank 
GROUP BY month(OrderDate),year(OrderDate)),
previouscustomer as (
select *,
LAG(total_customers, 1) OVER (ORDER BY year(OrderDate), monthname(OrderDate)) AS prev_months_total_customer
FROM monthly_customers
)
SELECT year(OrderDate), monthname(OrderDate),
(total_customers-NewCustomers)*100/prev_months_total_customer AS retentionrate
FROM previouscustomer;

#IZZA
#Monthly ARPC
WITH DistinctCustomer AS(
SELECT date_format(OrderDate,'%Y') AS YEAR,
date_format(OrderDate,'%M') AS MONTH, 
SUM(od.UnitPrice*od.Quantity) AS revenue,
COUNT(DISTINCT CUSTOMERID) AS d_customer
FROM orders o
LEFT JOIN northwind.`order details` od
USING (OrderID)
LEFT JOIN CUSTOMERS C
USING (CUSTOMERID)
group by year(orderdate), month(orderdate)
)
SELECT YEAR, MONTH, revenue/d_customer AS ARPC,d_customer
FROM DistinctCustomer;


#retention,churn,average customer lifetime in years 
WITH order_rank AS (
SELECT 
CustomerID,
OrderID,
OrderDate,
RANK() OVER (PARTITION BY CustomerID ORDER BY OrderID ASC ) as rank_of_orders
FROM orders),
monthly_customers AS (   
SELECT*,  month(OrderDate), year(OrderDate), count(distinct CustomerID) AS total_customers,
SUM(CASE WHEN rank_of_orders = 1 THEN 1 ELSE 0 END) AS NewCustomers
FROM order_rank 
GROUP BY month(OrderDate),year(OrderDate)),
previouscustomer as (
select *,
LAG(total_customers, 1) OVER (ORDER BY  year(OrderDate), month(OrderDate)) AS prev_months_total_customer
FROM monthly_customers
)
SELECT monthname(OrderDate),year(OrderDate), 
total_customers-NewCustomers AS retainedCustomers,
(total_customers-NewCustomers)*100/prev_months_total_customer AS retentionrate,
100- ((total_customers-NewCustomers)*100/prev_months_total_customer ) AS churnrate,
1/(100- ((total_customers-NewCustomers)*100/prev_months_total_customer)) AS Avg_Cust_Lifetime_yr
FROM previouscustomer



