-- Explore the Database

SELECT *
FROM factSale

-- Check the number of rows in fact sales table

SELECT COUNT(*)
FROM factSale


--Explore Customer Dimension
-- Returns full list of customers

SELECT *
FROM dimCustomer

-- looking at the dimcustomer table Checking the Numbes of rows in dimcustomer table

SELECT COUNT(*)
FROM dimCustomer

SELECT COUNT(*)
FROM dimCustomer as c
WHERE c.Customer <> 'unknown'

-- Exploring Number of Products
-- Returns all data from the stock item table.

SELECT *
FROM dimstockitem


-- Counts product numbers excluding those marked as unknown.

SELECT COUNT ([Stock Item Key]) AS ProductCount
FROM dimStockItem
WHERE [Stock Item] <> 'unknown'

-- Counts the number of unique colors of products

SELECT COUNT (DISTINCT Color ) As colorcount
FROM dimStockItem
WHERE Color <> 'N/A'


-- Exploring Cheapest Product
-- Find the lowest price of any product.

SELECT MIN ([Unit Price]) 
FROM dimStockItem 
WHERE [Stock Item Key] <> 0

-- Return all products and their prices.

SELECT [Stock Item] AS ProductName, [Unit Price]
FROM dimStockItem
WHERE [Stock Item] <> 'unknown'

-- Return the name and price of the lowest priced product.

SELECT [Stock Item] AS ProductName, [Unit Price]
FROM dimStockItem
WHERE [Unit Price] = (SELECT MIN ([Unit Price]) 
            FROM dimStockItem WHERE [Stock Item Key] <> 0)


--Return cheapest products that exclude the words box, bag or carton.

SELECT [Stock Item] AS ProductName, [Unit Price]
FROM dimStockItem
WHERE [Stock Item Key] <> 0
    AND [Stock Item] NOT LIKE '%bag%'
    AND [Stock Item] NOT LIKE '%box%'
    AND [Stock Item] NOT LIKE '%cartom%'
ORDER BY [Unit Price] ASC

 -- Black Products Containing Mug or Shirt
-- Returns all mug or shirt products that are black.

SELECT
 [Stock Item] AS ProductName, [Unit Price]
FROM dimStockItem
WHERE [Stock Item] LIKE '%mug%' OR [Stock Item] LIKE '%shirt%'
   AND Color = 'black'


-- Returns count of all mug or shirt products that are black.

SELECT COUNT([WWI Stock Item ID])
FROM dimStockItem
WHERE [Stock Item] LIKE '%mug%' OR [Stock Item] LIKE '%shirt%'
   AND Color = 'black'


-- Returns list of products that meet these conditions in ascending order

SELECT 
 [WWI Stock Item ID], [Stock Item] AS ProductName, [Unit Price]
FROM dimStockItem
WHERE [Stock Item] LIKE '%mug%' OR [Stock Item] LIKE '%shirt%'
   AND Color = 'black'
ORDER BY [Unit Price] ASC

-- Mark Up
-- Return the markup of item with WWI Stock item ID 29 

SELECT
    [Stock Item],
    [Unit Price],
    [Recommended Retail Price],
    ([Recommended Retail Price] -[Unit Price]) / [Unit Price] AS PctMarkup
FROM dimStockItem
WHERE [WWI Stock Item ID] = 29

-- As above, but rounded to four decimal places.

SELECT
    [Stock Item],
    [Unit Price],
    [Recommended Retail Price],
    CAST(([Recommended Retail Price] -[Unit Price]) / [Unit Price] AS decimal (8,4)) AS PctMarkup
FROM dimStockItem
WHERE [WWI Stock Item ID] = 29


-- Customers by Buying Group
--Returns the count of customers in each buying group.

SELECT
[Buying Group],
COUNT ([Customer Key]) AS CustomerCount
FROM dimCustomer
GROUP BY [Buying Group]
ORDER BY CustomerCount ASC


--Returns a list of postcodes with more than 3 Wingtip Toy shops.

SELECT
    [Postal Code]
FROM dimCustomer
WHERE [Buying Group] = 'wingtip toys'
GROUP BY [Postal Code]
HAVING COUNT([Customer Key]) >3


-- List Customers in Same Postal Code
-- Returns list of customers in post codes that have more than three Wingtip Customer shops.

SELECT
    [Postal Code], Customer
FROM dimCustomer
WHERE [Postal Code] IN (SELECT
                    [Postal Code]
                FROM dimCustomer
                WHERE [Buying Group] = 'wingtip toys'
                GROUP BY [Postal Code]
                HAVING COUNT([Customer Key]) >3)


-- As above, but filteering the list to return only WingTip shops.

SELECT
    [Postal Code], Customer
FROM dimCustomer
WHERE [Buying Group] = 'wingtip toys' 
AND [Postal Code] IN (SELECT
                    [Postal Code]
                FROM dimCustomer
                WHERE [Buying Group] = 'wingtip toys'
                GROUP BY [Postal Code]
                HAVING COUNT([Customer Key]) >3)


-- Employee Dimension Queries
-- Returns the % of employees working in sales

