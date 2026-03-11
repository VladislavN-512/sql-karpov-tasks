-- Для каждого дня, представленного в таблицах user_actions и courier_actions, рассчитайте следующие показатели:
-- Число новых пользователей.
-- Число новых курьеров.
-- Общее число пользователей на текущий день.
-- Общее число курьеров на текущий день.
-- Прирост числа новых пользователей.
-- Прирост числа новых курьеров.
-- Прирост общего числа пользователей.
-- Прирост общего числа курьеров.
  
-- Колонки с показателями назовите соответственно new_users, new_couriers, total_users, total_couriers, new_users_change, new_couriers_change, total_users_growth, total_couriers_growth. 
-- Колонку с датами назовите date.
-- Все показатели прироста считайте в процентах относительно значений в предыдущий день. При расчёте показателей округляйте значения до двух знаков после запятой. 
-- Результирующая таблица должна быть отсортирована по возрастанию даты.

-- Поля в результирующей таблице: 
-- date, new_users, new_couriers, total_users, total_couriers, new_users_change, new_couriers_change, total_users_growth, total_couriers_growth

with t1 as (SELECT date, count(distinct user_id) as new_users
            FROM   (SELECT user_id, min(time::date) as date
                    FROM   user_actions
                    GROUP BY user_id) as fu
            GROUP BY 1), 
  t2 as (SELECT date, count(distinct courier_id) as new_couriers
         FROM   (SELECT courier_id, min(time::date) as date
                 FROM   courier_actions
                 GROUP BY courier_id) as fc
         GROUP BY 1), 
  t3 as (SELECT date, new_users, new_couriers,
                sum(new_users::integer) OVER(ORDER BY date) as total_users,
                sum(new_couriers::integer) OVER(ORDER BY date) as total_couriers
         FROM t1
             LEFT JOIN t2 using (date))
  
SELECT date, new_users, new_couriers, total_users, total_couriers,
       round(100.0 * (new_users - lag(new_users) OVER (ORDER BY date)) / lag(new_users) OVER (ORDER BY date) ,
             2) as new_users_change,
       round(100.0 * (new_couriers - lag(new_couriers) OVER (ORDER BY date)) / lag(new_couriers) OVER (ORDER BY date) ,
             2) as new_couriers_change,
       round(100.0 * (total_users - lag(total_users) OVER (ORDER BY date)) / lag(total_users) OVER (ORDER BY date) ,
             2) as total_users_growth,
       round(100.0 * (total_couriers - lag(total_couriers) OVER (ORDER BY date)) / lag(total_couriers) OVER (ORDER BY date) ,
             2) as total_couriers_growth
FROM   t3
