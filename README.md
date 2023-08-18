# Customers-and-Products-Analysis-Using-SQL
It is important that a Product company extract key performance indicators (KPIs) to make smarter decisions. This saves time, resources, and money. In this project, I analyzed data from a sales record database for scale model cars and extracted information for decision-making.
A good analysis always starts with the right questions, Through this project, I want to answer the following questions
* Which products should we order more of or less of?
* How should we tailor marketing and communication strategies to customer behaviors?
* How much can we spend on acquiring new customers?
## Exploreing the Data Base
I used scale model cars data base and it contains 8 tables in total:
* Customers: customer data like Customer id( or serial number), Name, contact information along with Sales employee number is available.
* Employees: all the information regarding the employee is provided along with their employee id, office code, reporting manager, etc
* Offices: sales office information is available. All the offices have thier own unique code.
* Orders: customers' sales orders details like order number, customer number, dates are present
* OrderDetails: sales order line for each sales order, it contains the order number, the product code along with quantity column
* Payments: customers' payment details are recorded
* Products: a list of scale model cars, this is the complete list of product along with availabe quantity, prodcut description, price, etc.
* ProductLines: a list of product line categories along with their description.

Using the below code, a table is generated such that each table name is taken as a sting, and its number of columns and rows are counted.

```
SELECT 'customers' AS TableName, (SELECT COUNT(*) FROM pragma_table_info('customers')) AS NumColumns, COUNT(*) AS NumRows FROM customers
UNION ALL
SELECT 'employees' AS TableName, (SELECT COUNT(*) FROM pragma_table_info('employees')) AS NumColumns, COUNT(*) AS NumRows FROM employees
UNION ALL
SELECT 'offices' AS TableName, (SELECT COUNT(*) FROM pragma_table_info('offices')) AS NumColumns, COUNT(*) AS NumRows FROM offices
UNION ALL
SELECT 'orderdetails' AS TableName, (SELECT COUNT(*) FROM pragma_table_info('orderdetails')) AS NumColumns, COUNT(*) AS NumRows FROM orderdetails
UNION ALL
SELECT 'orders' AS TableName, (SELECT COUNT(*) FROM pragma_table_info('orders')) AS NumColumns, COUNT(*) AS NumRows FROM orders
UNION ALL
SELECT 'payments' AS TableName, (SELECT COUNT(*) FROM pragma_table_info('payments')) AS NumColumns, COUNT(*) AS NumRows FROM payments
UNION ALL
SELECT 'productlines' AS TableName, (SELECT COUNT(*) FROM pragma_table_info('productlines')) AS NumColumns, COUNT(*) AS NumRows FROM productlines
UNION ALL
SELECT 'products' AS TableName, (SELECT COUNT(*) FROM pragma_table_info('products')) AS NumColumns, COUNT(*) AS NumRows FROM products;
```
Thereby, I got a basic idea of the data:


![Alt text](table_columns_rows.png)
## Question 1: Which Products Should We Order More of or Less of?
The decision is to be made based on a product's demand, the revenue it generates, and the quantity available with us.
So I used two parameters that considers the above three paramaters into consideration:
* $lowStock = \frac{SUM(quantityOrdered)}{quantityInStock}$
* $productPerformance = SUM(quantityOrdered \cdot priceEach)$

To apply the above formula and thereby obtain the required priority Product, the following code is written:
```
WITH lowStockProducts AS(
	SELECT p.productCode, 
       CAST(od.quantityOrdered * 1.0 / p.quantityInStock AS DECIMAL(10, 2)) AS lowStock
	FROM products AS p
	JOIN (
		SELECT productCode, SUM(quantityOrdered) AS quantityOrdered
		FROM orderdetails
		GROUP BY productCode
	) AS od ON p.productCode = od.productCode
	GROUP BY p.productCode
	ORDER BY lowStock DESC
),
TopProducts AS(
	SELECT od.productCode,
			(quantityOrdered * priceEach) AS productPerformance
	FROM orderdetails od
	GROUP BY od.productCode
)
SELECT lsp.productCode, lsp.lowStock, tp.productPerformance
FROM LowStockProducts lsp
JOIN TopProducts tp ON lsp.productCode = tp.productCode
WHERE lsp.productCode IN (SELECT productCode FROM LowStockProducts)
ORDER BY lsp.lowStock DESC;
```
## Question 2: How Should We Match Marketing and Communication Strategies to Customer Behavior?
To answer this question I need to explore the customer information. One idea is to divide the most engaged customers - VIP who bring highr profit to the company from the less engaged customers. So as per the division we may organize some events to drive loyalty for the VIPs and launch a campaign for the less engaged.
On exploring the data we know every customer have an unique customerNumber, and he can place various orders with different orderNumbers.
Note: under one orderNumber there may be many unique products
So thereby the profit made by a customer can be calculated as follows:
* $profit = SUM(quantityOrdered * (priceEach - buyPrice))$