SELECT
CAST( COUNT (Employee) AS decimal (8, 2)) /
    (SELECT COUNT(Employee) AS EmployeeCnt
        FROM dimEmployee
        WHERE Employee <> 'unknown') AS SalesPeoplePctOfTotal
        
FROM dimEmployee
WHERE Employee <> 'unknown'
AND [Is Salesperson] = 1

--As above, but returned to two decimal places.

SELECT
CAST(CAST( COUNT (Employee) AS decimal (8, 2)) /
    (SELECT COUNT(Employee) AS EmployeeCnt
        FROM dimEmployee
        WHERE Employee <> 'unknown') AS decimal (8,2)) AS SalesPeoplePctOfTotal
        
FROM dimEmployee
WHERE Employee <> 'unknown'
AND [Is Salesperson] = 1


-- City Dimension Queries
-- Returns total population, count of cities, max city population 
-- for each sales territory. Also adds a total row.

SELECT 
   [Sales Territory], 
    SUM([Latest Recorded Population]) AS TotalPopulation,
    COUNT([WWI City ID]) AS NumberOfCities,
    MAX([Latest Recorded Population]) AS BiggestCityPopulation
FROM dimCity
WHERE City <> 'unknown'
GROUP BY ROLLUP ([Sales Territory])
ORDER BY TotalPopulation DESC


--As above, and tidies up the presentation of the total row.

SELECT 
   ISNULL([Sales Territory], 'Total') AS SalesTerritory, 
    SUM([Latest Recorded Population]) AS TotalPopulation,
    COUNT([WWI City ID]) AS NumberOfCities,
    MAX([Latest Recorded Population]) AS BiggestCityPopulation
FROM dimCity
WHERE City <> 'unknown'
GROUP BY ROLLUP ([Sales Territory])
ORDER BY TotalPopulation DESC


/*
Investigating Sales Over Time

Granularity Fact Sales
 Returns all sales where multiple rows appear per invoice.
Used to illustrate that the grain of the fact table is not simply one row per invoice, but one row per product invoice.
*/

SELECT *
FROM factSale
WHERE [WWI Invoice ID] IN (SELECT [WWI Invoice ID] FROM factSale
    GROUP BY [WWI Invoice ID] HAVING COUNT ([WWI Invoice ID]) > 1)
ORDER BY [WWI Invoice ID]


-- Fiscal Years in Dataset
-- Show max fiscal year in the date dimension.

SELECT MAX([Fiscal Year]) as MaxFiscalYear
FROM dimDate


-- Calculate Total Sales Excluding tax for each fiscal year.

SELECT 
    d.[Fiscal Year] AS FiscalYear,
    SUM(s.[Total Excluding Tax]) AS TotalSalesExcludingTax

FROM factSale AS s
    INNER JOIN dimDate AS d 
    ON s.[Invoice Date Key] = d.[Date]

GROUP BY d.[Fiscal Year]
ORDER BY d.[Fiscal Year] ASC


/*

Sales By Fiscal Period

Sales by Fiscal Year
Show sales and other metrics aggregated by fiscal year
*/

SELECT 
    d.[Fiscal Year] AS FiscalYear,
    SUM(s.[Total Excluding Tax]) AS TotalSalesExcludingTax,
    SUM(s.Quantity) AS QuantitySold,
    SUM(s.Profit) AS Profit

FROM factSale AS s
    INNER JOIN dimDate AS d 
    ON s.[Invoice Date Key] = d.[Date]

GROUP BY d.[Fiscal Year]
ORDER BY d.[Fiscal Year] DESC

-- Show sales and other metrics aggregated by fiscal year, and formatted nicely.

SELECT 
    d.[Fiscal Year] AS FiscalYear,
    FORMAT(SUM(s.[Total Excluding Tax]), 'C') AS TotalSalesExcludingTax,
    FORMAT(SUM(s.Quantity), 'N') AS QuantitySold,
    FORMAT(SUM(s.Profit), 'C') AS Profit

FROM factSale AS s
    INNER JOIN dimDate AS d 
    ON s.[Invoice Date Key] = d.[Date]

GROUP BY d.[Fiscal Year]
ORDER BY d.[Fiscal Year] DESC


-- Sales by Fiscal Month
-- Sales ordered by month and year.

SELECT 
    d.[Fiscal Month Label] AS FisicalMonth ,
    d.[Fiscal Year] AS FiscalYear,
    d.[Fiscal Month Number] AS FiscalMonthNumber ,
    FORMAT(SUM(s.[Total Excluding Tax]), 'C') AS TotalSalesExcludingTax,
    FORMAT(SUM(s.Quantity), 'N') AS QuantitySold,
    FORMAT(SUM(s.Profit), 'C') AS Profit

FROM factSale AS s
    INNER JOIN dimDate AS d 
    ON s.[Invoice Date Key] = d.[Date]

GROUP BY d.[Fiscal Year], 
    d.[Fiscal Month Label], 
    d.[Fiscal Month Number]

ORDER BY d.[Fiscal Year] DESC, [Fiscal Month Number] DESC



/*
 Top Selling Products

Total Sales in 2016
Shows the Total Sales in 2016 
*/

