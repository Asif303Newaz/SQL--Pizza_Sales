/* Retrieve the total number of orders placed */

select count(order_id) as total_orders from orders;

/* Calculate the total revenue generated from pizza sales.*/

select round(sum(order_details.QUANTITY * pizzas.price),2) as Total_sales
from order_details join pizzas
on order_details.PIZZA_ID = pizzas.pizza_id;


/*Identify the highest-priced pizza.*/

select pizza_types.name, pizzas.price
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
order by pizzas.price desc limit 1;

/*Identify the most common pizza size ordered.*/

select pizzas.size, count(order_details.ORDER_DETAILS_ID) as order_count
from order_details join pizzas
on order_details.PIZZA_ID = pizzas.pizza_id
group by pizzas.size order by order_count desc;

/*List the top 5 most ordered pizza types along with their quantities.*/

select pizza_types.name,
sum(order_details.QUANTITY) as quantity
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_details
on order_details.PIZZA_ID = pizzas.pizza_id
group by pizza_types.name
order by quantity desc limit 5;

/*Join the necessary tables to find the total quantity of each pizza category ordered*/

select pizza_types.category,
sum(order_details.QUANTITY) as quantity
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_details
on order_details.PIZZA_ID = pizzas.pizza_id
group by pizza_types.category order by quantity desc;

/*Determine the distribution of orders by hour of the day*/

select hour(order_time) as hour, count(ORDER_ID) as order_count from orders 
group by hour(order_time);

/*Join relevant tables to find the category-wise distribution of pizzas*/

select category, count(name)  from pizza_types
group by category ;

/*Group the orders by date and calculate the average number of pizzas ordered per day.*/

SELECT 
    order_date, 
    AVG(daily_quantity) AS avg_pizzas_per_day
FROM (
    SELECT 
        DATE(orders.ORDER_DATE) AS order_date,
        SUM(order_details.QUANTITY) AS daily_quantity
    FROM 
        order_details
    JOIN 
        orders ON orders.ORDER_ID = order_details.ORDER_ID
    GROUP BY 
        DATE(orders.ORDER_DATE)
) AS daily_orders
GROUP BY order_date
ORDER BY order_date;

/*Determine the top 3 most ordered pizza types based on revenue.*/

SELECT category,name,revenue,rnk
FROM (
    SELECT 
        pizza_types.category, 
        pizza_types.name, 
        SUM(order_details.QUANTITY * pizzas.price) AS revenue,
        RANK() OVER (ORDER BY SUM(order_details.QUANTITY * pizzas.price) DESC) AS rnk
    FROM order_details
    JOIN pizzas ON order_details.PIZZA_ID = pizzas.pizza_id
    JOIN pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
    GROUP BY pizza_types.category, 
        pizza_types.name
) AS ranked_pizzas
WHERE rnk <= 3 ORDER BY rnk;

/*Calculate the percentage contribution of each pizza type to total revenue.*/

WITH PizzaRevenue AS (
    SELECT 
        pizza_types.category, 
        pizza_types.name, 
        SUM(order_details.QUANTITY * pizzas.price) AS revenue
    FROM order_details
    JOIN pizzas ON order_details.PIZZA_ID = pizzas.pizza_id
    JOIN pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
    GROUP BY pizza_types.category, pizza_types.name
),
TotalRevenue AS (
    SELECT SUM(revenue) AS total_revenue
    FROM 
        PizzaRevenue
)
SELECT pr.category, pr.name, pr.revenue, 
    (pr.revenue / tr.total_revenue) * 100 AS percentage_contribution
FROM 
    PizzaRevenue pr, 
    TotalRevenue tr
ORDER BY 
    pr.revenue DESC;

/*Analyze the cumulative revenue generated over time.*/

WITH DailyRevenue AS (
    SELECT 
        DATE(orders.ORDER_DATE) AS order_date,
        SUM(order_details.QUANTITY * pizzas.price) AS daily_revenue
    FROM order_details
    JOIN pizzas ON order_details.PIZZA_ID = pizzas.pizza_id
    JOIN orders ON orders.ORDER_ID = order_details.ORDER_ID
    GROUP BY DATE(orders.ORDER_DATE)
),
CumulativeRevenue AS (
    SELECT order_date,daily_revenue,
        SUM(daily_revenue) OVER (ORDER BY order_date) AS cumulative_revenue
    FROM DailyRevenue
)
SELECT order_date,daily_revenue,cumulative_revenue
FROM CumulativeRevenue
ORDER BY order_date;

/*Determine the top 3 most ordered pizza types based on revenue for each pizza category.*/


select name, revenue 
from
(select category, name, revenue,
rank() over (partition by category order by revenue desc) as rn
from
(select pizza_types.category, pizza_types.name,
sum(order_details.QUANTITY * pizzas.price) as revenue  
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_details
on order_details.PIZZA_ID = pizzas.pizza_id
group by  pizza_types.category, pizza_types.name) as a) as b
where rn<= 3
;
