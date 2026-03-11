-- Для каждого дня в таблицах orders и user_actions рассчитайте следующие показатели:

-- Выручку, полученную в этот день.
-- Выручку с заказов новых пользователей, полученную в этот день.
-- Долю выручки с заказов новых пользователей в общей выручке, полученной за этот день.
-- Долю выручки с заказов остальных пользователей в общей выручке, полученной за этот день.

-- Колонки с показателями назовите соответственно revenue, new_users_revenue, new_users_revenue_share, old_users_revenue_share. Колонку с датами назовите date. 
-- Все показатели долей необходимо выразить в процентах. При их расчёте округляйте значения до двух знаков после запятой.
-- Результат должен быть отсортирован по возрастанию даты.
-- Поля в результирующей таблице: date, revenue, new_users_revenue, new_users_revenue_share, old_users_revenue_share


with first_actions as (SELECT user_id, min(time)::date as first_date
                       FROM   user_actions
                       GROUP BY user_id), 
t1 as (SELECT tt1.order_id, sum(p.price) as summa,
              sum(p.price) filter (WHERE tt1.order_id in (SELECT ua.order_id
                                                          FROM   user_actions ua 
                                                              join first_actions fa ON ua.user_id = fa.user_id
                                                          WHERE  ua.time::date = fa.first_date and ua.action = 'create_order')) as summa2
       FROM   (SELECT order_id, unnest(product_ids) as product_id
               FROM   orders
               WHERE  order_id not in (SELECT order_id
                                       FROM   user_actions
                                       WHERE  action = 'cancel_order')
               GROUP BY order_id, product_ids) tt1 
          join products p using (product_id)
      GROUP BY 1)

SELECT date, revenue, new_users_revenue,
       round(new_users_revenue::decimal / revenue * 100, 2) as new_users_revenue_share,
       round((revenue - new_users_revenue)::decimal / revenue * 100, 2) as old_users_revenue_share
FROM   (SELECT creation_time::date as date,
               sum(t1.summa) as revenue,
               sum(t1.summa2) as new_users_revenue
        FROM   orders 
          join t1 using (order_id)
        GROUP BY 1) tt2
ORDER BY date
