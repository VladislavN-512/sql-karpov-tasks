-- Для каждого товара, представленного в таблице products, за весь период времени в таблице orders рассчитайте следующие показатели:

-- Суммарную выручку, полученную от продажи этого товара за весь период.
-- Долю выручки от продажи этого товара в общей выручке, полученной за весь период.
-- Колонки с показателями назовите соответственно revenue и share_in_revenue. Колонку с наименованиями товаров назовите product_name.

-- Долю выручки с каждого товара необходимо выразить в процентах. При её расчёте округляйте значения до двух знаков после запятой.
  
-- Товары, округлённая доля которых в выручке составляет менее 0.5%, объедините в общую группу с названием «ДРУГОЕ» (без кавычек), просуммировав округлённые доли этих товаров.

-- Результат должен быть отсортирован по убыванию выручки от продажи товара.

-- Поля в результирующей таблице: product_name, revenue, share_in_revenue


with t1 as (SELECT p.name,
                   sum(p.price) as summa
            FROM   (SELECT order_id,
                           unnest(product_ids) as product_id
                    FROM   orders
                    WHERE  order_id not in (SELECT order_id
                                            FROM   user_actions
                                            WHERE  action = 'cancel_order')
                    GROUP BY order_id, product_ids) tt1 join products p using (product_id)
            GROUP BY 1), 
  t2 as (SELECT name as product_name, sum(t1.summa) as revenue
         FROM   t1
         GROUP BY name), 
  t3 as (SELECT sum(revenue) as total
         FROM   t2), 
  with_shares as (SELECT product_name, revenue, 
                    round(revenue::numeric / t3.total * 100, 2) as rounded_share
                  FROM   t2, t3)
SELECT case 
          when rounded_share < 0.5 then 'ДРУГОЕ'
          else product_name 
        end as product_name,
       sum(revenue) as revenue,
       sum(rounded_share) as share_in_revenue
FROM   with_shares
GROUP BY 1
ORDER BY 2 desc
