
--SQL DATA ANALYSIS 

select * from Products
select * from Customers
select * from Orders
select * from OrderDetails
select * from Regions

-- Question_1 --> Identify the top 10 products by total sales revenue.
select p.productName, sum(p.Price*od.Quantity) as net_revenue from Products as p inner join Orderdetails as od
on p.ProductID = od.ProductID group by p.productName order by net_revenue desc


--Question_2 --> Find customers who haven't placed an order in the last 6 months.

SELECT c.CustomerName, o.OrderDate FROM 
Customers AS c INNER JOIN Orders AS o 
ON 
c.CustomerID = o.CustomerID WHERE MONTH(o.OrderDate) <= 6;

--or 

SELECT c.CustomerName, o.OrderDate FROM 
Customers AS c INNER JOIN Orders AS o 
ON 
c.CustomerID = o.CustomerID WHERE datepart(MM, o.OrderDate) <= 6;

--Question_3 --> Calculate the total revenue for each product category

select p.category, sum(od.quantity*p.price) 
as total_Revenue from products as p 
inner join 
orderdetails as od
on p.ProductID = od.ProductID 
group by category order by total_Revenue desc;

--Qestion_4 --> Compute the average value of an order across all customers.


select c.customerName, avg(o.TotalAmount) as avg_order_value
from customers as c 
inner join
orders as o
on c.CustomerID = o.CustomerID
group by c.CustomerName

 ---OR
SELECT 

    AVG(o.TotalAmount) AS Avg_Order_Value
FROM 
    Orders AS o;

--Question_5 --> Find all orders where a discount was applied and 
--calculate the total revenue after discounts.

with cte as (
SELECT 
    od.OrderID, 
	   p.Price, 
        od.Quantity, 
        od.Discount,
    CASE 
        WHEN od.Discount > 0 THEN od.Discount
        ELSE 0
    END AS Discount_Applied
FROM 
    OrderDetails AS od
INNER JOIN 
    Products AS p
ON 
    od.ProductID = p.ProductID
)
select orderID, Discount_Applied,
	sum(quantity*price - (quantity*price*discount)/100) as revenue_After_discount
	from cte 
GROUP BY 
    OrderID,
Discount_Applied

--or 

SELECT 
    od.OrderID, 
    CASE 
        WHEN od.Discount > 0 THEN 1 
        ELSE 0 
    END AS Discount_Applied, 
    SUM(od.Quantity * p.Price * (1 - od.Discount / 100)) AS Revenue_After_Discount
FROM 
    OrderDetails AS od
INNER JOIN 
    Products AS p
ON 
    od.ProductID = p.ProductID
GROUP BY 
    od.OrderID, 
    CASE 
        WHEN od.Discount > 0 THEN 1 
        ELSE 0 
    END;


-- Question_6 --> Determine which regions contributed the most to overall sales

select r.regionName, sum(o.totalamount) as region_sales
from orders as o inner join customers as c
on c.CustomerID = o.CustomerID 
inner join regions as r on r.Country = c.Country 
group by r.regionName order by region_sales desc;


--Question_7 --> Calculate the profit margin for each product, considering the discount applied.

-- net_profit_margin = net_profit/revenue
SELECT 
    p.ProductName, 
    --SUM(od.Quantity * p.Price) AS Total_Sales,
    --SUM(od.Quantity * p.Price * (1 - od.Discount / 100)) AS Revenue_After_Discount,
    --SUM(od.Quantity * p.Price * (od.Discount / 100)) AS Total_Discount,
    (SUM(od.Quantity * p.Price * (1 - od.Discount / 100)) / SUM(od.Quantity * p.Price)) * 100 AS Profit_Margin_Percentage
FROM 
    Products AS p
INNER JOIN 
    OrderDetails AS od 
ON 
    p.ProductID = od.ProductID
GROUP BY 
    p.ProductName
ORDER BY 
    Profit_Margin_Percentage DESC;


--Question_8 -- > Categorize customers based on their total spending
--(e.g., High-Spending, Medium-Spending, Low-Spending).

select c.customerName, sum(p.price*od.quantity) as total_spending,
case 
	 when sum(p.price*od.quantity) > 800 then 'high_spending'
	 when sum(p.price*od.quantity) > 400 and sum(p.price*od.quantity) <= 800 then 'medium_spending'
	 else 'low_spending' 
end as spending_category
from products as p 
inner join orderdetails as od on p.productID = od.ProductID 
inner join orders as o on o.orderID = od.OrderID 
inner join customers as c on c.customerID = o.CustomerID group by 
c.customerName order by total_spending desc


--Question_9 --> Analyze the sales trends on a quarterly basis for each product category.

select  datepart(year, o.orderdate) as year,
datepart(quarter, o.orderdate) as quarters, p.category,
sum(p.price*od.quantity) as total_sales
from orders as o 
inner join orderdetails as od on o.orderID = od.orderID
inner join products as p on p.productID = od.productID
group by category, datepart(year, o.orderdate), datepart(quarter, o.orderdate)
order by quarters;


--Question_10 --> Identify products frequently purchased together by analyzing OrderDetails.

select od1.productId as P_A,
od2.productID as P_B,
count(*) as frequency
from OrderDetails as od1
inner join OrderDetails as od2
on od1.OrderID = od2.OrderID
and od1.ProductID <> od2.ProductID
group by od1.productId,
od2.productID order by frequency


--Question_11 --> Identify customers who have decreased their spending by 
--more than 50% compared to the previous year.

with cte as (
select c.customerID, c.customername, year(o.orderdate) as order_year, sum(o.totalamount) as total_spending
from customers as c inner join orders as o
on c.customerID = o.customerID
group by c.customerID, c.customername, year(o.orderdate)
)
select x.customername, x.order_year as current_year, x.total_spending as current_spending,
y.order_year as previous_year, y.total_spending as previous_spending
from cte as x join cte as y
on x.customerID = y.customerID
and x.order_year = y.order_year + 1
where x.total_spending < (y.total_spending*0.5)
order by x.customername, x.order_year


--Question_12 --> Predict the next month's sales using historical data (requires aggregating monthly sales).

with monthly_sale as(
select YEAR(orderdate) as order_year,
month(orderdate) as order_month,
sum(totalamount) as total_sales
from orders 
group by YEAR(orderdate),
month(orderdate)
)
, predicted_sales as (
select order_year, order_month, total_sales,
avg(total_sales) over(order by order_year, order_month rows between 5 preceding and current row) 
as predicted_next_month
from monthly_sale
)
select order_year, order_month + 1 as predicted_month,
predicted_next_month as predicted_sales
from predicted_sales order by order_year desc, order_month desc



