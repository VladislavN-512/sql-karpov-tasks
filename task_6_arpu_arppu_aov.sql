-- Для каждого дня в таблицах orders и user_actions рассчитайте следующие показатели:

-- Выручку на пользователя (ARPU) за текущий день.
-- Выручку на платящего пользователя (ARPPU) за текущий день.
-- Выручку с заказа, или средний чек (AOV) за текущий день.
-- Колонки с показателями назовите соответственно arpu, arppu, aov. Колонку с датами назовите date. 

-- При расчёте всех показателей округляйте значения до двух знаков после запятой.
-- Результат должен быть отсортирован по возрастанию даты. 
-- Поля в результирующей таблице: date, arpu, arppu, aov


with revenue_tab as (
    SELECT date, revenue, 
        SUM(revenue) OVER(order by date) as total_revenue,
        ROUND(((revenue::decimal / LAG(revenue) OVER(order by date))-1)*100 , 2 ) as revenue_change
    FROM (
        SELECT creation_time::date as date, SUM(t1.summa) as revenue
        FROM orders 
         JOIN (
            SELECT t2.order_id, SUM(p.price) as summa
            FROM ( 
                SELECT order_id, unnest(product_ids) as product_id 
                FROM orders 
                WHERE order_id not in (SELECT order_id FROM user_actions where action = 'cancel_order')
                GROUP BY order_id, product_ids 
            ) t2
             JOIN products p using (product_id)
            GROUP BY 1 
         ) t1 using (order_id)
    GROUP by 1) t3
), 
users_tab as (
    SELECT time::date as date, count(distinct user_id) as all_users,
        count(distinct user_id) filter (
            where action = 'create_order' 
             AND
             order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
         ) as paying_users,
        count(distinct order_id) filter (
            where action = 'create_order' 
             AND
             order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
        ) as all_orders
    FROM user_actions
    group by 1
)
SELECT date,
    round(revenue::decimal/all_users, 2) as arpu,
    round(revenue::decimal/paying_users, 2) as arppu,
    round(revenue::decimal/all_orders, 2) as aov
FROM users_tab
    join revenue_tab using (date)