SELECT SUM (s.[Total Excluding Tax])
FROM factSale AS s
    INNER JOIN dimDate AS d
    ON s.[Invoice Date Key] = d.[Date]

WHERE d.[Fiscal Year] = 2016


-- Top 10 Selling Products in YTD 2016

SELECT
    TOP 10 p.[Stock Item] AS Product,
    SUM (s.[Total Excluding Tax]) AS YTDTotalSalesExcludingTax
     
FROM factSale AS s
    INNER JOIN dimStockItem AS p
    ON s.[Stock Item Key] =  p.[Stock Item Key]
    INNER JOIN dimDate AS d
    ON s.[Invoice Date Key] = d.[Date]

WHERE d.[Fiscal Year] = 2016
GROUP BY p.[Stock Item]
ORDER BY YTDTotalSalesExcludingTax DESC


-- Sales by Salesperson and Product
-- Ordered sales by employee and product in 2016.

SELECT
    e.Employee AS SalesPerson,
    p.[Stock Item] AS Product,
    SUM (s.[Total Excluding Tax]) AS YTDTotalSalesExcludingTax
     
FROM factSale AS s
    INNER JOIN dimStockItem AS p
    ON s.[Stock Item Key] =  p.[Stock Item Key]
    INNER JOIN dimDate AS d
    ON s.[Invoice Date Key] = d.[Date]
    INNER JOIN dimEmployee AS e
    ON s.[Salesperson Key] = e.[Employee Key]

WHERE d.[Fiscal Year] = 2016
GROUP BY p.[Stock Item], e.Employee
ORDER BY YTDTotalSalesExcludingTax DESC


-- Sales by Salesperson and Product Percent of Total by Sales Person.
-- Ordered sales by employee and product in 2016. 
-- Including % of total.


SELECT TOP 10
    e.Employee AS SalesPerson,
    p.[Stock Item] AS Product,
    SUM (s.[Total Excluding Tax]) AS YTDTotalSalesExcludingTax,
    FORMAT(CAST( SUM (s.[Total Excluding Tax]) / ( SELECT SUM(s.[Total Excluding Tax])
                                        FROM   factSale AS s
                                        INNER JOIN dimDate AS d
                                        ON s.[Invoice Date Key] = d.[Date]
                                        WHERE d.[Fiscal Year] = 2016)
                                AS decimal (8,6)), 'P4') AS PercentOfSalesYTD

     
FROM factSale AS s
    INNER JOIN dimStockItem AS p
    ON s.[Stock Item Key] =  p.[Stock Item Key]
    INNER JOIN dimDate AS d
    ON s.[Invoice Date Key] = d.[Date]
    INNER JOIN dimEmployee AS e
    ON s.[Salesperson Key] = e.[Employee Key]

WHERE d.[Fiscal Year] = 2016
GROUP BY p.[Stock Item], e.Employee
ORDER BY YTDTotalSalesExcludingTax DESC


/* 
Sales by Salesperson and Product Percent of Total (Using Subquery)

Ordered sales by employee and product in 2016. 
Including % of total.

Including a dynamic subquery to filter results by the most recent fiscal year.
*/

SELECT TOP 10
    e.Employee AS SalesPerson,
    p.[Stock Item] AS Product,
    SUM (s.[Total Excluding Tax]) AS YTDTotalSalesExcludingTax,
    FORMAT(CAST( SUM (s.[Total Excluding Tax]) / ( SELECT SUM(s.[Total Excluding Tax])
                            FROM   factSale AS s
                            INNER JOIN dimDate AS d
                            ON s.[Invoice Date Key] = d.[Date]
                            WHERE d.[Fiscal Year] = (SELECT MAX ([Fiscal Year]) 
                            FROM factSale AS s INNER JOIN dimDate AS d 
                            ON s.[Invoice Date Key] = d.[Date]))
            AS decimal (8,6)), 'P4') AS PercentOfSalesYTD

FROM factSale AS s
    INNER JOIN dimStockItem AS p
    ON s.[Stock Item Key] =  p.[Stock Item Key]
    INNER JOIN dimDate AS d
    ON s.[Invoice Date Key] = d.[Date]
    INNER JOIN dimEmployee AS e
    ON s.[Salesperson Key] = e.[Employee Key]

WHERE d.[Fiscal Year] = (SELECT MAX ([Fiscal Year]) 
                            FROM factSale AS s INNER JOIN dimDate AS d 
                            ON s.[Invoice Date Key] = d.[Date])
GROUP BY p.[Stock Item], e.Employee
ORDER BY YTDTotalSalesExcludingTax DESC


/*
Top Selling Chiller Products
Zero Sales to Date
Shows quantity sold by stock item, only for chiller stock items.
*/

SELECT
    p.[Stock Item],
    SUM(Quantity) AS QuantitySold
FROM factSale AS s
        RIGHT JOIN dimStockItem p
        ON s.[Stock Item Key] = p.[Stock Item Key]
WHERE p.[Is Chiller Stock] = 1
GROUP BY ROLLUP (p.[Stock Item])
ORDER BY QuantitySold DESC










