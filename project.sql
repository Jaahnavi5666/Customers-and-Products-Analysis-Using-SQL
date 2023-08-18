
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
			SUM(quantityOrdered * priceEach) AS productPerformance
	FROM orderdetails od
	GROUP BY od.productCode
)
SELECT lsp.productCode, lsp.lowStock, tp.productPerformance
FROM LowStockProducts lsp
JOIN TopProducts tp ON lsp.productCode = tp.productCode
WHERE lsp.productCode IN (SELECT productCode FROM LowStockProducts)
ORDER BY lsp.lowStock DESC;



SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber
 ORDER BY profit DESC;
 
 WITH vipCustomers AS(
	SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
	FROM products p
	JOIN orderdetails od
		ON p.productCode = od.productCode
	JOIN orders o
		ON o.orderNumber = od.orderNumber
	GROUP BY o.customerNumber
)
SELECT c.contactLastName,c.contactFirstName,c.city,c.country,v.profit
FROM vipCustomers AS v
JOIN customers c ON v.customerNumber = c.customerNumber
ORDER BY profit
LIMIT 5;

WITH payment_with_year_month_table AS (
SELECT *, 
       CAST(SUBSTR(paymentDate, 1,4) AS INTEGER)*100 + CAST(SUBSTR(paymentDate, 6,7) AS INTEGER) AS year_month
  FROM payments p
),
customers_by_month_table AS (
SELECT p1.year_month, COUNT(*) AS number_of_customers, SUM(p1.amount) AS total
  FROM payment_with_year_month_table p1
 GROUP BY p1.year_month
),
new_customers_by_month_table AS (
SELECT p1.year_month, 
       COUNT(*) AS number_of_new_customers,
       SUM(p1.amount) AS new_customer_total,
       (SELECT number_of_customers
          FROM customers_by_month_table c
        WHERE c.year_month = p1.year_month) AS number_of_customers,
       (SELECT total
          FROM customers_by_month_table c
         WHERE c.year_month = p1.year_month) AS total
  FROM payment_with_year_month_table p1
 WHERE p1.customerNumber NOT IN (SELECT customerNumber
                                   FROM payment_with_year_month_table p2
                                  WHERE p2.year_month < p1.year_month)
 GROUP BY p1.year_month
),
customer_profit_by_month AS (
    SELECT p1.year_month, 
           (SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) * 1.0) / c.number_of_customers AS avg_customer_profit
    FROM orderdetails od
    JOIN products p ON od.productCode = p.productCode
    JOIN orders o ON od.orderNumber = o.orderNumber
    JOIN payment_with_year_month_table p1 ON o.customerNumber = p1.customerNumber
    JOIN customers_by_month_table c ON p1.year_month = c.year_month
    GROUP BY p1.year_month
),
avg_ltv AS (
    SELECT AVG(cpbm.avg_customer_profit) AS avg_customer_ltv
    FROM customer_profit_by_month cpbm
)

SELECT ROUND(avg_ltv.avg_customer_ltv, 2) AS ltv
FROM avg_ltv;